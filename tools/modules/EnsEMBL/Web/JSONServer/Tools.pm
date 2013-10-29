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
    
    # error?
    return $self->call_js_panel_method('showError', [$jobs_data->[0]->{error}, 'Invalid input']) if defined($jobs_data->[0]->{error});
    
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
  my $tickets_old   = $self->hub->param('tickets');

  my ($tickets_new, $auto_refresh) = $self->object->get_tickets_data_for_sync;

  return $self->call_js_panel_method('updateTicketList', [ $tickets_old eq $tickets_new ? undef : $tickets_new, $auto_refresh ]);
}

1;