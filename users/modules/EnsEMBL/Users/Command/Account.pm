=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Users::Command::Account;

## Base class for all the command modules
## This also contains support for openid login

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Users::Mailer::User;
use EnsEMBL::Users::Messages qw(MESSAGE_VERIFICATION_SENT MESSAGE_URL_EXPIRED MESSAGE_UNKNOWN_ERROR);

use parent qw(EnsEMBL::Web::Command);

use constant EMAIL_REGEX => qr/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/;
use constant LATIN_CHARS_REGEX => qr/\A[\p{Latin}\s\-']+\z/;

sub csrf_safe_process { } # stub for child classes - override this method instead of 'process' for CSRF safe processes

sub process {
  ## Wrapper around the child command module's csrf_safe_process method
  my $self    = shift;
  my $hub     = $self->hub;
  my $user    = $hub->user;
  my $r_user  = $user->rose_object;
  my $code_1  = $r_user ? $r_user->salt : $user->default_salt;
  my $code_2  = $hub->param($hub->CSRF_SAFE_PARAM) || '';

  if ($code_1 && $code_2 && $code_1 eq $code_2) {
    $r_user->reset_salt_and_save('changes_only' => 1) if $r_user;
    return $self->csrf_safe_process(@_);
  }

  return $self->redirect_message(MESSAGE_URL_EXPIRED);
}

sub redirect_after_login {
  ## Does an appropriate redirect after setting user cookie
  ## User if logged in through AJAX, the page is refreshed instead of dynamically changing the page contents (there are many things that can be different if you are logged in)
  ## @param Rose user object (optional)
  ## @note Only call this method once login verification is done
  my ($self, $user) = @_;
  my $hub = $self->hub;
  
  ## Set cookie (skip if no user object, e.g. if user has just disabled account)
  if ($user) {
    # return to login page if cookie cannot be set
    return $self->redirect_login(MESSAGE_UNKNOWN_ERROR) unless $hub->user->authorise({'user' => $user, 'set_cookie' => 1});
  }

  my $site = $hub->species_defs->ENSEMBL_SITE_URL;
  my $then = $hub->param('then') || '';
  my $url  = $then =~ /^(\/|$site)/ ? $then : $site; # only redirect to an internal url or a relative url

  # redirect
  if ($hub->controller->is_ajax_request) {
    my $referer = $hub->referer;
    if ($url eq $then && $url ne $referer->{'absolute_url'}) {
      $self->ajax_redirect($url, undef, undef, undef, $hub->param('modal_tab'));
    } else {
      return $self->ajax_redirect($referer->{'external'} ? $site : $referer->{'absolute_url'}, undef, undef, 'page');
    }
  } else {
    return $hub->redirect($self->url($url));
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
  return $self->ajax_redirect($self->hub->url({%$params, 'action' => 'Message', $param => $message}),
                                undef, undef, undef, $self->hub->param('modal_tab'));
}

sub redirect_login {
  ## Redirects to login page with an optionally displayed message
  ## @param Error constant in case of any error
  ## @param Hashref of extra GET params
  my ($self, $error, $params) = @_;
  return $self->ajax_redirect($self->hub->url({%{$params || {}}, 'action' => 'Login', $error ? ('err' => $error) : ()}),
                              undef, undef, undef, $self->hub->param('modal_tab'));
}

sub redirect_register {
  ## Redirects to registration page with an optionally displayed message
  ## @param Error constant in case of any error
  ## @param Hashref of extra GET params
  my ($self, $error, $params) = @_;
  
  return $self->ajax_redirect($self->hub->url({%{$params || {}}, 'action' => 'Register', $error ? ('err' => $error) : ()}),
                              undef, undef, undef, $self->hub->param('modal_tab'));
}

sub redirect_consent {
  ## Redirects to consent page
  ## @param Login object
  my ($self, $login) = @_;
  my $hub = $self->hub;
  my %params = ('email' => $hub->param('email'));;
  if ($login->consent_version) {
    if ($login->consent_version ne $hub->species_defs->GDPR_ACCOUNTS_VERSION) {
      $params{'old_version'} = $login->consent_version;
    }
  }
  return $self->ajax_redirect($hub->url({'action' => 'Consent', %params}));
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

sub consent_check_failed {
  ## Checks if the user has previously consented to the current GDPR policy version
  my ($self, $login) = @_;
  my $hub = $self->hub;
  ## Shouldn't reach this point if version is 0, but avoids 'uninitialized' warnings
  my $current_version = $hub->species_defs->GDPR_VERSION || 0;

  if ($login->consent_version && $login->consent_version eq $current_version) {
    return 0;
  }
  else {
    return 1;
  }
}


sub validate_fields {
  ## Validates the values provided by the user in registration like forms
  ## @param Hashref with name of the field and provided value as key-value pairs (keys: name, email, password, confirm_password)
  ## @return Hashref with validated values, or with a key 'invalid' if any invalid value found
  my ($self, $params) = @_;
  my $latin_chars = $self->LATIN_CHARS_REGEX;

  # name
  if (exists $params->{'name'}) {
    $params->{'name'} or return {'invalid' => 'name'};
    $params->{'name'} =~ /$latin_chars/ or return {'invalid' => 'non_latin'};
  }

  # email
  if (exists $params->{'email'}) {
    my $regex = $self->EMAIL_REGEX;
    $params->{'email'} = lc $params->{'email'};
    return {'invalid' => 'email'} unless $params->{'email'} =~ /$regex/;
  }

  # organization (optional)
  if (exists $params->{'organization'} && length $params->{'organization'}) {
    $params->{'organization'} =~ /$latin_chars/ or return {'invalid' => 'non_latin'};
  }

  # country (optional)
  if (exists $params->{'country'} && length $params->{'country'}) {
    $params->{'country'} =~ /$latin_chars/ or return {'invalid' => 'non_latin'};
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

sub mailer {
  ## Gets the mailer object for sending emails
  ## @return EnsEMBL::Users::Mailer::User object
  return EnsEMBL::Users::Mailer::User->new(shift->hub);
}

sub send_group_joining_notification_email {
  ## Sends a notification email to all the admins (the ones who opted to revieve these emails) of the group about the new joinee
  ## @param Group object
  ## @param Flag kept on or off if user joined the group or sent the request respectively
  my ($self, $group, $has_joined) = @_;

  if ( my @curious_admins = map {$_->notify_join ? $_->user : ()} @{$group->admin_memberships} ) {
    $self->mailer->send_group_joining_notification_email(\@curious_admins, $group, $has_joined);
  }
}

sub send_group_editing_notification_email {
  ## Sends a notification email to all the admins (the ones who opted to revieve these emails) about the group's info being edited
  ## @param Group object
  ## @param Original values in group (Hashref)
  ## @param Modified values in group (Hashref)
  my ($self, $group, $original_values, $modified_values) = @_;

  my $user_id = $self->hub->user->user_id;

  if ( my @curious_admins = map {$_->user_id ne $user_id && $_->notify_edit ? $_->user : ()} @{$group->admin_memberships} ) {
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
      $self->mailer->send_group_editing_notification_email(\@curious_admins, $group, join "\n", @changes);
    }
  }
}

sub send_group_sharing_notification_email {
  ## Sends a notification email to all the members (the ones who opted to revieve these emails) about the records being shared to the group
  ## @param Group object
  ## @param Records being shared (Hashref)
  my ($self, $group, $records) = @_;

  my $user_id = $self->hub->user->user_id;

  if ( my @curious_members = map {$_->user_id ne $user_id && $_->notify_share ? $_->user : ()} @{$group->memberships} ) {

    my %types;
    ($types{$_->type} ||= 0)++ for @$records;
    my @shared = map {sprintf '%d %s', $types{$_}, ucfirst $_} keys %types;

    $self->mailer->send_group_sharing_notification_email(\@curious_members, $group, join "\n", @shared);
  }
}

sub handle_mailinglist_subscriptions {
  ## Handles the user's request to join selected mailing lists
  ## @param Login object for the newly registered user
  my ($self, $login)  = @_;
  my %subscriptions   = @{$self->hub->species_defs->SUBSCRIPTION_EMAIL_LISTS};
  my @request_emails  = grep $subscriptions{$_}, @{$login->subscription || []};

  $self->mailer->send_mailinglists_subscription_emails($login, @request_emails) if @request_emails;
}

1;
