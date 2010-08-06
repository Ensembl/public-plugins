package EnsEMBL::Web::Configuration::Help;

sub modify_tree {
  my $self = shift;

  ## Remove standard Help tree
  $self->delete_tree;

  ## Add defaults
  $self->add_dbfrontend_to_tree(['WebAdmin'], [qw(View Faq Glossary Movie)]);
}

1;
