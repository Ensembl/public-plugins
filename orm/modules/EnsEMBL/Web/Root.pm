package EnsEMBL::Web::Root;

### Extends E::W::Root by adding a method needed by CRUD Components, Commands, etc

sub get_frontend_config {
### Instantiates the config module for the Ensembl CRUD frontend
  my $self = shift;
  my $config;

  my $class = 'EnsEMBL::ORM::DbFrontend::'.$self->model->hub->type;

  if (!$self->dynamic_use($class)) {
    ## Fall back to using generic configuration
    use EnsEMBL::ORM::DbFrontend;
    $class = 'EnsEMBL::ORM::DbFrontend';
  }
  $config = $class->new($self->model);
  return $config;
}

1;
