package EnsEMBL::Web::Configuration;

### NAME: EnsEMBL::Web::Configuration
### Extension to the core Configuration module, enabling easy addition of all the standard nodes required by the CRUD interface  

### STATUS: Under development

use strict;

use base qw(EnsEMBL::Web::Root);

my $DBFRONTEND_NODES = {
  'Display'       => {'caption' => 'View All', 'components' => [qw(display  EnsEMBL::ORM::Component::DbFrontend::Display)],       'availability' => 1},
  'List'          => {'caption' => 'List All', 'components' => [qw(list     EnsEMBL::ORM::Component::DbFrontend::List)],          'availability' => 1},
  'Add'           => {'caption' => 'Add',      'components' => [qw(add      EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1},
  'Select/Edit'   => {'caption' => 'Edit',     'components' => [qw(edit     EnsEMBL::ORM::Component::DbFrontend::Select)],        'availability' => 1},
  'Select/Delete' => {'caption' => 'Delete',   'components' => [qw(delete   EnsEMBL::ORM::Component::DbFrontend::Select)],        'availability' => 1},
  'Edit'          => {'caption' => 'Editing',  'components' => [qw(editing  EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1, 'no_menu_entry' => 1},
  'Preview'       => {'caption' => 'Preview',  'components' => [qw(preview  EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1, 'no_menu_entry' => 1},
  'Problem'       => {'caption' => 'Error',    'components' => [qw(error    EnsEMBL::ORM::Component::DbFrontend::Problem)],       'availability' => 1, 'no_menu_entry' => 1},
  'Confirm'       => {'caption' => 'Confirm',  'components' => [qw(confirm  EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete)], 'availability' => 1, 'no_menu_entry' => 1},
  'Save'          => {'caption' => '',         'command'    => 'EnsEMBL::ORM::Command::DbFrontend::Save',                         'availability' => 1, 'no_menu_entry' => 1},
  'Delete'        => {'caption' => '',         'command'    => 'EnsEMBL::ORM::Command::DbFrontend::Delete',                       'availability' => 1, 'no_menu_entry' => 1},
};

sub create_dbfrontend_node {
  ## Creates a dbfrontend page node
  ## @param Node name (or hashref of node name => hashref with keys caption, components, command, availability etc to override the ones given in $DBFRONTEND_NODES)
  my ($self, $node) = @_;

  my $node_name = ref $node ? [keys %$node]->[0]  : $node;
  $node         = ref $node ? $node->{$node_name} : {};
  
  warn 'Not a valid node name for DbFrontend' and return unless exists $DBFRONTEND_NODES->{$node_name};

  exists $node->{$_} or $node->{$_} = $DBFRONTEND_NODES->{$node_name}{$_} for keys %{$DBFRONTEND_NODES->{$node_name}};
  
  $self->create_node($node_name, delete $node->{'caption'}, delete $node->{'components'} || [], $node);
}

sub create_dbfrontend_nodes {
  ## Creates multiple dbfrontend nodes
  ## @params ArrayRef of params as accepted by create_dbfrontend_node
  my ($self, $nodes) = @_;
  $self->create_dbfrontend_node($_) for @$nodes;
}

sub create_all_dbfrontend_nodes {
  ## Adds all nodes to the config
  my $self = shift;
  
  $self->create_dbfrontend_node($_) for keys %$DBFRONTEND_NODES;
}

1;