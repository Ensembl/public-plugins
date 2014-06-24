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

package EnsEMBL::Web::Component::Tools::Blast::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::TicketsList
  EnsEMBL::Web::Component::Tools::Blast
);

sub job_summary_section {
  ## @override
  my ($self, $ticket, $job) = @_;

  my $summary   = $self->SUPER::job_summary_section($ticket, $job);
  my $hit_count = $job->result_count;

  for (@{$summary->get_nodes_by_flag('job_status_tag')}) {
    $_->append_HTML(sprintf ': %s hit%s found', $hit_count || 'No', $hit_count == 1 ? '' : 's');

    unless ($hit_count) {
      $_->set_attribute('title', "This job is finished, but no hits were found. If you believe that there should be a match to your query sequence please edit the job using the icon on the right to adjust the configuration parameters and resubmit the search.");
      $_->set_attribute('class', 'job-status-noresult');
      $_->remove_attribute('class', 'job-status-done');
    }
  }

  unless ($hit_count) {
    $_->parent_node->remove_child($_) for @{$summary->get_nodes_by_flag('job_results_link')};
  }

  return $summary;
}

1;