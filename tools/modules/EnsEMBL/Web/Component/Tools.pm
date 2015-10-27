=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Shared);

sub object {
  ## @override
  ## Gets the object according to the URL 'action' instead of the 'type' param, as expected in the tools based components
  return shift->SUPER::object->get_sub_object;
}

sub mcacheable {
  return 0;
}

sub new {
  ## @constructor
  ## @override To set the correct view config
  my $self = shift->SUPER::new(@_);
  if (my $hub = $self->hub) {
    $self->{'view_config'} = $hub->get_viewconfig($self->id, $hub->action, 'cache');
  }
  return $self;
}

sub _init {
  ## Makes all the components in tools ajaxable but not cacheable
  ## Override this in a child class to modify the default behaviour
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub job_status_tag {
  ## Tag to be displayed next to each job in ticket list table, or job details page
  ## @param Job object
  ## @param Dispatcher status (string)
  ## @param Number of results
  ## @param URL for results page
  ## @param Current assembly for the job species if it's not the same as the one to which the job was originally submitted to, 0 if species doesn't exist on current site
  ## @param Flag kept on if the job can be viewed on a different assembly website (only applicable if assembly different)
  my ($self, $job, $status, $result_count, $result_url, $assembly_mismatch, $has_assembly_site) = @_;

  my $css_class = "job-status-$status";
  my $href      = '';
  my $title     = {
    'not_submitted' => q(This job could not be submitted due to some problems. Please click on the 'View details' icon for more information),
    'queued'        => q(Your job has been submitted and will be processed soon.),
    'submitted'     => q(Your job has been submitted and will be processed soon.),
    'running'       => q(Your job is currently being processed. The page will refresh once it's finished running.),
    'done'          => q(This job is finished.),
    'failed'        => q(This job has failed. Please click on the 'View details' icon for more information),
    'deleted'       => q(Your ticket has been deleted. This usually happens if the ticket is too old.)
  }->{$status};

  if ($status eq 'done') {
    if ($assembly_mismatch) {
      $css_class  = 'job-status-mismatch';
      $title      = sprintf 'The job was run on %s assembly for %s. ', $job->assembly, $self->hub->species_defs->get_config($job->species, 'SPECIES_COMMON_NAME');
      $title     .= $has_assembly_site && $job->ticket->owner_type ne 'user' ? sprintf('Please save this ticket to your account using the icon on the right to be able to view this job on %s site. ', $job->assembly) : '';
      $title     .= sprintf q(To resubmit the job to %s assembly, please click on the 'Edit &amp; resubmit' icon.), $assembly_mismatch;
    } elsif (defined $assembly_mismatch && $assembly_mismatch eq '0') {
      $css_class  = 'job-status-mismatch';
      $title      = sprintf q(The job was run on %s which does not exist on this site.), $job->species =~ s/_/ /gr;
    } else {
      $href       = $self->hub->url($result_url); # display link on the tag only if job's done and results are available of current assembly
    }
  }

  return {
    'class'       => [$css_class, qw(_ht job-status)],
    'title'       => $title,
    'href'        => $href, 
    'inner_HTML'  => ucfirst $status =~ s/_/ /gr
  }
}

sub species_specific_info {
  ## Creates an info box alternative assembly info
  ## @param Species
  ## @param Tools type caption
  ## @param Tool type url name
  ## @return HTML for info box to be displayed
  my ($self, $species, $caption, $tool_type) = @_;
  my $hub   = $self->hub;
  my $sd    = $hub->species_defs;
  if (my $alt_assembly = $sd->get_config($species, 'SWITCH_ASSEMBLY')) {
    my $alt_assembly_url    = $sd->get_config($species, 'SWITCH_ARCHIVE_URL');
    my $species_common_name = $sd->get_config($species, 'SPECIES_COMMON_NAME');
    return $self->info_panel(
      sprintf('%s for %s %s', $caption, $species_common_name, $alt_assembly),
      sprintf('If you are looking for %s for %s %s, please go to <a href="http://%s%s">%3$s website</a>.',
        $caption,
        $species_common_name,
        $alt_assembly,
        $alt_assembly_url,
        $hub->url({'__clear' => 1, 'species' => $species, 'type' => 'Tools', 'action' => $tool_type })
      )
    ),
  }
  return '';
}

sub result_url {
  ## Get the url for the result page for a job
  ## @param Ticket object
  ## @param Job object
  my ($self, $ticket, $job) = @_;

  return {
    'species'     => $job->species,
    'type'        => 'Tools',
    'action'      => $ticket->ticket_type_name,
    'function'    => 'Results',
    'tl'          => $self->object->create_url_param({'ticket_name' => $ticket->ticket_name, 'job_id' => $job->job_id})
  };
}

sub format_date {
  ## Formats datetime from db into a printable form
  ## @param Datetime value
  ## @return String
  my ($self, $datetime) = @_;

  my @date = split /-|T|:/, $datetime;

  return sprintf '%s/%s/%s, %s:%s', $date[2], $date[1], $date[0], $date[3], $date[4];
}

1;
