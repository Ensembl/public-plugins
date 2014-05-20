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

package EnsEMBL::Web::Component::Tools::TicketsList;

### Displays a generic list of all the tickets available for the user (logged in or not)

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $sd            = $hub->species_defs;
  my $object        = $self->object;
  my $tickets       = $object->get_current_tickets;
  my $tool_type     = $object->tool_type;
  
  my $table         =  $self->new_table([
    { 'key' => 'analysis',  'title' => 'Analysis',      'sort' => 'string'          },
    { 'key' => 'ticket',    'title' => 'Ticket',        'sort' => 'string'          },
    { 'key' => 'jobs',      'title' => 'Jobs',          'sort' => 'none'            },
    { 'key' => 'created',   'title' => 'Submitted at',  'sort' => 'numeric_hidden'  },
    { 'key' => 'extras',    'title' => '',              'sort' => 'none'            }
  ], [], {
    'data_table'  => 'no_col_toggle',
    'exportable'  => 0
  });

  my $status_tips   = {
    'not_submitted'   => q(This job could not be submitted due to some problems. Please click on the 'View details' icon for more information),
    'queued'          => q(Your job has been submitted and will be processed soon.),
    'submitted'       => q(Your job has been submitted and will be processed soon.),
    'running'         => q(Your job is currently being processed. The page will refresh once it's finished running.),
    'done'            => q(This job is finished. Please click on 'View results' link to see the results),
    'failed'          => q(This job has failed. Please click on the 'View details' icon for more information),
    'deleted'         => q(Your ticket has been deleted. This usually happens if the ticket is too old.)
  };

  if ($tickets && @$tickets > 0) {

    foreach my $ticket (@$tickets) {

      my $ticket_name   = $ticket->ticket_name;
      my @jobs_summary;

      for ($ticket->job) {
        my $job_number        = $_->job_number;
        my $dispatcher_status = $_->dispatcher_status;
        push @jobs_summary, sprintf('<p><img class="job-species _ht" title="%s" src="%sspecies/16/%s.png" alt="" height="16" width="16"><span class="job-desc">%s%s</span><span class="_ht job-status job-status-%s left-margin" title="%s">%s</span>%s%s',
          $sd->species_label($_->species, 1),
          $self->img_url,
          $_->species,
          $job_number ? "Job $job_number: " : '',
          $_->job_desc || '',
          $dispatcher_status,
          $status_tips->{$dispatcher_status},
          ucfirst $dispatcher_status =~ s/_/ /gr,
          $self->job_results_link($ticket, $_),
          $self->job_buttons($ticket, $_)
        );
      }

      my $created_at = $ticket->created_at;

      $table->add_row({
        'analysis'  => $ticket->ticket_type->ticket_type_caption,
        'ticket'    => $self->ticket_link($ticket),
        'jobs'      => join('', @jobs_summary),
        'created'   => sprintf('<span class="hidden">%d</span>%s', $created_at =~ s/[^\d]//gr, $self->format_date($created_at)),
        'extras'    => $self->ticket_buttons($ticket)->render,
        'options'   => {'class' => "_ticket_$ticket_name"}
      });
    }
  }

  my ($tickets_data_hash, $auto_refresh) = $object->get_tickets_data_for_sync;

  return $self->dom->create_element({
    'node_name'   => 'div',
    'children'    => [{
      'node_name'   => 'input',
      'type'        => 'hidden',
      'class'       => 'panel_type',
      'value'       => 'ActivitySummary'
    }, {
      'node_name'   => 'input',
      'type'        => 'hidden',
      'name'        => '_refresh_url',
      'value'       => $hub->url('Json', {'function' => 'refresh_tickets'})
    }, {
      'node_name'   => 'input',
      'type'        => 'hidden',
      'name'        => '_tickets_data_hash',
      'value'       => $tickets_data_hash
    }, {
      'node_name'   => 'input',
      'type'        => 'hidden',
      'name'        => '_auto_refresh',
      'value'       => $auto_refresh
    }, {
      'node_name'   => 'h2',
      'inner_HTML'  => $tool_type ? qq(<a rel="_activity_summary" class="toggle set_cookie open" href="#">Recent $tool_type tickets:</a>) : 'Recent tickets:'
    }, {
      'node_name'   => 'div',
      'class'       => ['toggleable', '_activity_summary'],
      'children'    => [{
        'node_name'   => 'div',
        'class'       => '_ticket_table',
        'children'    => [{
          'node_name'   => 'p',
          'children'    => [{
            'node_name'   => 'a',
            'href'        => '',
            'class'       => 'button _tickets_refresh',
            'inner_HTML'  => '<span class="tickets-refresh"></span><span class="hidden tickets-timer"></span><span>Refresh</span>'
          }]
        }, {
          'node_name'   => 'div',
          'inner_HTML'  => $table->render
        }]
      }, {
        'node_name'   => 'div',
        'class'       => [qw(_no_jobs hidden)],
        'inner_HTML'  => '<p>You have no jobs currently running or recently completed.</p>',
      }]
    }]
  })->render;
}

sub ticket_link {
  my ($self, $ticket) = @_;
  my $ticket_name = $ticket->ticket_name;

  return sprintf('<a class="_ticket_view _change_location" href="%s">%s</a>',
    $self->hub->url({
      'action'    => $ticket->ticket_type->ticket_type_name,
      'function'  => 'View',
      'tl'        => $self->object->create_url_param({'ticket_name' => $ticket_name})
    }),
    $ticket_name
  );
}

sub ticket_buttons {
  my ($self, $ticket) = @_;
  my $hub           = $self->hub;
  my $user          = $hub->user;
  my $ticket_name   = $ticket->ticket_name;
  my $owner_is_user = $ticket->owner_type eq 'user';
  my $url_param     = $self->object->create_url_param({'ticket_name' => $ticket_name});
  my $action        = $ticket->ticket_type->ticket_type_name;

  my $save_button   = {
    'node_name'       => 'span',
    'class'           => ['_ht', 'sprite', 'save_icon', $user && $owner_is_user ? 'sprite_disabled' : ()],
    'title'           => $user ? $owner_is_user ? 'Already saved to account' : 'Save to account' : 'Login to save to account'
  };

  $save_button      = {
    'node_name'       => 'a',
    'class'           => [ $user ? '_json_link' : 'modal_link' ],
    'href'            => $user ? $hub->url('Json', {'type' => 'Tools', 'action' => $action, 'function' => 'save', 'tl' => $url_param}) : $hub->url({'type' => 'Account', 'action' => 'Login'}),
    'children'        => [ $save_button ]
  } unless $owner_is_user;

  my $buttons       = $self->dom->create_element('div', { 'children' => [ $save_button, {
    'node_name'       => 'a',
    'class'           => [qw(_ticket_edit _change_location)],
    'href'            => $hub->url({'action' => $action, 'function' => 'Edit', 'tl' => $url_param}),
    'children'        => [{
      'node_name'       => 'span',
      'class'           => [qw(_ht sprite edit_icon)],
      'title'           => 'Edit &amp; resubmit ticket'
    }]
  }, {
    'node_name'       => 'a',
    'class'           => '_json_link',
    'href'            => $hub->url('Json', {'action' => $action, 'function' => 'delete', 'tl' => $url_param}),
    'children'        => [{
      'node_name'       => 'span',
      'class'           => [ '_ht', 'sprite', 'delete_icon' ],
      'title'           => 'Delete ticket'
    }, {
      'node_name'       => 'span',
      'class'           => 'hidden _confirm',
      'inner_HTML'      => "This will delete ticket '$ticket_name' permanently."
    }]
  }]});

  return $buttons;
}

sub job_results_link {
  my ($self, $ticket, $job) = @_;
  return $job->dispatcher_status eq 'done'
    ? sprintf('<a class="small left-margin" href="%s">[View results]</a>', $self->hub->url({
      'species'   => $job->species,
      'type'      => 'Tools',
      'action'    => $ticket->ticket_type_name,
      'function'  => 'Results',
      'tl'        => $self->object->create_url_param({'ticket_name' => $ticket->ticket_name, 'job_id' => $job->job_id})
    }))
    : '';
}

sub job_buttons {
  my ($self, $ticket, $job) = @_;

  my $hub           = $self->hub;
  my $ticket_name   = $ticket->ticket_name;
  my $url_param     = $self->object->create_url_param({'ticket_name' => $ticket_name, 'job_id' => $job->job_id});
  my $action        = $ticket->ticket_type->ticket_type_name;

  return $self->dom->create_element('span', { 'class' => 'job-sprites', 'children' => [ {
    'node_name'       => 'a',
    'class'           => [qw(_ticket_view _change_location job-sprite)],
    'href'            => $hub->url({'action' => $action, 'function' => 'View', 'tl' => $url_param}),
    'children'        => [ {
      'node_name'       => 'span',
      'class'           => [qw(_ht sprite view_icon)],
      'title'           => 'View details'
    }]
  }, {
    'node_name'       => 'a',
    'class'           => [qw(_ticket_edit _change_location job-sprite)],
    'href'            => $hub->url({'action' => $action, 'function' => 'Edit', 'tl' => $url_param}),
    'children'        => [{
      'node_name'       => 'span',
      'class'           => [qw(_ht sprite edit_icon)],
      'title'           => 'Edit &amp; resubmit job'
    }]
  }, {
    'node_name'       => 'a',
    'class'           => [qw(_json_link job-sprite)],
    'href'            => $hub->url('Json', {'action' => $action, 'function' => 'delete', 'tl' => $url_param}),
    'children'        => [{
      'node_name'       => 'span',
      'class'           => [ '_ht', 'sprite', 'delete_icon' ],
      'title'           => 'Delete job'
    }, {
      'node_name'       => 'span',
      'class'           => 'hidden _confirm',
      'inner_HTML'      => @{$ticket->job} > 1 ? sprintf(q(This will delete job number %s from ticket '%s' permanently.), $job->job_number, $ticket_name) : sprintf(q(This will delete ticket '%s' permanently.), $ticket_name)
    }]
  }]})->render;
}

1;
