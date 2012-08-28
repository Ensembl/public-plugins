package EnsEMBL::Web::Object::Account;

### NAME: EnsEMBL::Web::Object::Account
### Object for accessing user account information 

### DESCRIPTION
### This module does not wrap around a data object, it merely
### accesses the user object via the session

use strict;

use EnsEMBL::ORM::Rose::Manager::Group;
use EnsEMBL::ORM::Rose::Manager::Login;
use EnsEMBL::ORM::Rose::Manager::Membership;
use EnsEMBL::ORM::Rose::Manager::Record;
use EnsEMBL::ORM::Rose::Manager::User;

use base qw(EnsEMBL::Web::Object);

## TODO - move these messages to seperate module and use them as constants
sub _messages { ## TODO change message texts ## TODO provide error or message heading along with the text
  my $self  = shift;
  my $hub   = $self->hub;

  # Message error constants    => code => message string
  MESSAGE_OPENID_CANCELLED      => 104 => sprintf('Your request to login via %s was cancelled. Please try again, or use one of the alternative login options below.', encode_entities($hub->param('provider') || 'OpenID')),
  MESSAGE_OPENID_INVALID        => 128 => '_message__OPENID_INVALID',
  MESSAGE_OPENID_SETUP_NEEDED   => 167 => '_message__OPENID_SETUP_NEEDED',
  MESSAGE_OPENID_ERROR          => 178 => sprintf('<p>An error happenned while making OpenID request. Please use an alternative login option.</p><p>Error summary: %s</p>', encode_entities($hub->param('oerr') || '')),
  MESSAGE_OPENID_EMAIL_MISSING  => 189 => '_message__OPENID_EMAIL_MISSING',
  MESSAGE_EMAIL_NOT_FOUND       => 206 => 'The email address provided is not recognised. Please try again.',
  MESSAGE_PASSWORD_WRONG        => 247 => 'The password provided is invalid. Please try again.',
  MESSAGE_PASSWORD_INVALID      => 272 => 'Password needs to be atleast 6 characters long.',
  MESSAGE_PASSWORD_MISMATCH     => 289 => 'The passwords do not match. Please try again.',
  MESSAGE_ALREADY_REGISTERED    => 297 => sprintf('The email address provided seems to be already registered. Please try to login with the email, or request to <a href="%s">retrieve your password</a> if you have lost one.', $hub->url({'action' => 'Password', 'function' => 'Lost', 'email' => $hub->param('email')})),
  MESSAGE_VERIFICATION_FAILED   => 337 => 'The email address could not be verified.',
  MESSAGE_VERIFICATION_PENDING  => 351 => '_message__VERIFICATION_PENDING',
  MESSAGE_LOGIN_MISSING         => 436 => '_message__LOGIN_MISSING',
  MESSAGE_EMAIL_INVALID         => 492 => 'Please enter a valid email address',
  MESSAGE_EMAILS_INVALID        => 510 => sprintf('Invalid email address: %s', encode_entities($hub->param('invalids') || '')),
  MESSAGE_NAME_MISSING          => 543 => 'Please provide a name',
  MESSAGE_ACCOUNT_BLOCKED       => 563 => 'Your account seems to be blocked. Please contact the helpdesk in case you need any help.',
  MESSAGE_VERIFICATION_SENT     => 528 => sprintf(q(A verification email has been sent to the email address '%s'. Please go to your inbox and click on the link provided in the email.), encode_entities($hub->param('email'))),
  MESSAGE_PASSWORD_EMAIL_SENT   => 602 => sprintf(q(An email has been sent to the email address '%s'. Please go to your inbox and follow the instructions to reset your password provided in the email.), encode_entities($hub->param('email'))),
  MESSAGE_EMAIL_CHANGED         => 645 => sprintf(q(You email address on our records has been successfully changed. Please <a href="%s">%s</a> to continue.), $hub->url({'action' => 'Preferences'}), $hub->user ? 'click here' : 'login'),
  MESSAGE_CANT_DELETE_LOGIN     => 691 => 'You can not delete the only login option you have to access your account.',
  MESSAGE_GROUP_NOT_FOUND       => 713 => 'Sorry, we could not find the specified group. Either the group does not exist or is inactive or is inaccessible to you for the action selected.',
  MESSAGE_GROUP_INVITATION_SENT => 722 => sprintf(q{Invitation for the group sent successfully to the following email(s): %s}, encode_entities($hub->param('emails'))),
  MESSAGE_CANT_DEMOTE_ADMIN     => 754 => 'Sorry, you can not demote yourself as you seem to be the only administrator of this group.',
  MESSAGE_BOOKMARK_NOT_FOUND    => 782 => 'Sorry, we could not find the specified bookmark.',
  MESSAGE_CANT_DELETE_BOOKMARK  => 789 => 'You do not seem to have the right to delete this bookmark.',
  MESSAGE_NO_EXISTING_ACCOUNT   => 802 => sprintf(q(No existing account was found for the email address provided. Please verify the email address again, or to create a new account, please <a href="%s">click here</a>), $hub->url({'action' => 'OpenID', 'function' => 'Register', 'code' => $hub->param('code')})),
  MESSAGE_URL_EXPIRED           => 815 => 'The link you clicked to reach here has been expired.',
  MESSAGE_UNKNOWN_ERROR         => 952 => 'An unknown error occurred. Please try again or contact the help desk.'
}

sub caption               { return 'Your Account';                                                        }
sub short_caption         { return 'Your Account';                                                        }
sub default_action        { return $_[0]->hub->user ? 'Preferences' : 'Login'                             }

sub openid_providers      { return [ map {$_} @{shift->hub->species_defs->OPENID_PROVIDERS} ];            } ## TODO do I need to map?
sub get_root_url          { return $_[0]->{'_root_url'} ||= $_[0]->hub->species_defs->ENSEMBL_BASE_URL;   }

sub new_login_account     { return EnsEMBL::ORM::Rose::Manager::Login->create_empty_object($_[1]);        }
sub fetch_login_account   { return EnsEMBL::ORM::Rose::Manager::Login->get_with_user($_[1]);              }
sub fetch_user_by_email   { return EnsEMBL::ORM::Rose::Manager::User->get_by_email($_[1]);                }

sub fetch_membership {
  ## Fetches a membership object with the given id
  ## Wrapper around fetch_by_primary_key of the manager class
  ## @params As accepted by fetch_by_primary_key method
  return EnsEMBL::ORM::Rose::Manager::Membership->fetch_by_primary_key(splice @_, 1);
}

sub fetch_group {
  ## Fetches a group object with the given id
  ## Wrapper around fetch_by_primary_key of the manager class
  ## @params As accepted by fetch_by_primary_key method
  return EnsEMBL::ORM::Rose::Manager::Group->fetch_by_primary_key(splice @_, 1);
}

sub fetch_groups {
  ## Fetches group objects
  ## Wrapper around get_objects of the manager class
  ## @param Reference of a hash as accepted by get_objects method
  return EnsEMBL::ORM::Rose::Manager::Group->get_objects(%{$_[1] || {}});
}

sub fetch_login_from_url_code {
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

sub fetch_accessible_membership_for_user {
  ## Fetches a membership object for the user for a given group
  ## Membership object fetched is active and linked to an active group unless the user is admin - ie. it will only get an inactive group membership for an admin of the group
  ## @param User object
  ## @param Group object or group id
  ## @param Optional hashref to be passed to find_memberships method of user object
  ## @return Membership object if found
  my ($self, $user, $group, $params) = @_;
  push @{$params->{'query'}         ||= []}, ('or' => ['level' => 'administrator', 'group.status' => 'active'], 'status' => 'active', 'member_status' => 'active');
  push @{$params->{'with_objects'}  ||= []}, 'group' unless grep {$_ eq 'group'} @{$params->{'with_objects'} || []};
  return $user->get_membership_object($group, {%$params, 'multi_many_ok' => 1});
}

sub fetch_active_membership_for_user {
  ## Fetches a membership object for the user for a given group
  ## Membership object fetch is active and linked to an active group
  ## @param User object
  ## @param Group object or group id
  ## @param Optional hashref to be passed to find_memberships method of user object
  ## @return Membership object if found
  my ($self, $user, $group, $params) = @_;
  push @{$params->{'query'} ||= []}, ('group.status' => 'active', 'status' => 'active', 'member_status' => 'active');
  push @{$params->{'with_objects'} ||= []}, 'group';
  return $user->get_membership_object($group, {%$params, 'multi_many_ok' => 1});
}

sub fetch_bookmark_with_owner {
  ## Fetches bookmark for the logged-in user with given bookmark id
  ## @param Bookmark record id (if 0, a new record is created)
  ## @param Group id (optional) if the bookmark is owned by a group
  ## @return List: Bookmark object and owner of the bookmark (ie. either a group object, or the user object itself)
  my ($self, $bookmark_id, $group_id) = @_;
  my $owner = $self->hub->user->rose_object;

  if ($bookmark_id) {
    if ($group_id) {
      my $membership = $self->fetch_accessible_membership_for_user($owner, $group_id, {'query' => ['group.status' => 'active']});
      $owner = $membership ? $membership->group : undef;
    }

    if ($owner && (my $bookmark = shift @{$owner->find_bookmarks('query' => [ 'record_id' => $bookmark_id ])})) {
      return ($bookmark, $owner);
    }
  } elsif (defined $bookmark_id)  {
    return ($owner->create_record('bookmark'), $owner);
  }
  return ();
}

sub fetch_invitation_record_from_url_code {
  ## Fetches and returns an invitation record by parsing the code parameter in the url
  ## @return Record object (user record)
  my $self = shift;

  $self->hub->param('invitation') =~ /^([a-zA-Z0-9_]+)\-([0-9]+)$/;

  my $invitations = EnsEMBL::ORM::Rose::Manager::Record->get_group_records(
    'with_objects'  => [ 'group' ],
    'query'         => [ 'record_id' => $2 ],
    'limit'         => 1
  );

  $_->invitation_code eq $1 and return $_ for @$invitations;
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
  ## @param Numeric code (or error constant) for the message
  ## @return HTML String message
  my ($self, $code)   = @_;
  my $hub             = $self->hub;
  my @messages        = $self->_messages;
  my $index_to_match  = $code =~ /^[0-9]+$/ ? 1 : 0;
  $messages[$index_to_match] eq $code and return ref $messages[2] eq 'CODE' ? $messages[2]->($self) : $messages[2] or splice @messages, 0, 3 while @messages;
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
