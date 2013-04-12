package EnsEMBL::Web::Configuration::UserData;

use strict;

sub _create_node {
  my ($self, $species, $type) = splice @_, 0, 3;

  $_[3] = { %{$_[3] || {}}, 'availability' => 0} if $type ne 'Account';

  return $self->SUPER::create_node(@_);
}

1;
