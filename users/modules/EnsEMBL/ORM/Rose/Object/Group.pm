package EnsEMBL::ORM::Rose::Object::Group;

### NAME: EnsEMBL::ORM::Rose::Object::Group
### ORM class for the webgroup table in ensembl_web_user_db

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

__PACKAGE__->meta->setup(
  table                 => 'webgroup',

  columns               => [
    webgroup_id           => {
      'type'                => 'serial',
      'primary_key'         => 1,
      'not_null'            => 1,
      'alias'               => 'group_id'
    },
    name                  => {
      'type'                => 'varchar',
      'length'              => '255'
    },
    blurb                 => {
      'type'                => 'text'
    },
    data                  => {
      'type'                => 'text'
    },
    type                  => {
      'type'                => 'enum',
      'values'              => [qw(open restricted private)],
      'default'             => 'restricted'
    },
    status                => {
      'type'                => 'enum',
      'values'              => [qw(active inactive)],
      'default'             => 'active'
    }
  ],

  title_column          => 'name',
  inactive_flag_column  => 'status',
  inactive_flag_value   => 'inactive',

  relationships         => [
    memberships           => {
      'type'                => 'one to many',
      'class'               => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'          => {'webgroup_id' => 'webgroup_id'},
      'methods'             => { map {$_, undef} qw(add_on_save count find get_set_on_save)}
    },
    records               => {
      'type'                => 'one to many',
      'class'               => 'EnsEMBL::ORM::Rose::Object::GroupRecord',
      'column_map'          => {'webgroup_id' => 'webgroup_id'},
    }
  ],

  virtual_relationships => [
    annotations           => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'annotation'}
    },
    bookmarks             => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'bookmark'}
    },
    invitations           => { # this record only contains the invitations for the users who have not yet registered with ensembl, invitations for existing users are saved as Membership objects
      'relationship'        => 'records',
      'condition'           => {'type' => 'invitation'}
    }
  ]
);

sub membership {
  ## Returns the membership object for the given user, creates a new membership object if no existing found
  ## @param Member - Rose User object
  ## @param User level (administrator or member) - defaults to 'member' - Only considered if new membership is being created
  ## @return Membership object, possibly a new unsaved one
  my ($self, $member, $level) = @_;
  my $membership = $member->get_membership_object($self);
  unless ($membership) {
    $membership = ($self->add_memberships([{
      'user_id'   => $member->user_id,
      'group_id'  => $self->group_id,
      'level'     => $level eq 'administrator' ? 'administrator' : 'member'
    }]))[0];
  }
  return $membership;
}

sub admin_memberships {
  ## Gets all the membership objects with administrator level
  ## @return Arrayref of membership objects
  my $self = shift;
  return my $memberships = $self->find_memberships('query' => ['level' => 'administrator', 'status' => 'active', 'member_status' => 'active', 'user.status' => 'active'], 'with_objects' => 'user');
}

#########################
####                 ####
#### RECORDS METHODS ####
####                 ####
#########################

sub create_record {
  ## Creates a group record of a given type (does not save it to the db)
  ## @param Type of the record
  ## @param Hashref of name value pair for columns of the new object (optional)
  my ($self, $type, $params) = @_;

  return ($self->add_records([{
    'user_id'       => $self->group_id,
    'type'          => $type,
    %{$params || {}}
  }]))[0];
}

1;