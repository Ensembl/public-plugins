=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Job);

sub prepare_to_dispatch {
  ## @override
  my ($self, $job) = @_;

  my $job_data = $job->job_data->raw;

  if ($job_data->{'sequence'}{'is_invalid'}) {
    $job->job_message([{'display_message' => $job_data->{'sequence'}{'is_invalid'}, 'fatal' => 0}]);
    return;
  }

  my $object  = $self->object;
  my $hub     = $self->hub;
  my $dba     = $hub->database('core', $job->species);
  my $dbc     = $dba->dbc;
  my $sd      = $hub->species_defs;

  $job_data->{'dba'}  = {
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

  my @search_type = $object->parse_search_type(delete $job_data->{'search_type'});

  $job_data->{'blast_type'} = $search_type[0];
  $job_data->{'program'}    = lc $search_type[1];

  return $job_data;
}

1;
