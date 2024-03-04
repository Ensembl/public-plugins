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

package EnsEMBL::Web::Component::Tools::ResultsSummary;

### Parent class for all ResultsSummary components
### Shall be used with MI

use strict;
use warnings;

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $job         = $object->get_requested_job({'with_all_results' => 1});
  my $status      = $job ? $job->dispatcher_status : '';

  # invalid job id
  return $self->warning_panel('Job not found', 'The job you requested was not found. It has either been expired, or you clicked on an invalid link.') unless $job;

  # job failed
  return $self->info_panel('No results found', 'The job has failed.') if $status eq 'failed';

  # job still running
  return $self->info_panel('No results found', 'The job is not done yet') if $status ne 'done';

  # job done, don't display anything, leave that to other components
  return '';
}

1;
