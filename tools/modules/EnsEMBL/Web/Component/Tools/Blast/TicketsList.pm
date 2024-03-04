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

package EnsEMBL::Web::Component::Tools::Blast::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::Blast
  EnsEMBL::Web::Component::Tools::TicketsList
);

sub job_summary_section {
  ## @override
  my ($self, $ticket, $job, $hit_count) = splice @_, 0, 4;

  my $summary = $self->SUPER::job_summary_section($ticket, $job, $hit_count, @_);
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

sub job_status_tag {
  ## @override
  ## Add info about number of hits found to the status tag if job's done
  my ($self, $job, $status, $hits, $result_url, $assembly_mismatch, $has_assembly_site) = @_;

  my $tag = $self->SUPER::job_status_tag($job, $status, $hits, $result_url, $assembly_mismatch, $has_assembly_site);

  if ($status eq 'done') {
    $tag->{'inner_HTML'} .= sprintf ': %s hit%s found', $hits || 'No', $hits == 1 ? '' : 's';

    if (!$hits && !$assembly_mismatch) {
      $tag->{'class'} = [ 'job-status-noresult', grep { $_ ne 'job-status-done' } @{$tag->{'class'}} ];
      $tag->{'title'} = 'This job is finished, but no hits were found. If you believe that there should be a match to your query sequence please edit the job using the icon on the right to adjust the configuration parameters and resubmit the search.';
      $tag->{'href'}  = '';
    }
  }

  return $tag;
}

sub analysis_caption {
  ## @override
  my ($self, $ticket) = @_;
  return $self->object->get_sub_object('Blast')->parse_search_type($ticket->job->[0]->job_data->{'search_type'}, 'search_method');
}

1;
