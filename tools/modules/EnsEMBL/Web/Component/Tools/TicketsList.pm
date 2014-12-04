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

use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

use parent qw(EnsEMBL::Web::Component::Tools);

sub content {
  my $self          = shift;
  my $class         = ref $self;
  my $hub           = $self->hub;
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
    'data_table'      => 1,
    'exportable'      => 0,
    'hidden_columns'  => [1],
  });

  if ($tickets && @$tickets > 0) {

    foreach my $ticket (@$tickets) {

      my $ticket_type = $ticket->ticket_type_name;
      my $ticket_name = $ticket->ticket_name;

      # Decorator design pattern
      my $component = $class eq __PACKAGE__ && dynamic_require(__PACKAGE__ =~ s/(::[^:]+)$/::$ticket_type$1/r, 1) || $class; # fallback to the generic parent class
      bless $self, $component unless ref $self eq $component;

      my @jobs_summary  = map $self->job_summary_section($ticket, $_, $_->result_count)->render, $ticket->job;
      my $created_at    = $ticket->created_at;

      $table->add_row({
        'analysis'  => $self->analysis_caption($ticket),
        'ticket'    => $self->ticket_link($ticket),
        'jobs'      => join('', @jobs_summary),
        'created'   => sprintf('<span class="hidden">%d</span>%s', $created_at =~ s/[^\d]//gr, $self->format_date($created_at)),
        'extras'    => $self->ticket_buttons($ticket)->render,
        'options'   => {'class' => "_ticket_$ticket_name"}
      });
    }

    bless $self, $class unless ref $self eq $class; # back to the original class
  }

  my ($tickets_data_hash, $auto_refresh) = $object->get_tickets_data_for_sync;

  return $self->dom->create_element({
    'node_name'   => 'div',
    'children'    => [{
      'node_name'   => 'input',
      'type'        => 'hidden',
      'class'       => ['panel_type'],
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
      'inner_HTML'  => $tool_type ? qq(<a rel="_activity_summary" class="toggle _slide_toggle set_cookie open" href="#">Recent $tool_type tickets:</a>) : 'Recent tickets:'
    }, {
      'node_name'   => 'div',
      'class'       => [qw(toggleable _activity_summary)],
      'children'    => [{
        'node_name'   => 'div',
        'class'       => ['_ticket_table'],
        'children'    => [{
          'node_name'   => 'p',
          'children'    => [{
            'node_name'   => 'a',
            'href'        => '',
            'class'       => [qw(button _tickets_refresh)],
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

sub job_summary_section {
  my ($self, $ticket, $job, $result_count) = @_;

  my $hub               = $self->hub;
  my $object            = $self->object;
  my $url_param         = $object->create_url_param({'ticket_name' => $ticket->ticket_name, 'job_id' => $job->job_id});
  my $action            = $ticket->ticket_type_name;
  my $species_defs      = $hub->species_defs;
  my $dispatcher_status = $job->dispatcher_status;
  my $job_species       = $job->species;
  my $valid_job_species = $species_defs->tools_valid_species($job_species);
  my $job_assembly      = $job->assembly;
  my $current_assembly  = $valid_job_species ? $species_defs->get_config($job_species, 'ASSEMBLY_VERSION') : '0';
  my $assembly_mismatch = $job_assembly ne $current_assembly;
  my $switch_assembly   = $species_defs->get_config($job_species, 'SWITCH_ASSEMBLY') || '';
  my $assembly_site     = $assembly_mismatch && $switch_assembly eq $job_assembly ? 'http://'.$species_defs->get_config($job_species, 'SWITCH_ARCHIVE_URL') : '';
  my $job_description   = $object->get_job_description($job);

  my $result_url = $dispatcher_status eq 'done' ? {
    '__clear'     => !!$assembly_site, # remove extra params for the external site
    'species'     => $job_species,
    'type'        => 'Tools',
    'action'      => $ticket->ticket_type_name,
    'function'    => 'Results',
    'tl'          => $url_param
  } : undef;

  if ($result_url && $assembly_mismatch) {
    if ($assembly_site && $ticket->owner_type eq 'user') { # if job is from another assembly and we do have a site for that assembly
      $result_url = { # result can only be seen by logged in user
        'then'      => $hub->url($result_url),
        'type'      => 'Account',
        'action'    => 'Login',
      };
    } else { # if job is from another assembly and we do NOT have a site for that assembly
      $result_url = undef;
    }
  }

  return $self->dom->create_element('p', {
    'children'    => [{
      'node_name'   => 'img',
      'class'       => [qw(job-species _ht)],
      'title'       => $valid_job_species ? $species_defs->species_label($job_species, 1) : $job_species =~ s/_/ /rg,
      'src'         => sprintf('%sspecies/16/%s.png', $self->img_url, $job_species),
      'alt'         => '',
      'style'       => {
        'width'       => '16px',
        'height'      => '16px'
      }
    }, {
      'node_name'   => 'span',
      'class'       => ['right-margin'],
      'flags'       => ['job_desc_span'],
      'inner_HTML'  => $job_description
    },
    $self->job_status_tag($job, $dispatcher_status, $result_count, $assembly_mismatch && $current_assembly, !!$assembly_site),
    $result_url ? {
      'node_name'   => 'a',
      'inner_HTML'  => $assembly_site ? "[View results on $job_assembly site]" : '[View results]',
      'flags'       => ['job_results_link'],
      'class'       => [qw(small left-margin)],
      'href'        => sprintf('%s%s', $assembly_site, $hub->url($result_url))
    } : (), {
      'node_name'   => 'span',
      'class'       => ['job-sprites'],
      'children'    => [{
        'node_name'   => 'a',
        'class'       => [qw(_ticket_view _change_location job-sprite)],
        'href'        => $hub->url({'action' => $action, 'function' => 'View', 'tl' => $url_param}),
        'children'    => [{
          'node_name'   => 'span',
          'class'       => [qw(_ht sprite view_icon)],
          'title'       => 'View details'
        }]
      }, {
        'node_name'     => 'a',
        'class'         => [qw(_ticket_edit _change_location job-sprite)],
        'href'          => $hub->url({'action' => $action, 'function' => 'Edit', 'tl' => $url_param}),
        'children'      => [{
          'node_name'     => 'span',
          'class'         => [qw(_ht sprite edit_icon)],
          'title'         => 'Edit &amp; resubmit job (create a new ticket)'
        }]
      }, {
        'node_name'     => 'a',
        'class'         => [qw(_json_link job-sprite)],
        'href'          => $hub->url('Json', {'action' => $action, 'function' => 'delete', 'tl' => $url_param}),
        'children'      => [{
          'node_name'     => 'span',
          'class'         => [qw(_ht sprite delete_icon)],
          'title'         => 'Delete job'
        }, {
          'node_name'     => 'span',
          'class'         => [qw(hidden _confirm)],
          'inner_HTML'    => qq(This will delete the following job permanently:\n$job_description)
        }]
      }]}
    ]
  });
}

sub ticket_link {
  my ($self, $ticket) = @_;
  my $ticket_name = $ticket->ticket_name;

  return sprintf('<a class="_ticket_view _change_location" href="%s">%s</a>',
    $self->hub->url({
      'action'    => $ticket->ticket_type_name,
      'function'  => 'View',
      'tl'        => $self->object->create_url_param({'ticket_name' => $ticket_name})
    }),
    $ticket_name
  );
}

sub ticket_buttons {
  my ($self, $ticket) = @_;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $user          = $hub->user;
  my $owner_is_user = $ticket->owner_type eq 'user';
  my $url_param     = $object->create_url_param({'ticket_name' => $ticket->ticket_name});
  my $job_count     = $ticket->job_count;
  my $action        = $ticket->ticket_type_name;

  my $save_button   = {
    'node_name'       => 'span',
    'class'           => [qw(_ht sprite save_icon), $user && $owner_is_user ? 'sprite_disabled' : ()],
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
      'title'           => 'Edit &amp; resubmit ticket (create new ticket)'
    }]
  }, {
    'node_name'       => 'a',
    'class'           => ['_json_link'],
    'href'            => $hub->url('Json', {'action' => $action, 'function' => 'delete', 'tl' => $url_param}),
    'children'        => [{
      'node_name'       => 'span',
      'class'           => [qw(_ht sprite delete_icon)],
      'title'           => 'Delete ticket'
    }, {
      'node_name'       => 'span',
      'class'           => [qw(hidden _confirm)],
      'inner_HTML'      => $job_count == 1
        ? sprintf("This will delete the following job permanently:\n%s", $object->get_job_description($ticket->job->[0]))
        : sprintf('This will delete %s jobs for this ticket.', $job_count == 2 ? 'both' : "all $job_count")
    }]
  }]});

  return $buttons;
}

sub analysis_caption {
  my ($self, $ticket) = @_;
  return $ticket->ticket_type->ticket_type_caption;
}

1;
