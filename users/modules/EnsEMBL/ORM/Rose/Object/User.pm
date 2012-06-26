package EnsEMBL::ORM::Rose::Object::User;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the user table in ensembl_web_user_db 

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';
#use constant DEBUG_SQL => 1;

__PACKAGE__->meta->setup(
  table       => 'user',

  columns     => [
    user_id           => {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1},
    name              => {'type' => 'varchar', 'length' => '255'},
    email             => {'type' => 'varchar', 'length' => '255'},
    data              => {'type' => 'text'},
    organisation      => {'type' => 'varchar', 'length' => '255'},
    country           => {'type' => 'varchar', 'length' => '2'},
    status            => {'type' => 'enum', 'values' => [qw(active suspended)], 'default' => 'active'},
  ],

  relationships => [
    logins            => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Login',
      'column_map'  => {'user_id' => 'user_id'},
    },
    records           => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::UserRecord',
      'column_map'  => {'user_id' => 'user_id'},
    },
    memberships       => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'user_id' => 'user_id'},
    },
    admin_privilege   => {
      'type'        => 'one to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::AdminPrivilage',
      'column_map'  => {'user_id' => 'user_id'}
    }
  ],

  virtual_relationships => [
    bookmarks             => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'bookmark'}
    },
  ]
);

############################
####                    ####
####    LOGIN METHOD    ####
####                    ####
############################

sub activate_login {
  ## Activates the given login object after copying the information like name, organisation, country to the user and linking both login to the user (does not save to the database afterwards)
  ## @param Login object to be linked an activated
  my ($self, $login) = @_;

  $login->copy_details_to_user($self);
  $login->activate;

  $self->add_logins([$login]);
}

sub get_local_login {
  ## Gets the local login object related to the user
  my $self = shift;

  $_->type eq 'local' and return $_ for @{$self->logins};
}

############################
####                    ####
#### MEMBERSHIPS METHOD ####
####                    ####
############################

sub get_membership_object {
  ## Gets membership object related to a given group
  ## @param Group object or id of the group
  ## @param Level of the membership - optional - if provided, will return the object only if level is same the level provided
  ## @return Membership object, if found, undef otherwise
  my ($self, $group, $level) = @_;
  my $group_id = ref $group ? $group->group_id : $group or return undef;
  $self->load('with' => 'memberships');
  $_->group_id eq $group_id and return !$level || $level && $level eq $_->level ? $_ : undef for $self->memberships;
}

sub admin_memberships {
  ## Gets all the admin memberships for the user
  return shift->find_memberships('query' => ['level' => 'administrator', 'status' => 'active', 'member_status' => 'active']);
}

sub nonadmin_memberships {
  ## Gets all the non-admin memberships for the user
  return shift->find_memberships('query' => ['level' => 'member', 'status' => 'active', 'member_status' => 'active']);
}

sub active_memberships {
  ## Gets all the active memberships for the user
  return shift->find_memberships('query' => ['status' => 'active', 'member_status' => 'active']);
}

sub create_group_membership {
  ## Creates a membership and group with the given details
  ## @param Hashref with keys as column (and relationships) for the membership object
  ## @return Memberhsip object with a new group (not yet saved to the database)
  my ($self, $params) = @_;

  return $self->meta->relationship('memberships')->class->new(
    'level'         => 'administrator',
    'user_id'       => $self->user_id,  # many to one relation do not save objects, so have to provide the foreign key value
    'status'        => 'active',
    'member_status' => 'active',
    'group'         => {
      'status'        => 'active'
    },
    %{$params || {}}    
  );
}



#####################
###               ###
### GROUP METHODS ###
###               ###
#####################

sub is_member_of {
  ## Checks whether user is a member of the given group
  ## @param Group rose object or id of the group
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  return $self->get_membership_object($group) ? 1 : undef;
}

sub is_admin_of {
  ## Checks whether user is an admin of the given group
  ## @param Group rose object or id of the group
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $self->get_membership_object($group);
  return $membership && $membership->level eq 'administrator' ? 1 : undef;
}

sub is_nonadminmember_of {
  ## Checks whether user is non-admin member of the given group
  ## @param Group rose object or id of the group
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $self->get_membership_object($group);
  return $membership && $membership->level eq 'member' ? 1 : undef;
}

sub request_membership {
  ## Creates a request for a group
  ## This adds a new row in the membership's table, but only if no existing row is found with same user_id and group_id
  ## @param Rose Group object to be sent request for
  ## @return
  ##   1  if request is created (or already exists)
  ##   -1 if user joined the group now (open group) or was already an active member of group
  ##   0  if user is blocked from the group
  my ($self, $group) = @_;

  my $membership = $group->membership($self, 'member');

  return 0  if $membership->is_user_blocked;
  return -1 if $membership->is_active;

  my $return = -1;
  if ($group->type eq 'open') {
    $membership->activate;
  } else {
    $membership->make_request unless $membership->is_pending_request;
    $return = 1;
  }
  $membership->save(user => $self);

  return $return;
}

sub block_group {
  ## Blocks a group from sending any further invitations
  ## @param Group to be blocked - Rose Group object
  ## @return 1 if group blocked successfully (or was already blocked), -1 if user is not a member of the group or 0 if user is admin of the group
  my ($self, $group) = @_;

  if (my $membership = $group->get_membership($self)) {
    return 0 if $membership->level ne 'member';
    $membership->block_group;
    $membership->save(user => $self);
    return 1;
  }
  return -1;
}

sub unblock_group {
  ## Unblocks a previously blocked group
  ## @param Group to be unblocked - Rose Group object
  ## @return 1 if unblocked successfully, 0 if user not a member of this group, -1 if group not blocked
  my ($self, $group) = @_;

  if (my $membership = $group->get_membership($self)) {
    return -1 unless $membership->is_group_blocked;
    $membership->inactivate_group;
    $membership->save(user => $self);
    return 1;
  }
  return 0;
}

sub accept_request {
  ## Makes the status of the user active - only if membership is a pending invitation for user
  ## @param Rose Group object or id of the group
  ## @return 1 if user set active successfully, 0 if user not a member of this group, -1 if current status is anything other than pending request from user
  my ($self, $group) = @_;

  if (my $membership = $self->get_membership_object($group)) {
    return -1 unless $membership->is_pending_invitation;
    $membership->activate;
    $membership->save(user => $self);
    return 1;
  }
  return 0;
}

sub inactivate_group {
  ## Makes the status of the group inactive - only an active user or a pending invitation or a pending request can be inactivated
  ## @param Group whose membership is to be set as inactive - Rose Group object or id of the group
  ## @return 1 if user set inactive successfully, 0 if user not a member of this group, -1 if user membership is neither active nor is the membership status a pending invitation or request
  my ($self, $group) = @_;

  if (my $membership = $self->get_membership_object($group)) {
    return -1 unless $membership->is_active || $membership->is_pending_invitation || $membership->is_pending_request;
    $membership->inactivate_group;
    $membership->save(user => $self);
    return 1;
  }
  return 0;
}

#########################
####                 ####
#### RECORDS METHODS ####
####                 ####
#########################

sub create_record   {
  ## Creates a user record of a given type (does not save it to the db)
  ## @param Type of the record
  ## @param Hashref of name value pair for columns of the new object (optional)
  my ($self, $type, $params) = @_;

  return $self->meta->relationship('records')->class->new(
    'user_id'       => $self->user_id,
    'type'          => $type,
    %{$params || {}}
  );
}


sub configurations  { return [ grep {$_->type eq 'configuration'}   shift->records ]; } ## Gets all the configurations for the user   @return ArrayRef of UserRecord rose objects
sub annotations     { return [ grep {$_->type eq 'annotation'}      shift->records ]; } ## Gets all the annotations for the user      @return ArrayRef of UserRecord rose objects
sub dases           { return [ grep {$_->type eq 'das'}             shift->records ]; } ## Gets all the das sources for the user      @return ArrayRef of UserRecord rose objects
sub newsfilters     { return [ grep {$_->type eq 'newsfilter'}      shift->records ]; } ## Gets all the newsfilters for the user      @return ArrayRef of UserRecord rose objects
sub sortables       { return [ grep {$_->type eq 'sortable'}        shift->records ]; } ## Gets all the sortables for the user        @return ArrayRef of UserRecord rose objects
sub currentconfigs  { return [ grep {$_->type eq 'current_config'}  shift->records ]; } ## Gets all the current configs for the user  @return ArrayRef of UserRecord rose objects
sub specieslists    { return [ grep {$_->type eq 'specieslist'}     shift->records ]; } ## Gets all the specieslists for the user     @return ArrayRef of UserRecord rose objects
sub uploads         { return [ grep {$_->type eq 'upload'}          shift->records ]; } ## Gets all the uploads for the user          @return ArrayRef of UserRecord rose objects
sub urls            { return [ grep {$_->type eq 'url'}             shift->records ]; } ## Gets all the urls for the user             @return ArrayRef of UserRecord rose objects
sub histories       { return [ grep {$_->type eq 'history'}         shift->records ]; } ## Gets all the history for the user          @return ArrayRef of UserRecord rose objects

1;