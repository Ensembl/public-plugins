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

package EnsEMBL::Web::Component::Tools::VEP;

### Base class for all Blast components

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Web::Component::Tools);

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Extra param hashref as required by expand_job_status method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $params) = @_;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Description',    $job->job_desc // '-');
  $two_col->add_row('Status',         $self->expand_job_status($job, $params)->render);

  return $two_col;
}

1;
