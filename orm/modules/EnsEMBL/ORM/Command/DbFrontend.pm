package EnsEMBL::ORM::Command::DbFrontend;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Command);

sub get_frontend {
### Instantiates the config module for this frontend
  my $self = shift;
  my ($module, $config);

  if ($self->model->hub->function) {
    $module = $self->model->hub->action;
  }
  else {
    $module = $self->model->hub->type;
  }
  my $class = "EnsEMBL::ORM::DbFrontend::$module";

  if ($self->dynamic_use($class)) {
    $config = $class->new($self->model);
  }
  return $config;
}


1;
