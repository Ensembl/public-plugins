package EnsEMBL::Admin::Component::Production::LogicName;

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend::List);

sub caption {
  return '';
}

sub record_tree {
  my $record_div = shift->SUPER::record_tree(@_);

  $_->inner_HTML($_->inner_HTML ? 'Yes' : 'No')  for @{$record_div->get_nodes_by_flag('displayable')};
  !$_->inner_HTML and $_->inner_HTML('<i>null</i>') for @{$record_div->get_elements_by_tag_name('td')};

  return $record_div;
}

1;