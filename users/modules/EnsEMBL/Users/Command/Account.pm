package EnsEMBL::Users::Command::Account;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::DataType::EmailAddress;
use EnsEMBL::Users::Mailer::User;

use base qw(EnsEMBL::Web::Command);

use constant {
  OPENID_EXTENSION_URL_AX    => 'http://openid.net/srv/ax/1.0',
  OPENID_EXTENSION_URL_SREG  => 'http://openid.net/extensions/sreg/1.1',
};

sub handle_openid_login {
  ## Handles a login/registration via openid
  ## @param Hashref with keys
  ##  - openid  Verified openid url
  ##  - email   User email provided by the openid provider
  ##  - name    Name provided by the openid provider
  my ($self, $params) = @_;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $openid  = delete $params->{'openid'} or throw exception('UserException', 'OpenID url missing while login');
  my $email   = $self->get_validated_email(delete $params->{'email'});
  my $name    = delete $params->{'name'};
  my $login   = $object->get_login_account($openid);

  # if login account exists - not a first time login
  if ($login) {

    my $linked_user = $login->user;

    unless ($linked_user) { # this means user tried to register previously, but left the process incomplete

      # reset the salt for security reasons
      $login->reset_salt;
      $login->save;

      return $self->redirect_link_existing_account($login);
    }

    return $self->redirect_message('AccountBlocked') if $linked_user->status eq 'suspended'; # If blocked user

    if ($login->status eq 'active') {

      return $self->redirect_after_login($linked_user); # For successful login

    } else { # user has not activated his account yet

      if ($email && $linked_user->email eq $email) {

        # Although this is not first time login, we still can't allow login until email address is verified
        $self->get_mailer->send_verification_email($login, $linked_user);
        return $self->redirect_message('VerificationSent', {'email' => $email});
      }

      # if email was not verified and now the new email provided by openid is not same as in linked user account, change the details and do new registration with new user account
      $login->name($name);
      $login->email($email);
    }

  # for a first time login
  } else {

    # We need an email to register
    return $self->redirect_login('OpenIDEmailMissing') unless $email;

    $login = $object->new_login_account({
      'type'      => 'openid',
      'identity'  => $openid,
      'status'    => 'pending',
      'provider'  => $hub->function,
      'email'     => $email,
      'name'      => $name,
    });
  }

  return $self->handle_registration($login, $email);
}

sub handle_local_login {
  ## Handles login using the local login account
  ## TODO
}

sub handle_adduser {
  ## Handles a request of local user registration
  ## @param Hashref with keys name (required), email (required), organisation (optional) and  country (optional)
  my ($self, $params) = @_;

  my $object  = $self->object;
  my $email   = $self->get_validated_email(delete $params->{'email'});

  return $self->redirect_register('EmailMissing') unless $email;
  return $self->redirect_register('NameMissing')  unless $params->{'name'};

  my $login   = $object->get_login_account($email);
  return $self->redirect_login('Registered') if $login && $login->status eq 'active';

  $login    ||= $object->new_login_account({
    'type'      => 'local',
    'identity'  => $email,
    'status'    => 'pending',
    map {$_     => $params->{$_}} qw(name organisation country)
  });

  return $self->handle_registration($login, $email, 1);
}

sub handle_registration {
  ## Handles a new login according to the email provided during registration
  ## @param Login object
  ## @param User email address (should be validated before calling this method)
  ## @param Flag if on will create a new user if email does not exist in user table
  my ($self, $login, $email, $do_create_new) = @_;

  my $object  = $self->object;
  my $user    = $object->get_user_by_email($email);

  if ($user) {
    return $self->redirect_message('AccountBlocked') if $user->status eq 'suspended'; # If blocked user
    return $self->redirect_after_registration($login, $user); # Register new login account with the existing user
  }

  if ($do_create_new) {
    warn "Creating new user";
    return $self->redirect_after_registration($login, $object->new_user_account({'email' => $email})); # Register new login account with a new user
  }

  $login->reset_salt;
  $login->save;

  return $self->redirect_link_existing_account($login);
}

sub redirect_after_registration {
  ## Adds and saves a new login account to user account before redirecting the page
  ## @param Rose Login object
  ## @param Rose User object
  my ($self, $login, $user) = @_;
  my $object = $self->object;

  # Link accounts
  $login->reset_salt;
  ($login) = $user->add_login([$login]);

  # check if openid provider is trusted and user uses same email in user account as provided by openid provider
  my $skip_verification = {@{$object->openid_providers}}->{$login->provider}->{'trusted'} && $user->email eq $login->email;
  warn sprintf("\nSkipping verification = %s (%s, %s)\nAdding login to user account", $skip_verification || '0', $login->provider, $login->email);

  $login->activate if $skip_verification;

  $user->save;

  return $self->redirect_after_login($user) if $skip_verification;

  warn "\nSending verification email";

  # otherwise, we do the verification ourselves.
  $self->get_mailer->send_verification_email($login);
  return $self->redirect_message('VerificationSent', {'email' => $user->email});
}

sub redirect_after_login {
  ## Does an appropriate redirect after setting user cookie
  ## User if logged in through AJAX, the page is refreshed instead of dynamically changing the page contents (there are many things that can be different if you are logged in)
  my ($self, $user) = @_;
  my $hub = $self->hub;

  # temp
  return $self->redirect_message('LoginSuccesful');

  # set cookie
  $hub->initialise_user({'user' => $user}, $self->object->user_cookie);

  # redirect
  if ($hub->is_ajax_request) {
    return $self->ajax_redirect($hub->url({'type' => 'Account', 'action' => 'Success'})); # this just closes the popup and refreshes the page
  } else {
    my $site = $hub->species_defs->ENSEMBL_SITE_URL;
    my $then = $hub->param('then') || '';
    return $hub->redirect($self->url($then =~ /^$site/ ? $then : $site)); #only redirect to an internal url
  }
}

sub redirect_message {
  ## Redirects to page that displays required message to user
  ## @param Function part if the URL that corresponds to the message
  ## @param Hashref of extra params that need to go as GET params in URL
  my ($self, $message, $params) = @_;
  return $self->ajax_redirect($self->hub->url({%{$params || {}}, 'action' => 'Message', 'function' => $message}));
}

sub redirect_login {
  ## Redirects to login page with an optionally displayed message
  ## @param Function param that corresponds to message
  my ($self, $message) = @_;
  return $self->ajax_redirect($self->hub->url({'action' => 'Login', 'function' => $message}));
}

sub redirect_register {
  ## Redirects to registration page with an optionally displayed message
  ## @param Function param that corresponds to message
  my ($self, $message) = @_;
  return $self->ajax_redirect($self->hub->url({'action' => 'Register', 'function' => $message}));
}

sub redirect_link_existing_account {
  ## Redirects to a page where user can input an email address to link existing user account with the given login account
  ## @param Login account
  ## @param Hashref of name-value pairs for GET params
  my ($self, $login, $params) = @_;

  return $self->ajax_redirect($self->hub->url({'type' => 'Account', 'action' => 'SelectAccount', 'code' => $self->object->get_url_code_for_login($login), %{$params || {}}}));
}

sub get_validated_email {
  ## Returns the email provided after validating it
  ## @param Email address (default to email param)
  ## @return Email address if valid, undef otherwise
  my ($self, $email) = @_;
  return EnsEMBL::Web::DataType::EmailAddress->new($email || $self->hub->param('email'))->to_string || undef;
}

sub get_mailer {
  ## Gets the mailer object for sending emails
  ## @return EnsEMBL::Users::Mailer::User object
  return EnsEMBL::Users::Mailer::User->new(shift->hub);
}

sub render_message {
  return "<p>$_[1]</p>";
}

1;