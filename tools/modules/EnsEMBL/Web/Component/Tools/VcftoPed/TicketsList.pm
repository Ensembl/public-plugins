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

package EnsEMBL::Web::Component::Tools::VcftoPed::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::VcftoPed
  EnsEMBL::Web::Component::Tools::TicketsList
);

sub job_summary_section {
  ## @override
  my ($self, $ticket, $job, $hit_count) = splice @_, 0, 4;

  my $summary = $self->SUPER::job_summary_section($ticket, $job, $hit_count, @_);

  # remove result links if no hit found
  unless ($hit_count) {
    $_->parent_node->remove_child($_) for @{$summary->get_nodes_by_flag('job_results_link')};
  }

  return $summary;
}

sub job_status_tag {
  ## @override
  ## Add info about number of hits found to the status tag if job's done
  my $self    = shift;  
  my $job     = $_[0];
  my $status  = $_[1];
  my $tag     = $self->SUPER::job_status_tag(@_);

  if ($status eq 'done' && !(scalar @{$job->result})) {
    $tag->{'inner_HTML'} = "Done: No results obtained";
    $tag->{'class'} = [ 'job-status-noresult', grep { $_ ne 'job-status-done' } @{$tag->{'class'}} ];
    $tag->{'title'} = 'This job is finished, but no results were obtained. If you believe that there should be a match please edit the job using the icon on the right to change the configuration and resubmit the search.';
    $tag->{'href'}  = '';    
  }

  return $tag;
}


1;
