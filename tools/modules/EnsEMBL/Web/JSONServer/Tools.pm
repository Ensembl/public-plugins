=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

sub json_save {
  my $self = shift;

  $self->object->save_ticket_to_account;

  return $self->call_js_panel_method('refresh', [ 1 ]);
}

sub json_delete {
  my $self = shift;

  $self->object->delete_ticket_or_job;

  return $self->call_js_panel_method('refresh');
}

sub json_refresh_tickets {
  my $self          = shift;
  my $tickets_old   = $self->hub->param('tickets');

  my ($tickets_new, $auto_refresh) = $self->object->get_tickets_data_for_sync;

  return $self->call_js_panel_method('updateTicketList', [ $tickets_old eq $tickets_new ? undef : $tickets_new, $auto_refresh ]);
}

sub json_load_ticket {
  my $self = shift;

  return $self->call_js_panel_method('populateForm', [ [ map $_->job_data->raw, $self->object->get_requested_ticket->job ] ]);
}

1;
