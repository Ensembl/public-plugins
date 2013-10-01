package EnsEMBL::Web::JSONServer::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::JSONServer);

sub object_type { 'Tools' }

sub json_form_submit {
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object;

  my $ticket_type   = $object->get_ticket_type_object($hub->param('ensembl_tool'));

  if ($ticket_type) {
    my $jobs_data = $object->form_inputs_to_jobs_data;

    if ($jobs_data && @$jobs_data) {
      $object->create_ticket($ticket_type, $jobs_data);
      return {'panelMethod' => ['refreshJobsList']};
    }
  }

  return {'invalid' => 1};
}

sub json_read_file {

}

1;