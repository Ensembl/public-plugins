package EnsEMBL::Admin::Component::Production;

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub get_printable {
  my ($self, $value, $default) = @_;
  return $value ? UNIVERSAL::can($value, 'get_title') ? $value->get_title : $default || (ref $value eq 'ARRAY' ? join ', ', @$value : $value) : $default || '<i>null</i>';
}

1;