package EnsEMBL::Admin::Component::Healthcheck::Details::Testcase;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck::Details);

sub caption {
  my $self = shift;
  my $param = $self->_param eq '' ? '' : ' (' . $self->_param . ')';
  return "Healthcheck details$param";
}

sub _param_name {
  return 'test';
}

sub _param {
  my $self = shift;
  return $self->hub->param('test') || '';
}

sub _type {
  return 'testcase';
}

sub _get_first_column_for_report {
  return 'Database Type<br />Species';
}

1;
