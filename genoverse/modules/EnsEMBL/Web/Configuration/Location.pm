package EnsEMBL::Web::Configuration::Location;

use EnsEMBL::Web::Tools::MethodMaker(copy => [ 'modify_tree', '_modify_tree' ]);

use strict;

sub modify_tree {
  my $self = shift;
  my $view = $self->get_node('View');
  
  $view->set('genoverse', 1);
  
  $self->_modify_tree unless $self->can('modify_tree') eq $self->can('_modify_tree');
}

sub get_configurable_components {
  my $self       = shift;
  my $node       = shift;
  my $components = $self->SUPER::get_configurable_components($node, @_);
  
  push @{$components->[0]}, 'genoverse' if $node && $node->get('genoverse');
  
  return $components;
}

1;
