package EnsEMBL::Web::Component::Tools::TicketsList;

### Displays a generic list of all the tickets available for the user (logged in or not)

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $user          = $hub->user;
  my $object        = $self->object;
  my $tickets       = $object->get_current_tickets;
  my $toggle        = $hub->action ne 'Summary'; # Summary page's table of tickets can not toggled

  my $table         =  $self->new_table([
    { 'key' => 'analysis',  'title' => 'Analysis',      'sort' => 'string'          },
    { 'key' => 'ticket',    'title' => 'Ticket',        'sort' => 'string'          },
    { 'key' => 'jobs',      'title' => 'Jobs',          'sort' => 'none'            },
    { 'key' => 'created',   'title' => 'Submitted at',  'sort' => 'numeric_hidden'  },
    { 'key' => 'extras',    'title' => '',              'sort' => 'none'            }
  ], [], {
    'toggleable'  => $toggle,
    'data_table'  => 'no_col_toggle',
    'exportable'  => 0,
    'id'          => '_ticket_table'
  });

  if ($tickets && @$tickets > 0) {

    foreach my $ticket (@$tickets) {

      my $ticket_name   = $ticket->ticket_name;
      my $jobs_summary  = {};
      my $job_number    = 1;

      for ($ticket->job) {
        my $job_id      = $_->job_id;
        my $job_desc    = $_->job_desc;
        my $hive_status = $_->hive_status;
        $jobs_summary->{$job_id} = sprintf '<p class="job-status">Job %d <span class="job-desc">%s</span>: <span class="job-status-%s _status_%3$s">%s<input type="hidden" value="%s"></span>',
          $job_number++,
          $job_desc ? "($job_desc)" : '',
          $hive_status,
          ucfirst $hive_status =~ s/_/ /gr,
          $job_id
        ;
      }

      my $owner_is_user = $ticket->owner_type eq 'user';
      my $created_at    = $ticket->created_at;
      my $ticket_extras = sprintf '<span class="_ht sprite save_icon%s _ticket_save" title="%s"></span><span class="_ht sprite delete_icon _ticket_delete" title="Delete ticket">',
        !$user || $owner_is_user ? ' sprite_disabled' : '',
        !$owner_is_user ? $user ? 'Save to account' : 'Login to save to account' : 'Saved to account'
      ;

      $table->add_row({
        'analysis'  => $ticket->ticket_type->ticket_type_caption,
        'ticket'    => $self->ticket_link($ticket),
        'jobs'      => join('', sort values %$jobs_summary),
        'created'   => sprintf('<span class="hidden">%d</span>%s', $created_at =~ s/[^\d]//gr, $self->format_date($created_at)),
        'extras'    => $ticket_extras,
        'options'   => {'class' => "_ticket_$ticket_name"}
      });
    }
  }

  my ($tickets_data, $auto_refresh) = $object->get_tickets_data_for_sync;

  return $self->dom->create_element('div', {'children' => [{
    'node_name'   => 'input',
    'type'        => 'hidden',
    'class'       => 'panel_type',
    'value'       => 'ActivitySummary'
  }, {
    'node_name'   => 'input',
    'type'        => 'hidden',
    'name'        => '_delete_url',
    'value'       => $hub->url('Json', {'function' => 'delete', 'tl' => 'TICKET_NAME'})
  }, {
    'node_name'   => 'input',
    'type'        => 'hidden',
    'name'        => '_refresh_url',
    'value'       => $hub->url('Json', {'function' => 'refresh_tickets'})
  }, {
    'node_name'   => 'input',
    'type'        => 'hidden',
    'name'        => '_tickets_data',
    'value'       => [ $tickets_data, 1 ]
  }, {
    'node_name'   => 'input',
    'type'        => 'hidden',
    'name'        => '_auto_refresh',
    'value'       => $auto_refresh
  }, {
    'node_name'   => 'h2',
    'inner_HTML'  => $toggle ? '<a rel="_ticket_table" class="toggle set_cookie open" href="#">Recent Tickets:</a>' : 'Recent Tickets:'
  }, {
    'node_name'   => 'div',
    'class'       => '_countdown'
  }, {
    'node_name'   => 'div',
    'inner_HTML'  => '<p class="_no_jobs hidden">You have no jobs currently running or recently completed.</p>'
  }]})->render.$table->render;

}

sub ticket_link {
  my ($self, $ticket) = @_;
  my $ticket_name = $ticket->ticket_name;

  return sprintf('<a href="%s">%s</a>',
    $self->hub->url({
      'action'    => $ticket->ticket_type->ticket_type_name,
      'function'  => 'Summary',
      'tl'        => $self->object->create_url_param({'ticket_name' => $ticket_name})
    }),
    $ticket_name
  );
}

1;
