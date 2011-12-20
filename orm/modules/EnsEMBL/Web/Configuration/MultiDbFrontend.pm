package EnsEMBL::Web::Configuration::MultiDbFrontend;

### Description:
### This class inherited from EnsEMBL::Web::Configuration helps to accommodate multiple domain based DbFrontend interfaces in one navigation tree

use base qw(EnsEMBL::Web::Configuration);

sub get_valid_action {
  my ($self, $action, $function) = @_;
  my $valid_action;

  if ($valid_action = $self->tree->get_node(join '/', grep {$_} $self->hub->type, $action, $action ? $function : ())) {
    $valid_action = $valid_action->id;
  }
  return $valid_action;
}

sub create_multidbfrontend_menu {
  ## Creates a multi-domain dbfrontend sub-menu
  ## @param Menu name
  ## @param Menu title - defaults to menu name
  ## @param Hashref that is extended with the node options for each node
  ## @param Hash in ArrayRef syntax for all the nodes to be added - adds all the default dbfrontend nodes if not provided
  ##  - Structure of the hash needs to be similar to the one returned in EnsEMBL::Web::Configuration->dbfrontend_nodes
  ##  - Any node if has same name as in EnsEMBL::Web::Configuration->dbfrontend_nodes will extend or override the default settings for the nodes
  ## @return menu node object
  my ($self, $menu_name, $menu_title, $options, $nodes) = @_;
  
  my $hub  = $self->hub;
  my $menu = $self->create_submenu($menu_name, $menu_title || $menu_name);
  my $dbf  = $self->dbfrontend_nodes;

  if ($nodes && ref $nodes eq 'ARRAY') {
    $dbf   = {@$dbf};
  }
  else {
    $nodes = $dbf;
    $dbf   = {};
  }

  while (my $node_name = shift @$nodes) {
    my $node_options = {%{$dbf->{$node_name} || {}}, %{$options || {}}, %{shift @$nodes}, 'raw' => 1, 'url' => $hub->url({'type' => $menu_name, 'action' => $node_name, 'function' => ''})};
    $menu->append($self->create_node("$menu_name/$node_name", delete $node_options->{'caption'}, delete $node_options->{'components'} || [], $node_options));
  }
  return $menu;
}

1;