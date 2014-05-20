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

package EnsEMBL::Web::Component::Tools::Blast::ResultsSummary;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable(0);
}

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $job         = $object->get_requested_job({'with_all_results' => 1});
  my $url_param   = $object->create_url_param;

  if ($job) {

    my $status = $job->status;

    return $status eq 'done'
      ? @{$job->result}
        ? ''
        : $self->_error('No results found', sprintf('If you believe that there should be a match to your query sequence please adjust the configuration parameters you selected and <a href="%s">resubmit the search</a>.', $hub->url({'function' => 'Edit', 'tl' => $url_param})))
      : $self->_error('No results found', sprintf('The job is either not done yet, or has failed. Click <a href="%s">here</a> to view', $hub->url({'function' => 'View', 'tl' => $url_param})))
    ;
  }

  return $self->_error('Job not found', 'The job you requested was not found. It has either been expired, or you clicked on an invalid link.');
}

1;
