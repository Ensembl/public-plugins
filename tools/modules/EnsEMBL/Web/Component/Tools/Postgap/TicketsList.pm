=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Postgap::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::Postgap
  EnsEMBL::Web::Component::Tools::TicketsList
);


sub job_status_tag {
  ## @override
  ## Remove link from the status tag of finished jobs
  my $self  = shift;

  my $status   = $_[1];
  my $job      = $_[0];
  my $job_dir  = $job->{job_dir};
  my $tag      = $self->SUPER::job_status_tag(@_);

  if ($status eq 'done') {
    # if output2 file is empty means no data obtained
    if(-f $job_dir.'/'.$job->dispatcher_data->{"output2_file"} && -z $job_dir.'/'.$job->dispatcher_data->{"output2_file"}) {
      $tag->{'inner_HTML'} = "Done: No data found";
      $tag->{'class'} = [ 'job-status-noresult', grep { $_ ne 'job-status-done' } @{$tag->{'class'}} ];
      $tag->{'title'} = 'This job is finished, but no results were obtained.';
      $tag->{'href'}  = '';
    } else {
      $tag->{'title'} = q(This job is finished. Please click on the 'Download&nbsp;results' link to download result file.);
      $tag->{'href'}  = '';
    }
  }

  return $tag;
}

sub job_summary_section {
  ## @override
  ## Change text and link of the results link
  my $self      = shift;
  my $ticket    = $_[0];
  my $job       = $_[1];
  my $job_dir   = $job->{job_dir}; 
  my $output    = $job_dir.'/'.$job->dispatcher_data->{"output_file"}.".tar.gz";
  my $summary   = $self->SUPER::job_summary_section(@_);

  foreach (@{$summary->get_nodes_by_flag('job_results_link') || []}) {
    if (-s $output) {
      $_->inner_HTML('[Download results]');
      $_->set_attribute('href', $self->object->get_sub_object('Postgap')->download_url($ticket->ticket_name, {'action' => 'Postgap'}));
    } else {
      $_->inner_HTML('');
    }
  }

  return $summary;
}

sub ticket_buttons {
  ## @override
  ## Add an extra download icon for finished jobs
  my $self      = shift;
  my $ticket    = $_[0];
  my $buttons   = $self->SUPER::ticket_buttons(@_);
  my ($job)     = $ticket && $ticket->job;
  my $output    = $job->{job_dir}.'/'.$job->dispatcher_data->{"output_file"}.".tar.gz";

  #only provide the download icon when there is an output file and it is not empty
  if ($job && $job->dispatcher_status eq 'done' && -s $output) {
    $buttons->prepend_child({
      'node_name'   => 'a',
      'class'       => [qw(_download)],
      'href'        => $self->object->get_sub_object('Postgap')->download_url($ticket->ticket_name, {'action' => 'Postgap'}),
      'children'    => [{
        'node_name'   => 'span',
        'class'       => [qw(_ht sprite download_icon)],
        'title'       => 'Download output file'
      }]
    });
  }

  return $buttons;
}



1;
