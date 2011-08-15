package EnsEMBL::Web::Configuration;

### NAME: EnsEMBL::Web::Configuration
### Extension to the core Configuration module, enabling easy addition of all the standard nodes required by the CRUD interface

### STATUS: Under development

use strict;

use constant DEFAULT_ACTION => 'List';

sub set_default_action {
  ## @overrides
  ## Override the constant DEFAULT_ACTION instead of overriding this method in child classes
  my $self = shift;
  $self->{'_data'}{'default'} = $self->DEFAULT_ACTION;
}

sub dbfrontend_nodes {
  ## Gets all the default nodes needed by dbfrontend
  ## @param HashRef with keys required to override keys in each node
  ## @return Hash in ArrayRef syntax
  my ($self, $params) = @_;

  my $nodes = [
    'Display'       => {'caption' => 'View All', 'components' => [qw(display  EnsEMBL::ORM::Component::DbFrontend::Display)],       'availability' => 1},
    'List'          => {'caption' => 'List All', 'components' => [qw(list     EnsEMBL::ORM::Component::DbFrontend::List)],          'availability' => 1},
    'Add'           => {'caption' => 'Add',      'components' => [qw(add      EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1},
    'Duplicate'     => {'caption' => 'Duplicate','components' => [qw(copy     EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1, 'no_menu_entry' => 1},
    'Select/Edit'   => {'caption' => 'Edit',     'components' => [qw(edit     EnsEMBL::ORM::Component::DbFrontend::Select)],        'availability' => 1, 'no_menu_entry' => 1},
    'Select/Delete' => {'caption' => 'Delete',   'components' => [qw(delete   EnsEMBL::ORM::Component::DbFrontend::Select)],        'availability' => 1, 'no_menu_entry' => 1},
    'Edit'          => {'caption' => 'Editing',  'components' => [qw(editing  EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1, 'no_menu_entry' => 1},
    'Preview'       => {'caption' => 'Preview',  'components' => [qw(preview  EnsEMBL::ORM::Component::DbFrontend::Input)],         'availability' => 1, 'no_menu_entry' => 1},
    'Problem'       => {'caption' => 'Error',    'components' => [qw(error    EnsEMBL::ORM::Component::DbFrontend::Problem)],       'availability' => 1, 'no_menu_entry' => 1},
    'Confirm'       => {'caption' => 'Confirm',  'components' => [qw(confirm  EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete)], 'availability' => 1, 'no_menu_entry' => 1},
    'Save'          => {'caption' => '',         'command'    => 'EnsEMBL::ORM::Command::DbFrontend::Save',                         'availability' => 1, 'no_menu_entry' => 1},
    'Delete'        => {'caption' => '',         'command'    => 'EnsEMBL::ORM::Command::DbFrontend::Delete',                       'availability' => 1, 'no_menu_entry' => 1},
  ];

  foreach my $node (@$nodes) {
    ref $node and map {$node->{$_} = $self->deepcopy($params->{$_})} keys %{$params || {}};
  }
  return $nodes;
}

sub create_dbfrontend_node {
  ## Creates a dbfrontend page node
  ## @param Node name (or hashref of node name => hashref with keys caption, components, command, availability etc to override the ones given in &dbfrontend_nodes)
  my ($self, $node) = @_;

  my $node_name = ref $node ? [keys %$node]->[0]  : $node;
  $node         = ref $node ? $node->{$node_name} : {};
  
  my $all_nodes = {@{$self->dbfrontend_nodes}};
  
  warn 'Not a valid node name for DbFrontend' and return unless exists $all_nodes->{$node_name};

  exists $node->{$_} or $node->{$_} = $all_nodes->{$node_name}{$_} for keys %{$all_nodes->{$node_name}};
  
  $self->create_node($node_name, delete $node->{'caption'}, delete $node->{'components'} || [], $node);
}

sub create_dbfrontend_nodes {
  ## Creates multiple dbfrontend nodes
  ## @param ArrayRef of params as accepted by create_dbfrontend_node
  ## @param Hashref with keys to override the ones in default dbfronend nodes 
  my ($self, $nodes) = @_;
  $self->create_dbfrontend_node($_) for @$nodes;
}

sub create_all_dbfrontend_nodes {
  ## Adds all nodes to the config
  ## @param Hashref that is added to each node's options
  my ($self, $params) = @_;
  my $all_nodes = $self->dbfrontend_nodes($params);
  my $nodes = [];
  
  while (my $node_name = shift @$all_nodes) {
    my $node = shift @$all_nodes;
    push @$nodes, $self->create_node($node_name, delete $node->{'caption'}, delete $node->{'components'} || [], $node);
  }
  return $nodes;
}

1;