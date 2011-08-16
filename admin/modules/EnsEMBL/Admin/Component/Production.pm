package EnsEMBL::Admin::Component::Production;

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub get_printable {
  my ($self, $value) = @_;
  return $value ? UNIVERSAL::can($value, 'get_title') ? $value->get_title : $value : '<i>null</i>';
}

1;