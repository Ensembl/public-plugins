=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;

use previous qw(new);

sub new {
  ## Adds 'tl' to the list of core params before returning the newly created object
  my $self = shift->PREV::new(@_);
  push @{$self->{'_core_params'}}, 'tl';
  return $self;
}

sub tools_sitetype {
  ## site_type column value for all the tickets blonging to the site
  return shift->ENSEMBL_TOOLS_SITETYPE;
}

sub tools_list {
  ## Return a list of all tools that are enabled
  ## @return Disguised hash in an array syntax (to maintain order) with keys as name of the tool and value as caption
  my $self  = shift;
  my @list  = @{$self->ENSEMBL_TOOLS_LIST};

  for (0..$#list) {
    next if $_ % 2;
    if (
      ($list[$_] eq 'Blast'             && !$self->ENSEMBL_BLAST_ENABLED) ||
      ($list[$_] eq 'VEP'               && !$self->ENSEMBL_VEP_ENABLED) ||
      ($list[$_] eq 'AssemblyConverter' && !$self->ENSEMBL_AC_ENABLED)  ||
      ($list[$_] eq 'FileChameleon'     && !$self->ENSEMBL_FC_ENABLED)  ||
      ($list[$_] eq 'AlleleFrequency'   && !$self->ENSEMBL_AF_ENABLED)  ||
      ($list[$_] eq 'VcftoPed'          && !$self->ENSEMBL_VP_ENABLED)  ||
      ($list[$_] eq 'DataSlicer'        && !$self->ENSEMBL_DS_ENABLED)  ||
      ($list[$_] eq 'VariationPattern'  && !$self->ENSEMBL_VPF_ENABLED)
    ) {
      $list[$_]   = undef;
      $list[$_+1] = undef;
    }
  }

  return grep $_, @list;
}

sub tools_db {
  ## Returns tools db details
  ## @return Hashref
  my $self = shift;
  my $db   = $self->multidb->{'DATABASE_WEB_TOOLS'};

  return {
    'database'  => $db->{'NAME'},
    'host'      => $db->{'HOST'},
    'port'      => $db->{'PORT'},
    'username'  => $db->{'USER'}  || $self->DATABASE_WRITE_USER,
    'password'  => $db->{'PASS'}  || $self->DATABASE_WRITE_PASS
  };
}

sub tools_valid_species {
  ## Return a list of all valid species for tool
  ## If list of species is provided as argument, it returns the valid ones among the list
  return shift->valid_species(@_);
}

sub get_available_blast_datasources {
  ## Gets all the available blast data sources for the given species
  my ($self, $species) = @_;

  my $blast_types   = $self->multi_val('ENSEMBL_BLAST_TYPES');
  my $source_types  = $self->get_config($species, 'ENSEMBL_BLAST_DATASOURCES_BY_TYPE') || $self->multi_val('ENSEMBL_BLAST_DATASOURCES_BY_TYPE'); # give precedence to species.ini entry
  my $datasources   = {};

  foreach my $blast_type (keys %$blast_types) { #BLAT, NCBIBLAST, WUBLAST etc
    next if $blast_type eq 'ORDER';

    $datasources->{$_} = 1 for @{$source_types->{$blast_type} || []} #LATESTGP, CDNA_ALL, PEP_ALL etc
  }

  return $datasources;
}

sub get_blast_datasource_filename {
  ## Get tha name of the source file name for the given species, blast type and source type
  my ($self, $species, $blast_type, $source_type) = @_;

  return $self->$_($species, $source_type) for sprintf '_get_%s_source_file', $blast_type;
}

sub _get_NCBIBLAST_source_file {
  ## @private
  my ($self, $species, $source_type) = @_;

  my $assembly  = $self->get_config($species, 'ASSEMBLY_VERSION');
  my $type      = lc($source_type =~ s/_/\./r);
  my $sp_prefix = ucfirst($self->get_config($species, 'SPECIES_PRODUCTION_NAME'));

  return sprintf '%s.%s.%s.fa', $sp_prefix, $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf '%s.%s.%s.%s.fa', $sp_prefix, $assembly, $self->get_config($species, 'REPEAT_MASK_DATE') || $self->get_config($species, 'DB_RELEASE_VERSION'), $type;
}

sub _get_BLAT_source_file {
  ## @private
  my ($self, $species, $source_type) = @_;
  my $server = $self->get_config($species, 'BLAT_DATASOURCES')->{$source_type};
  return $server ? join ':', $server, $self->ENSEMBL_BLAT_TWOBIT_DIR : '';
}

1;
