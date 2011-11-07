package EnsEMBL::ORM::Rose::Object::User;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the user table in ensembl_web_user_db 

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::ORM::Rose::Object::Group;
use EnsEMBL::ORM::Rose::Object::UserRecord;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'user',

  columns     => [
    user_id           => {type => 'serial', primary_key => 1, not_null => 1},
    name              => {type => 'varchar', 'length' => '255'},
    email             => {type => 'varchar', 'length' => '255'},
    salt              => {type => 'varchar', 'length' => '8'},
    password          => {type => 'varchar', 'length' => '64'},
    data              => {type => 'text'},
    organisation      => {type => 'text'},
    status            => {type => 'enum', 'values' => [qw(active pending suspended)]}
  ],

  title_column          => 'name',
  inactive_flag_column  => 'status',
  inactive_flag_value   => 'suspended',

  relationships => [
    records       => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::UserRecord',
      'column_map'  => {'user_id' => 'user_id'},
    },
    memberships   => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'user_id' => 'user_id'},
    }
  ]
);

############################
####                    ####
#### MEMBERSHIPS METHOD ####
####                    ####
############################

sub admin_memberships {
  ## Gets all the admin memberships for the user
  ## @param optional hashref with key 'superuser' - if value is boolean true, includes the superuser memberships
  my ($self, $params) = @_;
  my $regexp = $params->{'superuser'} ? qr/^(administrator|superuser)$/ : qr/^administrator$/;
  return [ grep {$_->level =~ $regexp} $self->memberships ];
}

sub nonadmin_memberships {
  ## Gets all the non-admin memberships for the user
  my $self = shift;
  return [ grep {$_->level eq 'member'} $self->memberships ];
}

#####################
###               ###
### GROUP METHODS ###
###               ###
#####################

sub is_member_of {
  ## Checks whether user is a member of the given group
  ## @param Group rose object
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  return $group->get_membership($self) ? 1 : undef;
}

sub is_admin_of {
  ## Checks whether user is an admin of the given group
  ## @param Group rose object
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $group->get_membership($self);
  return $membership && $membership->level eq 'administrator' ? 1 : undef;
}

sub is_superuser_of {
  ## Checks whether user is a superuser of the given group
  ## @param Group rose object
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $group->get_membership($self);
  return $membership && $membership->level eq 'superuser' ? 1 : undef;
}

sub is_nonadminmember_of {
  ## Checks whether user is non-admin member of the given group
  ## @param Group rose object
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $group->get_membership($self);
  return $membership && $membership->level eq 'member' ? 1 : undef;
}

sub create_group {
  ## Creates a group and saves it with the given details
  ## @param Name of the group
  ## @param Description text of the group
  ## @param Type of the group - open, restricted or private - defaults to restricted
  ## @throw UserException::IllegalArgumentException if group name is less than 8 chars long
  my ($self, $name, $description, $type) = @_;

  # validation
  ($name ||= '') =~ s/^\s|\s$//;
  throw exception('UserException::IllegalArgumentException', 'Name of the group needs to be at least 8 characters') if length $name < 8;
  $type = 'restricted' unless $type || $type =~ /^open|private$/;

  return EnsEMBL::ORM::Rose::Object::Group->new(
    'name'        => $name,
    'blurb'       => sprintf('%s', $description || ''),
    'type'        => $type,
    'status'      => 'active',
    'memberships' => [{
      'user'        => $self,
      'level'       => $level
    }]
  )->save('user' => $self);  ## cascade => 1 - TODO - test this! - both tables being updated? trackable info being saved to both?
}

sub request_membership {
  ## Creates a request for a group
  ## This adds a new row in the membership's table, but only if no existing row is found with same user_id and webgroup_id
  ## @param Rose Group object to be sent request for
  ## @return 1 if request is created (or already exists), 0 - if user is already an active member of group or -1 if user is blocked from the group
  my ($self, $group) = @_;

  my $membership = $group->membership($self, 'member');

  return 0  if $membership->is_active;
  return -1 if $membership->is_user_blocked;

  $membership->make_request unless $membership->is_pending_request;
  $membership->save(user => $self);

  return 1;
}

sub block_group {
  ## Blocks a group from sending any further invitations
  ## @param Group to be blocked - Rose Group object
  ## @return 1 if group blocked successfully (or was already blocked), 0 if user is not a member of the group or -1 if user is either admin or superuser
  my ($self, $group) = @_;

  if (my $membership = $group->get_membership($self)) {
    return -1 if $membership->level ne 'member';
    $membership->block_group;
    $membership->save(user => $self);
    return 1;
  }
  return undef;
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
  ## @param Rose Group object
  ## @return 1 if user set active successfully, 0 if user not a member of this group, -1 if current status is anything other than pending request from user
  my ($self, $group) = @_;

  if (my $membership = $group->get_membership($self)) {
    return -1 unless $membership->is_pending_invitation;
    $membership->activate;
    $membership->save(user => $self);
    return 1;
  }
  return 0;
}

sub inactivate_group {
  ## Makes the status of the group inactive - only an active user or a pending invitation or a pending request can be inactivated
  ## @param Group whose membership is to be set as inactive - Rose Group object
  ## @return 1 if user set inactive successfully, 0 if user not a member of this group, -1 if user is neither active nor is the membership status a pending invitation or request
  my ($self, $group) = @_;

  if (my $membership = $group->get_membership($self)) {
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

sub create_record {
  ## Creats a new (unsaved) UserRecord object for the given type for this user
  my ($self, $type) = @_;
  return EnsEMBL::ORM::Rose::Object::UserRecord->new('type' => $type, 'user' => $self);
}

sub bookmarks       { return [ grep {$_->type eq 'bookmark'}        shift->records ]; } ## Gets all the bookmarks for the user        @return ArrayRef of UserRecord rose objects
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