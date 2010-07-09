package EnsEMBL::ORM::Command::DbFrontend::Delete;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Delete
### Module to delete/retire one or more EnsEMBL::ORM::Rose::Object-based records

### STATUS: Under Development

### DESCRIPTION:

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub = $self->model->hub;
  my $param = {};
  my $config = $self->get_frontend_config;

  my $data = $self->model->object;
  my $permit_delete = $config->{'permit_delete'};
  my $success = 0;

  if ($permit_delete) {
    if (ref($permit_delete) eq 'ARRAY') {
      $success = $data->retire($permit_delete);
    }
    elsif ($permit_delete == 1) {
      $success = $data->delete;
    }
  }

  my $url = '/'.$hub->type.'/';
  if ($success) {
    $url .= 'List';
  }
  else {
    $url .= 'Problem';
    $param = {'error' => 'delete'};
  }

  $self->ajax_redirect($url, $param);
}

1;
