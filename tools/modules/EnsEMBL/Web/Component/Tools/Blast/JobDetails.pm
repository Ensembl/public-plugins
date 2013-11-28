=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::JobDetails;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools::Blast);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $job         = $object->get_requested_job({'with_all_results' => 1});

  if ($job) {

    my $status      = $job->status;
    my $hive_status = $job->hive_status;
    my $twocol      = $self->job_details_table($job, {'links' => [qw(edit delete)]});

    return $twocol->render if $status ne 'done';

    if ($job->result) {
      $twocol->set_attribute('class', ['toggleable', '_job_input_details', 'hidden']);
      return $self->dom->create_element('div', {
        'children'    => [{
          'node_name'   => 'h3',
          'children'    => [{
            'node_name'   => 'div',
            'children'    => [{
              'node_name'   => 'a',
              'href'        => '#',
              'inner_HTML'  => 'Input details',
              'class'       => ['toggle', 'set_cookie', 'closed'],
              'rel'         => '_job_input_details'
            }]
          }]
        }, $twocol]
      })->render;

    } else {
      return sprintf '%s%s', $twocol->render, $self->_error('No results found', 'If you believe that there should be a match to your query sequence(s) please adjust the configuration parameters you selected and resubmit the search.');
    }
  } else {
      return $self->_error('Job not found', 'The job you requested was not found. It has either been expired, or you clicked on an invalid link.');
  }
}

1;
