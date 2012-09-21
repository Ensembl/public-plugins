package EnsEMBL::Users::Command::Account;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Users::Mailer::User;
use EnsEMBL::Users::Messages qw(MESSAGE_ACCOUNT_BLOCKED MESSAGE_VERIFICATION_SENT MESSAGE_UNKNOWN_ERROR);

use base qw(EnsEMBL::Web::Command);

use constant EMAIL_REGEX => qr/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/;

sub handle_registration {
  ## Handles a new login according to the email provided during registration
  ## @param Login object
  ## @param Email to be registered (should be validated before calling this method)
  ## @param Hashref with keys:
  ##  - add_new           (for openid registration only) Flag if on will create a new user if email does not exist in user table
  ##  - skip_verify_email (for openid registration only) Flag if on, will not send a verification email to the existing account if accounts being linked
  my ($self, $login, $email, $flags) = @_;

  my $login_type  = $login->type;
  my $object      = $self->object;
  my $user        = $object->fetch_user_by_email($email);

  if ($user) {
    return $self->redirect_message(MESSAGE_ACCOUNT_BLOCKED) if $user->status eq 'suspended'; # If blocked user

  } elsif ($login_type eq 'openid' && !$flags->{'add_new'}) { # redirect to the page to register with openid if not explicitly told to create a new user
    $login->reset_salt_and_save;
    return $self->redirect_openid_register($login);

  } else {
    warn "Creating new user";
    $user = $object->new_user_account({'email' => $email});
  }

  # skip verification if flag kept on, or if openid provider is trusted and user uses same email in user account as provided by openid provider
  if ($login_type eq 'openid' && ($flags->{'skip_verify_email'} || $login->has_trusted_provider && $user->email eq $login->email)) {
    warn sprintf("\nSkipping verification for (%s, %s)", $login->provider, $login->email);
    $login->activate($user);
    $user->save;
    return $self->redirect_after_login($user);
  }

  # Link login object to user object
  $login->reset_salt;
  $user->add_logins([$login]);
  $user->save;

  warn sprintf("\nSending verification for (%s, %s)", $login->type eq 'openid' ? $login->provider : $login->type, $login->email);

  # Send verification email
  $self->get_mailer->send_verification_email($login);
  return $self->redirect_message(MESSAGE_VERIFICATION_SENT, {'email' => $user->email});
}

sub redirect_after_login {
  ## Does an appropriate redirect after setting user cookie
  ## User if logged in through AJAX, the page is refreshed instead of dynamically changing the page contents (there are many things that can be different if you are logged in)
  ## @param Rose user object
  ## @note Only call this method once login verification is done
  my ($self, $user) = @_;
  my $hub           = $self->hub;
  my $object        = $self->object;

  # return to login page if cookie not set
  return $self->redirect_login(MESSAGE_UNKNOWN_ERROR) unless $hub->user->authorise({'user' => $user});

  # redirect
  if ($hub->is_ajax_request) {
    return $self->ajax_redirect($hub->url({'type' => 'Account', 'action' => 'Success'})); # this just closes the popup and refreshes the page
  } else {
    my $site = $hub->species_defs->ENSEMBL_SITE_URL;
    my $then = $hub->param('then') || '';
    return $hub->redirect($self->url($then =~ /^(\/|$site)/ ? $then : $site)); #only redirect to an internal url or a relative url
  }
}

sub redirect_message {
  ## Redirects to page that displays required message to user
  ## @param Message/Error constant
  ## @param Hashref of extra params that need to go as GET params
  ##  - error: if this key is provided, it will change the message as error instead of setting 'error' as a GET parameter
  my ($self, $message, $params) = @_;
  $params ||= {};
  my $param = delete $params->{'error'} ? 'err' : 'msg';
  return $self->ajax_redirect($self->hub->url({%$params, 'action' => 'Message', $param => $message}));
}

sub redirect_login {
  ## Redirects to login page with an optionally displayed message
  ## @param Error constant in case of any error
  ## @param Hashref of extra GET params
  my ($self, $error, $params) = @_;
  return $self->ajax_redirect($self->hub->url({%{$params || {}}, 'action' => 'Login', $error ? ('err' => $error) : ()}));
}

sub redirect_register {
  ## Redirects to registration page with an optionally displayed message
  ## @param Error constant in case of any error
  ## @param Hashref of extra GET params
  my ($self, $error, $params) = @_;
  return $self->ajax_redirect($self->hub->url({%{$params || {}}, 'action' => 'Register', $error ? ('err' => $error) : ()}));
}

sub redirect_openid_register {
  ## Redirects to a page where user can verify (or input) an email address to register with OpenID
  ## @param Login object
  ## @param Error constant if any
  my ($self, $login, $error) = @_;
  my $hub   = $self->hub;
  my $then  = $hub->param('then');

  return $self->ajax_redirect($self->hub->url({
    'type'      => 'Account',
    'action'    => 'OpenID',
    'function'  => 'Register',
    'code'      => $login->get_url_code,
    $error ? (
    'err'       => $error
    ) : (),
    $then ? (
    'then'      => $then
    ) : ()
  }));
}

sub validate_fields {
  ## Validates the values provided by the user in registration like forms
  ## @param Hashref with name of the field and provided value as key-value pairs (keys: name, email, password, confirm_password)
  ## @return Hashref with validated values, or with a key 'invalid' if any invalid value found
  my ($self, $params) = @_;

  # name
  if (exists $params->{'name'}) {
    $params->{'name'} or return {'invalid' => 'name'};
  }

  # email
  if (exists $params->{'email'}) {
    my $regex = $self->EMAIL_REGEX;
    $params->{'email'} = lc $params->{'email'};
    return {'invalid' => 'email'} unless $params->{'email'} =~ /$regex/;
  }

  # password
  if (exists $params->{'password'}) {
    length ($params->{'password'} || '') < 6 and return {'invalid' => 'password'};
    
    # confirm password
    if (exists $params->{'confirm_password'}) {
      $params->{'password'} eq $params->{'confirm_password'} or return {'invalid' => 'confirm_password'};
    }
  }
  return $params;
}

sub get_mailer {
  ## Gets the mailer object for sending emails
  ## @return EnsEMBL::Users::Mailer::User object
  return EnsEMBL::Users::Mailer::User->new(shift->hub);
}

sub send_group_joining_notification_email {
  ## Sends a notification email to all the admins (the ones who opted to revieve these emails) of the group about the new joinee
  ## @param User who joined the group
  ## @param Group object
  ## @param Flag kept on or off if user joined the group or sent the request respectively
  my ($self, $user, $group, $has_joined) = @_;

  if ( my @curious_admins = map {$_->notify_join && $_->user || ()} @{$group->admin_memberships} ) {
    my $mailer = $self->get_mailer;
    $mailer->send_group_joining_notification_email($user, $_, $group, $has_joined) for @curious_admins;
  }
}

sub send_group_editing_notification_email {
  ## Sends a notification email to all the admins (the ones who opted to revieve these emails) about the group's info being edited
  ## @param Admin user who edited the group
  ## @param Group object
  ## @param Original values in group (Hashref)
  ## @param Modified values in group (Hashref)
  my ($self, $user, $group, $original_values, $modified_values) = @_;

  if ( my @curious_admins = map {$_->user_id ne $user->user_id && $_->notify_edit && $_->user || ()} @{$group->admin_memberships} ) {
    my $titles  = {
      'name'      => 'Group name',
      'blurb'     => 'Description',
      'type'      => 'Type',
      'status'    => 'Status'
    };
    if ( my @changes = map { $original_values->{$_} eq $modified_values->{$_}
      ? ()
      : sprintf(q( - %s changed from '%s' to '%s'), $titles->{$_}, $original_values->{$_} || '', $modified_values->{$_} || '')
    } keys %$original_values ) {
      my $mailer = $self->get_mailer;
      $mailer->send_group_editing_notification_email($user, $_, $group, join "\n", @changes) for @curious_admins;
    }
  }
}

sub send_group_sharing_notification_email {
  ## TODO
}

sub get_curious_admins {
  ## Gets all the admins of a group that opted to get notified on some event
  ## TODO
}

sub internal_referer {
  ## Gets the internal referer without error or message code
  ## @return url string
  my $hub     = shift->hub;
  my $referer = $hub->referer;
  (my $url    = $referer->{'absolute_url'}) =~ s/[\?,\;]{1}(err|msg)\=[^\;]*//;

  return $referer->{'external'} ? $hub->url({'action' => 'Preferences'}) : $url;
}

1;
