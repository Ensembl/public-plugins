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
  EnsEMBL::Web::Component::Tools::Blast
  EnsEMBL::Web::Component::Tools::TicketsList
);

sub job_summary_section {
  ## @override
  my ($self, $ticket, $job, $hit_count) = @_;

  my $summary = $self->SUPER::job_summary_section($ticket, $job, $hit_count);
  my $desc    = $job->job_data->{'summary'};

  # remove result links if no hit found
  unless ($hit_count) {
    $_->parent_node->remove_child($_) for @{$summary->get_nodes_by_flag('job_results_link')};
  }

  # provide default summary as helptip to the description if user provided a custom description
  for (@{$summary->get_nodes_by_flag('job_desc_span')}) {
    my $escaped_desc = quotemeta $desc;
    if ($_->inner_HTML !~ /$escaped_desc/) {
      $_->set_attributes({'title' => $desc, 'class' => '_ht'});
    }
  }

  return $summary;
}

1;
