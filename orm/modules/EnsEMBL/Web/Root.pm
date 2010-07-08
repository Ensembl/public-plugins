package EnsEMBL::Web::Root;

### Extends E::W::Root by adding a method needed by both Components and Commands

sub get_frontend_config {
### Instantiates the config module for the Ensembl CRUD frontend
  my $self = shift;
  my $config;

  my $class = 'EnsEMBL::ORM::DbFrontend::'.$module = $self->model->hub->type;

  if ($self->dynamic_use($class)) {
    $config = $class->new($self->model);
  }
  return $config;
}

