package EnsEMBL::Web::Configuration::Help;

sub modify_tree {
  my $self = shift;

  ## Add defaults
  $self->add_dbfrontend_to_tree(['WebAdmin']);
}

1;
