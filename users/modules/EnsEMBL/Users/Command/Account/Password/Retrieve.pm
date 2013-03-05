package EnsEMBL::Users::Command::Account::Password::Retrieve;

### Command module that sends an email to the user email address to be able to reset his password
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_EMAIL_INVALID MESSAGE_EMAIL_NOT_FOUND MESSAGE_PASSWORD_EMAIL_SENT);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $email   = $hub->param('email') || '';

  # validation
  my $fields  = $self->validate_fields({'email' => $email});
  return $self->ajax_redirect($hub->url({'action' => 'Password', 'function' => 'Lost', 'email' => $email, 'err' => MESSAGE_EMAIL_INVALID})) if $fields->{'invalid'};

  # get the existing account
  $email      = $fields->{'email'};
  my $login   = $object->fetch_login_account($email);
  return $self->ajax_redirect($hub->url({'action' => 'Password', 'function' => 'Lost', 'email' => $email, 'err' => MESSAGE_EMAIL_NOT_FOUND})) unless $login;

  # if account exists, but registration is incomplete
  return $self->handle_registration($login, $email) unless $login->status eq 'active';

  # account found, reset the salt, save the login object and send an email
  $login->reset_salt_and_save;

  $self->mailer->send_password_retrieval_email($login);

  return $self->redirect_message(MESSAGE_PASSWORD_EMAIL_SENT, {'email' => $email});
}

1;
