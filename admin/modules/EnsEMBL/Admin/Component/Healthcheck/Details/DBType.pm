package EnsEMBL::Admin::Component::Healthcheck::Details::DBType;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck::Details);

sub caption {
  my $self = shift;
  my $param = $self->_param eq '' ? '' : ' (' . $self->_param . ')';
  return "Database healthcheck details$param";
}

sub _param_name {
  return 'db';
}

sub _param {
  my $self = shift;
  return $self->hub->param('db') || '';
}

sub _type {
  return 'database_type';
}

sub _get_first_column_for_report {
  return 'Species<br />Testcase';
}

sub _get_default_list {
  return [qw(cdna core funcgen otherfeatures production variation vega)];
}

1;
