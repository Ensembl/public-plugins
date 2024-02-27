=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::ConfigPacker;

use strict;
use warnings;
use File::Find;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use previous qw(munge_config_tree munge_config_tree_multi);

sub munge_config_tree {
  my $self = shift;
  $self->PREV::munge_config_tree(@_);
  $self->_configure_blast;
  $self->_configure_assembly_converter_files;
}

sub munge_config_tree_multi {
  my $self = shift;
  $self->PREV::munge_config_tree_multi(@_);
  $self->_configure_blast_multi if $SiteDefs::ENSEMBL_BLAST_ENABLED;
  $self->_configure_vep_multi   if $SiteDefs::ENSEMBL_VEP_ENABLED;
}

sub _configure_blast {}

sub _configure_blast_multi {
  my $self                  = shift;
  my $multi_tree            = $self->full_tree->{'MULTI'};

  return if $multi_tree->{'ENSEMBL_BLAST_DATASOURCES'};

  my $blast_types           = {%{$multi_tree->{'ENSEMBL_BLAST_TYPES'} || {}}};
  my $blast_types_ordered   = [ map { delete $blast_types->{$_} ? $_ : () } @{delete $blast_types->{'ORDER'} || []} ];
  my $source_types          = $multi_tree->{'ENSEMBL_BLAST_DATASOURCES_ALL'};
  my $search_types_ordered  = [];
  my $sources_by_type       = $multi_tree->{'ENSEMBL_BLAST_DATASOURCES_BY_TYPE'};
  my $all_sources           = {};
  my $all_sources_order     = [];
  my $sources               = {};

  foreach my $source_type (@{delete $source_types->{'ORDER'} || []}, sort keys %$source_types) { #LATESTGP, CDNA_ALL, PEP_ALL etc
    my $source_type_details = delete $source_types->{$source_type} or next;
       $source_type_details =~ /^([^\s]+)\s+(.+)$/;

    my $db_type = $1;
    my $label   = $2;
    push @{$sources->{$db_type}}, $source_type;
    push @{$all_sources_order}, $source_type;
    $all_sources->{$source_type} = $label;
  }

  foreach my $blast_type (@$blast_types_ordered) { #BLAT, NCBIBLAST etc
    my $search_types = {%{$multi_tree->{'ENSEMBL_BLAST_METHODS_'.$blast_type}}};

    for (@{delete $search_types->{'ORDER'} || []}, sort keys %$search_types) { #BLASTN, BLASTX, BLASTP etc
      if ($search_types->{$_}) {
        push @$search_types_ordered, {
          'search_type' => "${blast_type}_$_",
          'query_type'  => $search_types->{$_}[0],
          'db_type'     => $search_types->{$_}[1],
          'program'     => $search_types->{$_}[2],
          'min_length'  => $search_types->{$_}[3] || 0,
          'sources'     => [ grep { my $s = $_; !!grep($_ eq $s, @{$sources_by_type->{$blast_type}}) } @{$sources->{$search_types->{$_}[1]}} ] # filter out the sources that are not valid for this blast type
        };
        delete $search_types->{$_};
      }
    }
  }

  $multi_tree->{'ENSEMBL_BLAST_DATASOURCES_ORDER'}  = $all_sources_order;
  $multi_tree->{'ENSEMBL_BLAST_DATASOURCES'}        = $all_sources;
  $multi_tree->{'ENSEMBL_BLAST_CONFIGS'}            = $search_types_ordered;
}

sub _configure_vep_multi {
  my $self = shift;
  my $tree = $self->tree;

  my @configs;

  # parse vep plugins config files
  foreach my $config_file (@{$SiteDefs::ENSEMBL_VEP_PLUGIN_CONFIG_FILES}) {
    if (!-e $config_file) {
      _vep_config_warning("Could not locate config file $config_file", 1);
      return;
    }

    my $content = file_get_contents($config_file);
    my $config  = eval $content;

    if ($@) {
      _vep_config_warning("Failed to parse config file $config_file", 1);
      return;
    }

    if (ref $config ne 'HASH') {
      _vep_config_warning("Config file $config_file did not return reference to a HASH", 1);
      return;
    }

    push @configs, $config;
  }

  # merge configs
  my $vep_configs = shift @configs;
  foreach my $config (@configs) {
    foreach my $key (keys %$config) {

      my ($orig) = grep { $_->{'key'} eq $key } @{$vep_configs->{'plugins'}};

      if (!$orig) {
        _vep_config_warning("Key '$key' in not present in the base VEP plugins config file");
        next;
      }

      $orig->{$_} = _resolve_sitedefs_vars($config->{$key}->{$_}) for keys %{$config->{$key}};
    }
  }

  $tree->{'ENSEMBL_VEP_PLUGIN_CONFIG'} = $vep_configs;

  # parse vep custom config file
  my $vep_custom_config_file = $SiteDefs::ENSEMBL_VEP_CUSTOM_CONFIG_FILES;
  if (!-e $vep_custom_config_file) {
    _vep_config_warning("Could not locate config file $vep_custom_config_file", 1);
    return;
  }

  my $config = _load_json_config($vep_custom_config_file);

  $tree->{'ENSEMBL_VEP_CUSTOM_CONFIG'} = $config;
}

sub _resolve_sitedefs_vars {
  my $obj = shift;

  return $obj unless $obj;
  return $obj =~ s/\[\[(\w+)\]\]/eval("\$SiteDefs::$1") \/\/ _vep_config_warning("\$SiteDefs::$1 is used in one of the ENSEMBL_VEP_PLUGIN_CONFIG_FILES but not defined in SiteDefs") && ''/egr unless ref $obj;
  return [ map { _resolve_sitedefs_vars($_) } @$obj ] if ref $obj eq 'ARRAY';
  return { map { $_ => _resolve_sitedefs_vars($obj->{$_}) } keys %$obj } if ref $obj eq 'HASH';
}

sub _load_json_config {
  my $filename = shift;
  return unless $filename;

  my $json_text = do {
    open(my $json_fh, "<", $filename)
      or do {
        _vep_config_warning("Could not open $filename: $!\n");
        return [];
      };
    local $/;
    <$json_fh>
  };

  my $json = JSON->new;
  my $data;
  eval {
	$data = $json->decode($json_text);
  } or do {
    _vep_config_warning("Could not parse config file $filename", 1, "Custom");
    return [];
  };

  return $data;
}

sub _vep_config_warning {
  my ($message, $fatal, $type) = @_;

  $type ||= "Plugins";
  $message = $fatal ? "[ERROR] VEP $type are not configured: $message" : "[WARNING] $message";
  warn $message." - thrown by ".__FILE__."\n";
}


sub _configure_assembly_converter_files {
  my $self = shift;
  my $species = $self->species;
  my $chain_file_dir = File::Spec->catfile($SiteDefs::ENSEMBL_CHAIN_FILE_DIR, $species);
  if (-d $chain_file_dir) {
    my @files = ();
    # Get all the available chain files to add entry to corresponding species
    find(sub {
      push @files, s/.chain.gz$//r if /.chain.gz$/;
    }, $chain_file_dir);

    push @{$self->tree->{'ASSEMBLY_CONVERTER_FILES'}}, @files;
  }
}

1;
