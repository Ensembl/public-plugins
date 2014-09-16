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
  my $self        = shift;
  my $rose_object = $self->rose_object;
  my $job_data    = $rose_object->job_data->raw; # get raw hash to make sure we do not modify the job_data column

  if ($job_data->{'sequence'}{'is_invalid'}) {
    $rose_object->job_message([{'display_message' => $job_data->{'sequence'}{'is_invalid'}, 'fatal' => 0}]);
    return;
  }

  my $object      = $self->object;
  my @search_type = $object->parse_search_type(delete $job_data->{'search_type'});

  $job_data->{'blast_type'} = $search_type[0];
  $job_data->{'program'}    = lc $search_type[1];
  $job_data->{'work_dir'}   = $rose_object->job_dir;

  return $job_data;
}

sub get_dispatcher_class {
  ## For Blat, we use the Blat dispatcher, otherwise whatever is configured in SiteDefs.
  my ($self, $data) = @_;
  return $data->{'blast_type'} eq 'BLAT' ? 'Blat' : undef;
}

1;
