package EnsEMBL::Users::Command::Account::User::Authenticate;

### Command module to authenticate the user after verifying the password with the one on records
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(
  MESSAGE_ACCOUNT_BLOCKED
  MESSAGE_EMAIL_NOT_FOUND
  MESSAGE_PASSWORD_WRONG
  MESSAGE_VERIFICATION_PENDING
);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $email   = $hub->param('email') || '';
  my $login   = $object->fetch_login_account($email);

  return $self->redirect_login(MESSAGE_EMAIL_NOT_FOUND, {'email' => $email})  unless $login;
  return $self->redirect_login(MESSAGE_VERIFICATION_PENDING)                  unless $login->status eq 'active';
  return $self->redirect_login(MESSAGE_ACCOUNT_BLOCKED)                       unless $login->user->status eq 'active';
  return $self->redirect_login(MESSAGE_PASSWORD_WRONG, {'email' => $email})   unless $login->verify_password($hub->param('password') || '');

  return $self->redirect_after_login($login->user);
}

1;