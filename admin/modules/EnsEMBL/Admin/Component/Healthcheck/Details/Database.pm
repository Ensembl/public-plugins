package EnsEMBL::Admin::Component::Healthcheck::Details::Database;

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
  return 'database_name';
}

sub _get_first_column_for_report {
  return 'DB Type<br />Species<br />Testcase';
}

sub _get_default_list {
  return [];
}

sub _show_anchors {
  return 0;
}


1;
