package EnsEMBL::Admin::Component::Healthcheck::Details::Species;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck::Details);

sub caption {
  my $self = shift;
  my $param = $self->_param eq '' ? '' : ' (' . $self->_param . ')';
  return "Healthcheck details$param";
}

sub _param_name {
  return '';
}

sub _param {
  my $self = shift;
  return $self->hub->species eq 'common' ? '' : $self->hub->species;
}

sub _type {
  return 'species';
}

sub _get_first_column_for_report {
  return 'Database Type<br />Testcase';
}

1;