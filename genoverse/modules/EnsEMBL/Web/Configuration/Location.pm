package EnsEMBL::Web::Configuration::Location;

use strict;

use previous qw(modify_tree);

sub modify_tree {
  my $self = shift;
  my $view = $self->get_node('View');
  
  $view->set('genoverse', 1);

  $self->PREV::modify_tree;
}

sub get_configurable_components {
  my $self       = shift;
  my $node       = shift;
  my $components = $self->SUPER::get_configurable_components($node, @_);
  
  push @{$components->[0]}, 'genoverse' if $node && $node->get('genoverse');
  
  return $components;
}

1;
