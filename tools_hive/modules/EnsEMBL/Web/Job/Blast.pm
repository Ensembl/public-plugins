=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Job::Blast;

### plugin to add extra parameters to BLAST/BLAT job before submitting it to Hive dispatcher

use strict;
use warnings;

use previous qw(prepare_to_dispatch);

sub prepare_to_dispatch {
  ## @plugin
  my $self        = shift;
  my $data        = $self->PREV::prepare_to_dispatch(@_) or return;
  my $rose_object = $self->rose_object;
  my $blast_type  = $data->{'blast_type'};
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $dba         = $hub->database('core', $rose_object->species);
  my $dbc         = $dba->dbc;

  $data->{'dba'}  = {
    -user               => $dbc->username,
    -host               => $dbc->host,
    -port               => $dbc->port,
    -pass               => $dbc->password,
    -dbname             => $dbc->dbname,
    -driver             => $dbc->driver,
    -species            => $dba->species,
    -species_id         => $dba->species_id,
    -multispecies_db    => $dba->is_multispecies,
    -group              => $dba->group
  };

  $data->{'code_root'} = $sd->ENSEMBL_HIVE_HOSTS_CODE_LOCATION;

  if ($data->{'blast_type'}) {
    for (sprintf 'ENSEMBL_%s_DATA_PATH', $blast_type) {
      if (my $path = $sd->$_) {
        $data->{'index_files'} = $path;
      }
    }
    for (sprintf 'ENSEMBL_%s_DATA_PATH_DNA', $blast_type) {
      if (my $path = $sd->$_) {
        $data->{'dna_index_files'} = $path;
      }
    }
  }

  return $data;
}

1;
