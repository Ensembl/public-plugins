package EnsEMBL::ORM::Rose::Object::Group;

### NAME: EnsEMBL::ORM::Rose::Object::Group
### ORM class for the webgroup table in ensembl_web_user_db

### All methods provided to modify group's membership should only be called after verifying whether user is authorised to use them (ie. he is admin/superuser of the group)

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Membership;
use EnsEMBL::ORM::Rose::Manager::Membership;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table                 => 'webgroup',

  columns               => [
    webgroup_id   => {type => 'serial', primary_key => 1, not_null => 1},
    name          => {type => 'varchar', 'length' => '255'},
    blurb         => {type => 'text'},
    data          => {type => 'text'},
    type          => {type => 'enum', 'values' => [qw(open restricted private)]},
    status        => {type => 'enum', 'values' => [qw(active inactive)]}
  ],

  title_column          => 'name',
  inactive_flag_column  => 'status',
  inactive_flag_value   => 'inactive',

  relationships   => [
    memberships     => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'webgroup_id' => 'webgroup_id'},
    }
  ]
);

sub membership {
  ## Returns the membership object for the given user, creates a new membership object if no existing found
  ## @param Member - Rose User object
  ## @param (Only considered if new membership is being created) User level (administrator, superuser or member) - defaults to 'member'
  ## @return Membership object
  my ($self, $member, $level) = @_;
  my $membership = $self->get_membership($member);
  unless ($membership) {
    $self->forget_related('membership');    ## TODO - do some testing thing here about - is it really needed or does Rose update it automatically?
    $member->forget_related('membership');  ## TODO - as above
    $membership = EnsEMBL::ORM::Rose::Object::Membership->new(
      'user'  => $member,
      'group' => $self,
      'level' => $level =~ /^(administrator|superuser)$/ ? $level : 'member'
    );
  }
  return $membership;
}

sub get_membership {
  ## Gets the Membership object related to a the user for this group only if found - no new membership is created
  ## @param Member - User rose object
  ## @return Rose Membership object or undef if user is not a member of this group
  my ($self, $member) = @_;
  my $member_id       = $member->user_id;
  my $group_id        = $self->webgroup_id;
  my $membership      = undef;

  # Fetch only the required row if already not fetched
  if ($member->has_loaded_related('memberships')) {
    $_->webgroup_id == $group_id and $membership = $_ and last for $member->memberships;
  }
  elsif ($self->has_loaded_related('memberships')) {
    $_->user_id == $member_id and $membership = $_ and last for $self->memberships;
  }
  else {
    ($membership) = @{EnsEMBL::ORM::Rose::Manager::Membership->get_objects(
      'query' => [
        'user_id'     => $member_id,
        'webgroup_id' => $group_id
      ],
      'limit' => 1
    ) || []};
  }
  return $membership;
}

sub members {
  ## Gets all the members for the group - including superusers and admins
  ## @return Array of User rose objects
  return shift->_get_members;
}

sub admins {
  ## Gets all the admins for the group
  ## @return Array of User rose objects
  return shift->_get_members('administrator');
}

sub superusers {
  ## Gets all the superusers for the group
  ## @return Array of User rose objects
  return shift->_get_members('superuser');
}

sub non_admin_members {
  ## Gets all the members for the group - excluding superusers and admins
  ## @return Array of User rose objects
  return shift->_get_members('member');
}

sub set_admin {
  ## Sets an existing member as admin of the group
  ## @param Rose User object - existing member who is to be made Admin
  ## @param Web::User object to update the trackable info - logged in user
  ## @return 1 if done successfully or level already the same, 0 if user is not a member if this group, -1 if user trying to change his own level
  shift->_change_member_level('administrator', @_);
}

sub set_superuser {
  ## Sets an existing member as superuser of the group
  ## @param Rose User object - existing member who is to be made superuser
  ## @param Web::User object to update the trackable info - logged in user
  ## @return 1 if done successfully, undef if user is already a superuser
  ## @return 1 if done successfully or level already the same, 0 if user is not a member if this group, -1 if user trying to change his own level
  shift->_change_member_level('superuser', @_);
}

sub set_non_admin_member {
  ## Sets an existing admin/superuser as non-admin member of the group
  ## @param Rose User object - existing member who is to be demoted
  ## @param Web::User object to update the trackable info - logged in user
  ## @return 1 if done successfully, undef if user is already a non admin member
  ## @return 1 if done successfully or level already the same, 0 if user is not a member if this group, -1 if user trying to change his own level
  shift->_change_member_level('member', @_);
}

sub invite_user {
  ## Creates an invitation for a member - does NOT send any email
  ## This adds a new row in the membership's table, but only if no existing row is found with same user_id and webgroup_id
  ## @param Rose User object to be sent invitation to be a member
  ## @param Web::User object to update the trackable info - logged in user
  ## @return 1 if invitation is created (or already exists), 0 - if user is already an active member of group or -1 if user has blocked the group
  my ($self, $member, $admin) = @_;

  my $membership = $self->membership($member, 'member');

  return 0  if $membership->is_active;
  return -1 if $membership->is_group_blocked;

  $membership->make_invitation unless $membership->is_pending_invitation;
  $membership->save(user => $admin);

  return 1;
}

sub block_user {
  ## Blocks a user from the group or from sending any further invitations to the group
  ## @param Member to be blocked - Rose User object
  ## @param Logged in user for trackable info - Web User obect
  ## @return 1 if user blocked successfully (or was already blocked), 0 if user is not a member of the group or -1 if user is either admin or superuser
  my ($self, $member, $admin) = @_;

  if (my $membership = $self->get_membership($member)) {
    return -1 if $membership->level ne 'member';
    $membership->block_user;
    $membership->save(user => $admin);
    return 1;
  }
  return undef;
}

sub unblock_user {
  ## Unblocks a previously blocked user
  ## @param Member to be unblocked - Rose User object
  ## @param Logged in user for trackable info - Web User object
  ## @return 1 if unblocked successfully, 0 if user not a member of this group, -1 if member not blocked
  my ($self, $member, $admin) = @_;

  if (my $membership = $self->get_membership($member)) {
    return -1 unless $membership->is_user_blocked;
    $membership->inactivate_user;
    $membership->save(user => $admin);
    return 1;
  }
  return 0;
}

sub activate_user {
  ## Makes the status of the user active - only if membership is a pending request from user
  ## @param Member to be set as active - Rose User object
  ## @param Logged in user for trackable info - Web User obect
  ## @return 1 if user set active successfully, 0 if user not a member of this group, -1 if current status is anything other than pending request from user
  my ($self, $member, $admin) = @_;

  if (my $membership = $self->get_membership($member)) {
    return -1 unless $membership->is_pending_request;
    $membership->activate;
    $membership->save(user => $admin);
    return 1;
  }
  return 0;
}

sub inactivate_user {
  ## Makes the status of the user inactive - only an active user or a pending invitation or a pending request can be inactivated
  ## @param Member to be set as inactive - Rose User object
  ## @param Logged in user for trackable info - Web User obect
  ## @return 1 if user set inactive successfully, 0 if user not a member of this group, -1 if user is neither active nor is the membership status a pending invitation or request
  my ($self, $member, $admin) = @_;

  if (my $membership = $self->get_membership($member)) {
    return -1 unless $membership->is_active || $membership->is_pending_invitation || $membership->is_pending_request;
    $membership->inactivate_user;
    $membership->save(user => $admin);
    return 1;
  }
  return 0;
}

### 
# Some private methods
###

sub _get_members {
  my ($self, $level) = @_;
  return [ map { $_->is_active && (!$level || $level eq $_->level) ? $_->user : () } shift->memberships ];
}

sub _change_member_level {
  my ($self, $new_level, $member, $admin) = @_;

  my $membership = $self->get_membership($member);

  return 0  if !$membership;
  return -1 if $membership->user_id eq $admin->user_id;

  $membership->level($new_level);
  $membership->save(user => $admin);
  return 1;
}

1;