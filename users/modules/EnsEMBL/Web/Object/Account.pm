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

sub caption               { return 'Your Account';                                                        }
sub short_caption         { return 'Your Account';                                                        }
sub default_action        { return $_[0]->hub->user ? 'Preferences' : 'Login';                            }

sub openid_providers      { return $_[0]->deepcopy($_[0]->hub->species_defs->OPENID_PROVIDERS);           }
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

sub count_groups {
  ## Counts the number of groups user is a member of
  ## @param hashref with keys:
  ##  - active_only : If on, will return groups that are active only, other it will count inactive groups for the admin user
  ##  - admin_only  : If on, will return groups that user is an admin of
  ## @return number
  my ($self, $params) = @_;

  return $self->hub->user->rose_object->memberships_count('with_objects' => ['group'], 'query' => [
    'status'          => 'active',
    'member_status'   => 'active',
    $params->{'active_only'} ? (
      'group.status'    => 'active'
    ) : (
      'or'              => [
        'level'           => 'administrator',
        'group.status'    => 'active'
      ]
    ),
    $params->{'admin_only'} ? (
      'level'           => 'administrator'
    ) : ()
  ]);
}

sub count_bookmarks {
  ## Counts the number of bookmarks for a user
  ## @return number
  return shift->hub->user->rose_object->bookmarks_count;
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
