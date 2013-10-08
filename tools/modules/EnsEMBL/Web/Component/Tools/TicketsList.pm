package EnsEMBL::Web::Component::Tools::TicketsList;

### Displays a generic list of all the tickets available for the user (logged in or not)

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $user    = $hub->user;
  my $object  = $self->object;
  my $tickets = $object->get_current_tickets;
  my $toggle  = $hub->action ne 'Summary'; # Summary page's table of tickets can not toggled

  my $table   =  $self->new_table([
    { 'key' => 'analysis',  'title' => 'Analysis',      'sort' => 'string'  },
    { 'key' => 'ticket',    'title' => 'Ticket',        'sort' => 'string'  },
    { 'key' => 'jobs',      'title' => 'Jobs',          'sort' => 'none'    },
    { 'key' => 'created',   'title' => 'Submitted at',  'sort' => 'string'  },
    { 'key' => 'extras',    'title' => '',              'sort' => 'none'    }
  ], [], {
    'toggleable'  => $toggle,
    'data_table'  => 'no_col_toggle',
    'exportable'  => 0,
    'sorting'     => ['created desc'],
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
      my $ticket_extras = sprintf '<span class="_ht sprite save_icon%s _ticket_save" title="%s"></span><span class="_ht sprite delete_icon _ticket_delete" title="Delete ticket">',
        !$user || $owner_is_user ? ' sprite_disabled' : '',
        !$owner_is_user ? $user ? 'Save to account' : 'Login to save to account' : 'Saved to account'
      ;

      $table->add_row({
        'analysis'  => $ticket->ticket_type->ticket_type_caption,
        'ticket'    => sprintf('<a href="%s">%s</a>', $hub->url({'action' => $ticket->ticket_type->ticket_type_name, 'function' => 'Summary', 'tl' => $object->create_url_param({'ticket_name' => $ticket_name})}), $ticket_name),
        'jobs'      => join('', sort values %$jobs_summary),
        'created'   => $self->format_date($ticket->created_at),
        'extras'    => $ticket_extras
      });
    }
  }

  return sprintf '
    <div><input type="hidden" class="panel_type" value="Jobs" />%s
      <div class="countdown"></div>
      <div><p class="_no_jobs hidden">You have no jobs currently running or recently completed.</p></div>
    </div>%s',
    $toggle ? sprintf('<h2><a rel="_ticket_table" class="toggle set_cookie open" href="#">Recent Tickets:</a></h2>') : '<h2>Recent Tickets:</h2>',
    $table->render
  ;
};

1;
