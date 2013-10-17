package EnsEMBL::Web::JSONServer::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::JSONServer);

sub object_type { 'Tools' }

sub json_form_submit {
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $jobs_data     = $object->form_inputs_to_jobs_data;

  if ($jobs_data && @$jobs_data) {
    $object->create_ticket($jobs_data);
    return $self->call_js_panel_method('ticketSubmitted');
  }

  return $self->call_js_panel_method('showError', ['Input provided is invalid', 'Invalid input']);
}

sub json_read_file {

}

sub json_delete {
  my $self    = shift;
  my $object  = $self->object;
  
  $object->delete_ticket_or_job;

  return $self->call_js_panel_method('refresh');
}

sub json_refresh_tickets {
  my $self          = shift;
  my $tickets       = $self->object->get_current_tickets;
  my $tickets_data  = {};

  if ($tickets && @$tickets > 0) {

    foreach my $ticket (@$tickets) {

      my $ticket_name = $ticket->ticket_name;
      $tickets_data->{$ticket_name}{$_->job_id} = $_->hive_status for $ticket->job;
    }
  }

  return $self->call_js_panel_method('updateTicketList', [ $self->jsonify($tickets_data) ]);
}

1;