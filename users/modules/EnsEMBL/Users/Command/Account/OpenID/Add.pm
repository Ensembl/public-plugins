package EnsEMBL::Users::Command::Account::OpenID::Add;

### Command module to register a new openid account, or link an existing account (with provided email) to a new openid login
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(
  MESSAGE_EMAIL_INVALID
  MESSAGE_NAME_MISSING
  MESSAGE_NO_EXISTING_ACCOUNT
  MESSAGE_PASSWORD_WRONG
  MESSAGE_URL_EXPIRED
);

use base qw(EnsEMBL::Users::Command::Account::OpenID);

sub process {
  my $self              = shift;
  my $object            = $self->object;
  my $hub               = $self->hub;
  my $login             = $object->fetch_login_from_url_code(1) or return $self->redirect_message(MESSAGE_URL_EXPIRED, {'error' => 1});
  my $login_code        = $login->get_url_code;
  my $provider          = $login->provider;
  my $trusted_provider  = $login->has_trusted_provider;
  my $function          = $hub->function;
  my $email             = $self->validate_fields({'email' => $hub->param('email') || ''})->{'email'} || '';
  my $skip_verify_email = 0;

  if ($function eq 'Link') {

    return $self->redirect('LinkExisting', {'code' => $login_code}, MESSAGE_EMAIL_INVALID) unless $email;

    my $existing_user = $object->fetch_user_by_email($email);

    # if user not found for the given email, redirect back with an error message
    if (!$existing_user) {
      return $self->redirect('LinkExisting', {'code' => $login_code}, MESSAGE_NO_EXISTING_ACCOUNT);

    # if provider is not trusted, or the email being linked is not same as the one provider returned, we need to authenticate the existing account before linking it with the openid provided
    } elsif (!$trusted_provider || $login->email ne $existing_user->email) {
      my $authentication_method = $hub->param('authentication');

      if (!$authentication_method) {
        return $self->redirect('Authenticate', {'email' => $email, 'code' => $login_code});

      } elsif ($authentication_method eq 'password') {
        my $existing_local_login = $existing_user->get_local_login;
        return $self->redirect('Authenticate', {'code' => $login_code, 'email' => $email}                         ) unless $existing_local_login;
        return $self->redirect('Authenticate', {'code' => $login_code, 'email' => $email}, MESSAGE_PASSWORD_WRONG ) unless $existing_local_login->verify_password($hub->param('password') || '');
        $skip_verify_email = 1;

      } # else for email authentication, continue to registration
    }

    # else if provider is trusted and emails returned by openid provider is same as one on existing account, continue to registration

  } elsif ($function eq 'Add') {

    my $name = $self->validate_fields({'name' => $hub->param('name') || ''})->{'name'} || '';

    if ($email && $name) {
      # add extra information to the login object submitted by the user before continuing to registration
      $login->name($name);
      $hub->param($_) and $login->$_($hub->param($_)) for qw(organisation country);

    } else {
      return $self->redirect_openid_register($login, $email ? MESSAGE_NAME_MISSING : MESSAGE_EMAIL_INVALID);
    }
  }

  return $self->handle_registration($login, $email, { 'add_new' => 1, 'skip_verify_email' => $skip_verify_email });
}

sub redirect {
  my ($self, $function, $url_params, $error) = @_;
  return $self->hub->redirect({'action' => 'OpenID', 'function' => $function, $error ? ('err' => $error) : (), %$url_params});
}

1;
