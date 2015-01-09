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

sub get_job_summary {
  ## Reads the job dispatcher_status field, and display status accordingly
  ## @param Job object
  ## @param Arrayref with name of the links that need to be displayed (edit and delete) (defaults to displaying both)
  ## @return DIV node
  my ($self, $job, $links) = @_;

  $links ||= [qw(edit delete)];

  my $hub               = $self->hub;
  my $object            = $self->object;
  my $job_id            = $job->job_id;
  my $job_message       = $job->job_message->[0];
  my $job_status        = $job->status;
  my $dispatcher_status = $job->dispatcher_status;
  my $url_param         = $object->create_url_param({'job_id' => $job_id});
  my $job_status_div    = $self->dom->create_element('div', {
    'children'            => [{
      'node_name'           => 'p',
      'inner_HTML'          => $object->get_job_description($job)
    }, {
      'node_name'           => 'p',
      'class'               => 'job-icons'
    }]
  });

  my $icons = {
    'edit'    => {
      'icon'    => 'edit_icon',
      'title'   => 'Edit &amp; resubmit (create new ticket)',
      'url'     => [{ 'function' => 'Edit', 'tl' => $url_param }],
      'class'   => '_ticket_edit _change_location'
    },
    'delete'  => {
      'icon'    => 'delete_icon',
      'title'   => 'Delete',
      'url'     => ['Json', {'function' => 'delete',  'tl' => $url_param  }],
      'class'   => '_json_link',
      'confirm' => 'This will delete this job permanently.'
    }
  };

  my $margin_left_class = @{$job_status_div->last_child->child_nodes} ? 'left-margin' : ''; # set left margin only if required

  foreach my $link (@$links) {
    if ($icons->{$link}) {
      $job_status_div->last_child->append_child('a', {
        'href'        => $hub->url(@{$icons->{$link}{'url'}}),
        'class'       => $icons->{$link}{'class'},
        'children'    => [{
          'node_name'   => 'span',
          'class'       => ['sprite', $icons->{$link}{'icon'}, '_ht', $margin_left_class || ()],
          'title'       => $icons->{$link}{'title'}
        }, $icons->{$link}{'confirm'} ? {
          'node_name'   => 'span',
          'class'       => ['hidden', '_confirm'],
          'inner_HTML'  => $icons->{$link}{'confirm'}
        } : () ]
      });
      $margin_left_class = '';
    }
  }

  if ($job_status eq 'awaiting_user_response') {

    my $display_message         = $job_message && $job_message->display_message || 'Unknown error';
    my $exception_is_fatal      = $job_message ? $job_message->fatal : 1;
    my $job_message_class       = "_job_message_$job_id";
    my $error_div               = $job_status_div->append_child('div', {
      'class'       => 'job-error-msg',
      'children'    => [{
        'node_name'   => 'p',
        'inner_HTML'  => join('', $display_message, $exception_is_fatal ? sprintf(' <a class="toggle _slide_toggle closed" href="#more" rel="%s">Show details</a>', $job_message_class) : '')
      }]
    });

    if ($exception_is_fatal) {
      my $exception = $job_message ? $job_message->exception : {};
      my $details   = $exception->{'message'} ? "Error with message: $exception->{'message'}\n" : "Error:\n";
         $details  .= $exception->{'stack'}
        ? join("\n", map(sprintf("Thrown by %s at %s (%s)", $_->[3], $_->[0], $_->[2]), @{$exception->{'stack'}}))
        : $exception->{'exception'} || 'No details'
      ;

      my $helpdesk_details = sprintf 'This seems to be a problem with %s website code. Please contact our <a href="%s" class="modal_link">helpdesk</a> to report this problem.',
        $hub->species_defs->ENSEMBL_SITETYPE,
        $hub->url({'type' => 'Help', 'action' => 'Contact', 'subject' => 'Exception in Web Tools', 'message' => sprintf("\n\n\n%s with message (%s) (for job %s): %s", $exception->{'class'} || 'Exception', $display_message, $job_id, $details)})
      ;

      $error_div->append_children({
        'node_name'   => 'div',
        'class'       => [ $job_message_class, 'toggleable', 'hidden', 'job_error_message' ],
        'inner_HTML'  => $details
      }, {
        'node_name'   => 'p',
        'inner_HTML'  => $helpdesk_details
      });
    }
  }

  return $job_status_div;
}

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @params Extra params as required by get_job_summary method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job) = splice @_, 0, 2;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $species   = $job->species;
  my $sd        = $self->hub->species_defs;
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Job summary',  $self->get_job_summary($job, @_)->render);
  $two_col->add_row('Species',      $sd->tools_valid_species($species)
    ? sprintf('<img class="job-species" src="%sspecies/16/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1))
    : $species =~ s/_/ /rg
  );

  return $two_col;
}

sub _results_link_params {
  my ($self, $job, $url_param) = @_;
  my $link_params = {
      'class'       => [qw(small left-margin results-link)],
      'flags'       => ['view_results_link'],
      'inner_HTML'  => '[View results]',
      'href'        => $self->hub->url({
        'species'     => $job->species,
        'type'        => 'Tools',
        'action'      => $job->ticket->ticket_type_name,
        'function'    => 'Results',
        'tl'          => $url_param
      })
  };
  return $link_params;
}


sub new_tool_form {
  ## Creates a new Form object with the information required by all Tools based form pages
  ## @param Tool type ('action' for the form submit URL)
  ## @param Hashref as provided to Form constructor (optional)
  my ($self, $action, $params) = @_;

  $params ||= {};
  $params->{'class'} = '_tool_form bgcolour '.($params->{'class'} || '');

  my $form = $self->new_form({
    'action'          => $self->hub->url('Json', {'type' => 'Tools', 'action' => $action, 'function' => 'form_submit'}),
    'method'          => 'post',
    'skip_validation' => 1,
    %$params
  });

  $form->add_hidden({
    'name'            => 'load_ticket_url',
    'value'           => $self->hub->url('Json', {'function' => 'load_ticket', 'tl' => 'TICKET_NAME'})
  });

  return $form;
}

sub add_buttons_fieldset {
  ## Adds the genetic buttons fieldset to the tools form
  ## @param Form object
  ## @param Hashref of keys as the name of the extra links needed ('reset' and 'cancel') and value their caption
  ## @return The added fieldset object
  my ($self, $form, $params) = @_;

  my $url       = $self->hub->url({'function' => ''});
  my $fieldset  = $form->add_fieldset;
  my $field     = $fieldset->add_field({
    'type'            => 'submit',
    'value'           => 'Run &rsaquo;'
  });
  my @extras    = (exists $params->{'reset'} ? {
    'node_name'       => 'a',
    'href'            => $url,
    'class'           => [qw(_tools_form_reset left-margin _change_location)],
    'inner_HTML'      => $params->{'reset'}
  } : (), exists $params->{'cancel'} ? {
    'node_name'       => 'a',
    'href'            => $url,
    'class'           => [qw(_tools_form_cancel left-margin _change_location)],
    'inner_HTML'      => $params->{'cancel'}
  } : ());

  $field->elements->[-1]->append_children(@extras) if @extras;

  return $fieldset;
}

sub job_status_tag {
  ## Tag to be displayed next to each job in ticket list table, or job details page
  ## @param Job object
  ## @param Dispatcher status (string)
  ## @param Number of results
  ## @param Current assembly for the job species if it's not the same as the one to which the job was originally submitted to, 0 if species doesn't exist on current site
  ## @param Flag kept on if the job can be viewed on a different assembly website (only applicable if assembly different)
  my ($self, $job, $status, $result_count, $assembly_mismatch, $has_assembly_site) = @_;

  my $css_class = "job-status-$status";
  my $title     = {
    'not_submitted' => q(This job could not be submitted due to some problems. Please click on the 'View details' icon for more information),
    'queued'        => q(Your job has been submitted and will be processed soon.),
    'submitted'     => q(Your job has been submitted and will be processed soon.),
    'running'       => q(Your job is currently being processed. The page will refresh once it's finished running.),
    'done'          => q(This job is finished. Please click on 'View results' link to see the results),
    'failed'        => q(This job has failed. Please click on the 'View details' icon for more information),
    'deleted'       => q(Your ticket has been deleted. This usually happens if the ticket is too old.)
  }->{$status};

  if ($status eq 'done') {
    if ($assembly_mismatch) {
      $css_class  = 'job-status-mismatch';
      $title      = sprintf 'The job was run on %s assembly for %s. ', $job->assembly, $self->hub->species_defs->get_config($job->species, 'SPECIES_COMMON_NAME');
      $title     .= $has_assembly_site && $job->ticket->owner_type ne 'user' ? sprintf('Please save this ticket to your account using the icon on the right to be able to view this job on %s site. ', $job->assembly) : '';
      $title     .= sprintf q(To resubmit the job to %s assembly, please click on the 'Edit &amp; resubmit' icon.), $job->assembly, $assembly_mismatch;
    } elsif (defined $assembly_mismatch && $assembly_mismatch eq '0') {
      $css_class  = 'job-status-mismatch';
      $title      = sprintf q(The job was run on %s which does not exist on this site.), $job->species =~ s/_/ /gr;
    }
  }

  return {
    'node_name'   => 'span',
    'class'       => [$css_class, qw(_ht job-status)],
    'title'       => $title,
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

sub format_date {
  ## Formats datetime from db into a printable form
  ## @param Datetime value
  ## @return String
  my ($self, $datetime) = @_;

  my @date = split /-|T|:/, $datetime;

  return sprintf '%s/%s/%s, %s:%s', $date[2], $date[1], $date[0], $date[3], $date[4];
}

1;
