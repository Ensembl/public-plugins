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

package EnsEMBL::Web::JSONServer::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::JSONServer);

sub object_type { 'Tools' }

sub json_form_submit {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $ticket    = $object->ticket_class->new($object);

  $ticket->process;

  return $self->call_js_panel_method('showError', [ $ticket->error, 'Invalid input' ]) if $ticket->error;
  return $self->call_js_panel_method('ticketSubmitted');
}

sub json_save {
  my $self = shift;

  $self->object->save_ticket_to_account;

  return $self->call_js_panel_method('refresh', [ 1 ]);
}

sub json_delete {
  my $self = shift;

  $self->object->delete_ticket_or_job;

  return $self->call_js_panel_method('refresh', [ 1 ]);
}

sub json_refresh_tickets {
  my $self          = shift;
  my $tickets_old   = $self->hub->param('tickets');

  my ($tickets_new, $auto_refresh) = $self->object->get_tickets_data_for_sync;

  return $self->call_js_panel_method('updateTicketList', [ $tickets_old eq $tickets_new ? undef : $tickets_new, $auto_refresh ]);
}

sub json_load_ticket {
  my $self = shift;

  return $self->call_js_panel_method('populateForm', [ $self->object->get_edit_jobs_data ]);
}

1;
