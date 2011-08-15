package EnsEMBL::Admin::Component::Production::LogicName;

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend::List);

sub caption {
  return '';
}

sub content_tree {
  ## @overrides
  my $self    = shift;

  my $tree = $self->SUPER::content_tree;

  $_->inner_HTML('No analysis web data found in the database for the applied filter.') for @{$tree->get_nodes_by_flag($self->_FLAG_NO_CONTENT)};

  return $tree;
}

sub record_tree {
  ## @overrides
  my $record_div = shift->SUPER::record_tree(@_);

  $_->inner_HTML($_->inner_HTML ? 'Yes' : 'No')  for @{$record_div->get_nodes_by_flag('displayable')};
  !$_->inner_HTML and $_->inner_HTML('<i>null</i>') for @{$record_div->get_elements_by_tag_name('td')};

  return $record_div;
}

1;