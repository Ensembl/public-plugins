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

package EnsEMBL::Web::Component::Tools::VariationPattern::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::VariationPattern
  EnsEMBL::Web::Component::Tools::TicketsList
);

sub job_summary_section {
  ## @override
  ## Change text and link of the results link
  my $self      = shift;
  my $ticket    = $_[0];
  my ($job)     = $ticket && $ticket->job;
  my $summary   = $self->SUPER::job_summary_section(@_);

  foreach (@{$summary->get_nodes_by_flag('job_results_link') || []}) {
    $_->inner_HTML($job->dispatcher_data->{'just_download'} ? '[Download unedited file]' : '[Download results]');
    $_->set_attribute('href', $self->object->download_url($ticket->ticket_name));
    $_->set_attribute('rel', "notexternal");
  }

  return $summary;
}


sub job_status_tag {
  ## @override
  ## Remove link from the status tag of finished jobs
  my $self    = shift;
  my $status  = $_[1];
  my $tag     = $self->SUPER::job_status_tag(@_);

  if ($status eq 'done') {
    $tag->{'title'} = q(This job is finished. Please click on the 'Download&nbsp;results' link to download result file.);
    $tag->{'href'}  = '';
  }

  return $tag;
}

sub ticket_buttons {
  ## @override
  ## Add an extra download icon for finished jobs
  my $self      = shift;
  my $ticket    = $_[0];
  my $buttons   = $self->SUPER::ticket_buttons(@_);
  my ($job)     = $ticket && $ticket->job;

  if ($job && $job->dispatcher_status eq 'done') {
    my $icon = $buttons->prepend_child({
      'node_name'   => 'a',
      'class'       => [qw(_download)],
      'href'        => $self->object->download_url($ticket->ticket_name),
      'children'    => [{
        'node_name'   => 'span',
        'class'       => [qw(_ht sprite download_icon)],
        'rel'         => 'notexternal',
        'title'       => 'Download output file'
      }]
    });

    $icon->set_attribute('rel', "notexternal");
  }

  return $buttons;
}




1;
