package EnsEMBL::ORM::Rose::Object::Membership;

### NAME: EnsEMBL::ORM::Rose::Object::Membership
### ORM class for the group_member table in ensembl_web_user_db

### Status of the membership is decided by two columns: status and member_status
### status: active    member_status: active   Membership is active
### status: active    member_status: inactive User removed himself from the group - To join the group again, he can send a request or can receive an invitation
### status: active    member_status: pending  Invitation is waiting user's approval
### status: active    member_status: barred   User blocked the group - he will not receive any invitations but can still send a request to join the group - he can also unblock the group be setting member_status to inactive
### member_status: active   status: inactive  Admin removed user from the group - To join the group again, user can be sent an invitation again or can send a request for membership approval
### member_status: active   status: pending   User sent a request to join the group for admin's approval
### member_status: active   status: barred    User blocked by the group's admin. User can not send any request for joining group - Admin can send an invitation to the user, or can unblock the user by setting status to inactive
### any other combinations should not be allowed - ie. one of the statuses has to be active at all times

### A membership record once created never gets removed from the db - either of the status or member_status can be inactive for the record to appear removed

### level column can contain three values:
### member: A normal member of the group
### administrator: Can send invitations, accept/reject requests, edit the group and in-activate/re-activate the group
### superuser: Can do everything an administrator can do, except inactivating the group

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table                 => 'group_member',

  columns               => [
    group_member_id   => {type => 'serial', primary_key => 1, not_null => 1},
    webgroup_id       => {type => 'integer'},
    user_id           => {type => 'integer'},
    level             => {type => 'enum', 'values' => [qw(member administrator superuser)]},
    status            => {type => 'enum', 'values' => [qw(active inactive pending barred)], 'default' => 'active'  },  #status set by the admin
    member_status     => {type => 'enum', 'values' => [qw(active inactive pending barred)], 'default' => 'inactive'},  #status set by the user
  ],

  relationships         => [
    user => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'  => {'user_id' => 'user_id'},
    },
    group => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Group',
      'column_map'  => {'webgroup_id' => 'webgroup_id'},
    }
  ]
);

sub is_active {
  ## Checks whether both status and member_status are active
  my $self = shift;
  return $self->status eq 'active' && $self->member_status eq 'active';
}

sub is_inactive {
  ## Checks whether either status or member_status is inactive
  my $self = shift;
  return $self->status eq 'inactive' || $self->member_status eq 'inactive';
}

sub is_group_blocked {
  ## Checks whether the group is blocked by the user
  return shift->member_status eq 'barred';
}

sub is_user_blocked {
  ## Checks whether the user is blocked by the group
  return shift->status eq 'barred';
}

sub is_pending_invitation {
  ## Checks whether this membership is a pending invitation for the user
  my $self = shift;
  return $self->member_status eq 'pending';
}

sub is_pending_request {
  ## Checks whether this membership is a pending request by the user
  my $self = shift;
  return $self->status eq 'pending';
}

sub make_invitation {
  ## Modifies the status and member_status to make it an invitation for the user
  my $self = shift;
  $self->status('active');
  $self->member_status('pending');
  $self->level('member');
}

sub make_request {
  ## Modifies the status and member_status to make it a request from user
  my $self = shift;
  $self->status('pending');
  $self->member_status('active');
  $self->level('member');
}

sub activate {
  ## Modifies the status and member_status to make user status active
  my $self = shift;
  $self->status('active');
  $self->member_status('active');
  $self->level('member');
}

sub inactivate_user {
  ## Modifies the status and member_status to make user status inactive
  my $self = shift;
  $self->status('inactive');
  $self->member_status('active');
  $self->level('member');
}

sub inactivate_group {
  ## Modifies the status and member_status to make group status inactive
  my $self = shift;
  $self->status('active');
  $self->member_status('inactive');
  $self->level('member');
}

sub block_user {
  ## Modifies the status and member_status to block the user
  my $self = shift;
  $self->status('barred');
  $self->member_status('active');
  $self->level('member');
}

sub block_group {
  ## Modifies the status and member_status to block the group
  my $self = shift;
  $self->status('active');
  $self->member_status('barred');
  $self->level('member');
}

1;