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

package EnsEMBL::Web::Component::Tools::Blast::ResultsSummary;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::Blast
  EnsEMBL::Web::Component::Tools::ResultsSummary
);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable(0);
}

sub content {
  my $self    = shift;
  my $message = $self->SUPER::content;

  # display the message if something goes wrong
  return $message if $message;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $url_param = $object->create_url_param;

  # no results found
  return $self->info_panel('No results found', sprintf('If you believe that there should be a match to your query sequence please adjust the configuration parameters you selected and <a href="%s">resubmit the search</a>.', $hub->url({'function' => 'Edit', 'tl' => $url_param})))
    unless @{$job->result};

  # result found, don't display anything, leave that to other components
  return '';
}

1;
