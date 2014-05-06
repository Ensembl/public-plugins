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

sub _init {
  ## Makes all the components in tools ajaxable but not cacheable
  ## Override this in a child class to modify the default behaviour
  ## Make the Ajax request for loading components is sent via POST in case long query_sequence is there.
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(['query_sequence']);
}

sub get_job_summary {
  ## Reads the job dispatcher_status field, and display status accordingly
  ## @param Job object
  ## @param Extra params hashref with keys:
  ##  - links: Arrayref with name of the links that need to be displayed (results, edit, delete)
  ## @return DIV node
  my ($self, $job, $params) = @_;

  my $hub               = $self->hub;
  my $job_id            = $job->job_id;
  my $job_message       = $job->job_message->[0];
  my $job_status        = $job->status;
  my $dispatcher_status = $job->dispatcher_status;
  my $url_param         = $self->object->create_url_param({'job_id' => $job_id});
  my $job_status_div    = $self->dom->create_element('div', {
    'children'            => [{
      'node_name'           => 'p',
      'inner_HTML'          => sprintf('Job %s: %s', $job->job_number, $job->job_desc // '-')
    }, {
      'node_name'           => 'p',
      'class'               => 'job-status-links',
      'children'            => [{
        'node_name'           => 'span',
        'class'               => ['job-status', "job-status-$dispatcher_status"],
        'inner_HTML'          => ucfirst $dispatcher_status =~ s/_/ /gr
      }]
    }]
  });

  if ($job_status eq 'done') {
    $job_status_div->last_child->append_child('a', {
      'class'       => [qw(small left-margin results-link)],
      'flags'       => ['view_results_link'],
      'inner_HTML'  => '[View results]',
      'href'        => $hub->url({
        'species'     => $job->species,
        'type'        => 'Tools',
        'action'      => $job->ticket->ticket_type_name,
        'function'    => 'Results',
        'tl'          => $url_param
      })
    });
  }

  my $icons = {
    'edit'    => {'icon' => 'edit_icon',    'title' => 'Edit &amp; resubmit', 'url' => [        {'function' => 'Edit',    'tl' => $url_param  }], 'class' => '_ticket_edit _change_location'},
    'delete'  => {'icon' => 'delete_icon',  'title' => 'Delete',              'url' => ['Json', {'function' => 'delete',  'tl' => $url_param  }], 'class' => '_json_link', 'confirm' => "This will delete this job permanently."}
  };

  my $margin_left_class = 'left-margin';

  foreach my $link (@{($params || {})->{'links'} || []}) {
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

    my $display_message         = $job_message->display_message;
    my $exception_is_fatal      = $job_message->fatal;
    my $job_message_class       = "_job_message_$job_id";
    my $error_div               = $job_status_div->append_child('div', {
      'class'       => 'job-error-msg',
      'children'    => [{
        'node_name'   => 'p',
        'inner_HTML'  => join('', $display_message, $exception_is_fatal ? sprintf(' <a class="toggle closed" href="#more" rel="%s">Show details</a>', $job_message_class) : '')
      }]
    });

    if ($exception_is_fatal) {
      my $exception = $job_message->exception;
      my $details   = $exception->{'message'} ? "Error with message: $exception->{'message'}\n" : "Error:\n";
         $details  .= $exception->{'stack'}
        ? join("\n", map(sprintf("Thrown by %s at %s (%s)", $_->[3], $_->[0], $_->[2]), @{$exception->{'stack'}}))
        : $exception->{'exception'} || 'No details'
      ;

      my $helpdesk_details = sprintf 'This seems to be a problem with %s website code. Please contact our <a href="%s" class="modal_link">helpdesk</a> to report this problem.',
        $hub->species_defs->ENSEMBL_SITETYPE,
        $hub->url({'type' => 'Help', 'action' => 'Contact', 'subject' => 'Exception in Web Tools', 'message' => sprintf("\n\n\n%s with message (%s) (for job %s): %s", $job_message->exception->{'class'} || 'Exception', $display_message, $job_id, $details)})
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
  my ($self, $form, $params) = @_;

  my $url     = $self->hub->url({'function' => ''});
  my $field   = $form->add_fieldset->add_field({
    'type'            => 'submit',
    'value'           => 'Run &rsaquo;'
  });
  my @extras  = (exists $params->{'reset'} ? {
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
