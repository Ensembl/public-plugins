package EnsEMBL::Users::Command::Account::Authenticate;

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $login   = $object->get_login_account($hub->param('email'));

  return $self->redirect_after_login($login->user) if $login && $login->verify_password($hub->param('password'));

  return $self->redirect_login($object->MESSAGE_AUTHENTICATION_FAILED);
}

1;