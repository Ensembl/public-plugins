package EnsEMBL::Web::Object::Account;

### NAME: EnsEMBL::Web::Object::Account
### Object for accessing user account information 

### DESCRIPTION
### This module does not wrap around a data object, it merely
### accesses the user object via the session

use strict;

use EnsEMBL::ORM::Rose::Manager::User;
use EnsEMBL::ORM::Rose::Manager::Login;
use EnsEMBL::ORM::Rose::Manager::Group;
use EnsEMBL::ORM::Rose::Manager::Membership;

use base qw(EnsEMBL::Web::Object);

sub _messages {## TODO change message texts
  MESSAGE_OPENID_CANCELLED      => 135 => sub { sprintf q(Your request to login via %s was cancelled. Please try again, or use one of the alternative login options below.), shift->hub->param('provider') || 'OpenID' },
  MESSAGE_OPENID_INVALID        => 153 => '_message__OPENID_INVALID',
  MESSAGE_OPENID_SETUP_NEEDED   => 167 => '_message__OPENID_SETUP_NEEDED',
  MESSAGE_OPENID_ERROR          => 278 => '_message__OPENID_ERROR',
  MESSAGE_OPENID_EMAIL_MISSING  => 233 => '_message__OPENID_EMAIL_MISSING',
  MESSAGE_EMAIL_NOT_FOUND       => 256 => 'The email address provided is not recognised. Please try again.',
  MESSAGE_PASSWORD_WRONG        => 297 => 'The password provided is invalid. Please try again.',
  MESSAGE_ALREADY_REGISTERED    => 345 => sub { sprintf q(The email address provided seems to be already registered. Please try to login with the email, or request to <a href="%s">retrieve your password</a> if you have lost one.), $_[0]->hub->url({'action' => 'Password', 'function' => 'Lost', 'email' => $_[0]->hub->param('email')}) },
  MESSAGE_CONFIRMATION_FAILED   => 354 => 'The email address could not be confirmed.',
  MESSAGE_VERIFICATION_FAILED   => 367 => 'The email address could not be verified.',
  MESSAGE_INVALID_PASSWORD      => 374 => 'Password needs to be atleast 6 characters long.',
  MESSAGE_PASSWORD_MISMATCH     => 457 => 'The passwords do not match. Please try again.',
  MESSAGE_LOGIN_MISSING         => 436 => '_message__LOGIN_MISSING',
  MESSAGE_EMAIL_INVALID         => 492 => 'Please enter a valid email address',
  MESSAGE_NAME_MISSING          => 543 => 'Please provide a name',
  MESSAGE_ACCOUNT_BLOCKED       => 563 => 'Your account seems to be blocked. Please contact the helpdesk in case you need any help.',
  MESSAGE_VERIFICATION_SENT     => 528 => sub { sprintf q(A verification email has been sent to the email address '%s'. Please go to your inbox and click on the link provided in the email.), shift->hub->param('email') },
  MESSAGE_PASSWORD_EMAIL_SENT   => 602 => sub { sprintf q(An email has been sent to the email address '%s'. Please go to your inbox and follow the instructions to reset your password provided in the email.), shift->hub->param('email') },
  MESSAGE_EMAIL_CHANGED         => 645 => sub { sprintf q(You email address on our records has been successfully changed. Please <a href="%s">login</a> with your new email address to continue.), shift->hub->url({'action' => 'Preferences'})},
  MESSAGE_CANT_DELETE_LOGIN     => 691 => 'You can not delete the only login option you have to access your account.',
  MESSAGE_GROUP_NOT_FOUND       => 713 => 'Sorry, we could not find any group.',
  MESSAGE_MEMBER_BLOCKED        => 735 => '_message_MESSAGE_MEMBER_BLOCKED',
  MESSAGE_BOOKMARK_NOT_FOUND    => 782 => '_message_BOOKMARK_NOT_FOUND',
  MESSAGE_UNKNOWN_ERROR         => 952 => 'An unknown error occurred. Please try again or contact the help desk.',
}

sub caption               { return 'Your Account';                                                      }
sub short_caption         { return 'Your Account';                                                      }
sub default_action        { return $_[0]->hub->user ? 'Preferences' : 'Login'                           }

sub openid_providers      { return [ map {$_} @{shift->hub->species_defs->OPENID_PROVIDERS} ];          } ## TODO do I need to map?

sub get_root_url          { return $_[0]->{'_root_url'} ||= $_[0]->hub->species_defs->ENSEMBL_BASE_URL; }
sub get_user_by_id        { return EnsEMBL::ORM::Rose::Manager::User->get_by_id($_[1]);                 }
sub get_user_by_email     { return EnsEMBL::ORM::Rose::Manager::User->get_by_email($_[1]);              }
sub new_login_account     { return EnsEMBL::ORM::Rose::Manager::Login->create_empty_object($_[1]);      }
sub get_login_account     { return EnsEMBL::ORM::Rose::Manager::Login->get_with_user($_[1]);            }
sub get_group             { return EnsEMBL::ORM::Rose::Manager::Group->fetch_by_primary_key($_[1]);       }
sub get_all_groups        { return EnsEMBL::ORM::Rose::Manager::Group->get_objects;                       }

## TODO - change above methods to 'fetch'

sub fetch_membership      { return EnsEMBL::ORM::Rose::Manager::Membership->fetch_by_primary_key($_[1]);  }

sub get_login_from_url_code {
  ## Fetches and returns a login object by parsing the code parameter in the url
  ## @param Flag if on, will ignore checking a valid user object related to the login object
  ## @return Login object for matching salt, login id and user id, undef otherwise
  my ($self, $ignore_user) = @_;

  $self->hub->param('code') =~ /^([0-9]+)\-([0-9]+)\-([a-zA-Z0-9_]+)$/;

  my $login = EnsEMBL::ORM::Rose::Manager::Login->get_objects(
    'with_objects'  => [ 'user' ],
    'query'         => [ 'login_id', $2, 'salt', $3 ],
    'limit'         => 1,
  )->[0];

  if ($login) {
    return $login if $ignore_user;
    my $user = $login->user;
    return $login if $user && $user->user_id eq $1 && $user->status eq 'active';
  }

  return undef;
}

sub new_user_account {
  ## @return unsaved EnsEMBL::ORM::Rose::Object::User object
  my ($self, $params) = @_;

  return EnsEMBL::ORM::Rose::Manager::User->create_empty_object({
    'status'  => 'active',
    'email'   => delete $params->{'email'},
    'name'    => delete $params->{'name'} || '',
    %$params
  });
}

sub activate_user_login {
  ## Activates the user's login object
  ## @param Login object
  my ($self, $login) = @_;
  my $user = $login->user;
  $login->activate;
  $user->save;
  $login->save;
}

sub get_group_types {
  ## Gets the type of groups with the display text
  return {
    'open'          => 'Open - any user can see and join this group.',
    'restricted'    => 'Restricted - any user can see this group, but can join only if an administrator sends him an invitation or approves his request.',
    'private'       => 'Private - a user can not see this group, and can only join it if an administrator sends him a request.'
  };
}

sub get_notification_types {
  ## Gets the type of notifications settings saved in the db for a group admin
  return {
    'notify_join'   => 'Email me when someone joins the group',
    'notify_edit'   => 'Email me when someone edits the group information',
    'notify_share'  => 'Email me when someone shares something with the group'
  };
}

sub get_message {
  ## Returns the message string for a given code
  ## @param Numeric code for the message
  ## @return HTML String message
  my ($self, $code) = @_;
  my $hub           = $self->hub;
  my @messages      = $self->_messages;
  $messages[1] eq $code and return ref $messages[2] eq 'CODE' ? $messages[2]->($self) : $messages[2] or splice @messages, 0, 3 while @messages;
}

sub get_message_code {
  ## Returns the code of the message
  ## @param Message keyword as in &_messages
  ## @return code for url
  my ($self, $key)  = @_;
  my @messages      = $self->_messages;
  $messages[0] eq $key and return $messages[1] or splice @messages, 0, 3 while @messages;
}

sub is_inline_request {
  return shift->hub->param('_inline') ? 1 : undef;
}

sub list_of_countries {
  ## Returns the list of all the countries in the world acc to ISO_3166
  ## @return Hashref with ISO_3166-1 code as key and name of the country as value
  return shift->hub->species_defs->COUNTRY_CODES;
}

1;
