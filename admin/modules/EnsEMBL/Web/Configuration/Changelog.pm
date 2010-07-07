package EnsEMBL::Web::Configuration::Changelog;

sub populate_tree {
  my $self = shift;

  ## Add defaults
  $self->add_dbfrontend_to_tree(['WebAdmin']);

  $self->create_node( 'Summary', 'Show all',
    [qw(summary EnsEMBL::ORM::Component::Changelog::Summary)],
    { 'availability' => 1}
  );

}

1;
