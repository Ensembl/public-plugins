=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use previous qw(munge_config_tree munge_config_tree_multi _munge_file_formats);

sub munge_config_tree {
  my $self = shift;
  $self->PREV::munge_config_tree(@_);
  $self->_configure_blast;
}

sub munge_config_tree_multi {
  my $self = shift;
  $self->PREV::munge_config_tree_multi(@_);
  $self->_configure_blast_multi;
  $self->_configure_vep_multi;
}

sub _munge_file_formats {
  my $self = shift;
  $self->PREV::_munge_file_formats(@_);
  
  # add gene list format
  push @{$self->tree->{'UPLOAD_FILE_FORMATS'}}, 'gene_list';
  $self->tree->{'DATA_FORMAT_INFO'}->{'gene_list'} = {
    'ext' => 'txt',
    'label' => 'Gene or feature list',
    'display' => 'feature',
  };
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
  return unless defined($tree->{'ENSEMBL_VEP_PLUGINS'}) && defined($tree->{'ENSEMBL_VEP_PLUGINS'}->{'CONFIG'});
  my $file = $tree->{'ENSEMBL_VEP_PLUGINS'}->{'CONFIG'};
  
  return unless -e $file;
  my $content = file_get_contents($file);

  my $VEP_PLUGIN_CONFIG = eval $content;
  die("Failed to parse VEP config file $file: $@\n") if $@;

  $tree->{'ENSEMBL_VEP_PLUGIN_CONFIG'} = $VEP_PLUGIN_CONFIG;
}

1;
