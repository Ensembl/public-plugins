package EnsEMBL::Web::Object::Healthcheck;

use strict;

use EnsEMBL::Admin::Data::Rose::Report;
use EnsEMBL::Admin::Data::Rose::Session;
use EnsEMBL::ORM::Data::Rose::User;

use base qw(EnsEMBL::Web::Object);

sub new {
  my $class = shift;
  return bless { 'hub'  => @_ }, $class;
}

sub caption { return "Healthcheck"; }
sub short_caption { return "Healthcheck"; }

sub data_interface {
  my ($self, $type) = @_;

  my $module = sprintf 'EnsEMBL::%s::Data::Rose::%s', $type eq 'User' ? 'ORM' : 'Admin', $type;
  return $self->{$type} ||= $module->new($self->{'hub'});
}

1;