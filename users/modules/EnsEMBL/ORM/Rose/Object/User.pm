package EnsEMBL::ORM::Rose::Object::User;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the user table in ensembl_web_user_db 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

__PACKAGE__->meta->setup(
  table                 => 'user',

  columns               => [
    user_id               => {
      'type'                => 'serial',
      'primary_key'         => 1,
      'not_null'            => 1
    },
    name                  => {
      'type'                => 'varchar',
      'length'              => '255'
    },
    email                 => {
      'type'                => 'varchar',
      'length'              => '255'
    },
    data                  => {
      'type'                => 'text'
    },
    organisation          => {
      'type'                => 'varchar',
      'length'              => '255'
    },
    country               => {
      'type'                => 'varchar',
      'length'              => '2'
    },
    status                => {
      'type'                => 'enum',
      'values'              => [qw(active suspended)],
      'default'             => 'active'
    }
  ],

  relationships         => [
    logins                => {
      'type'                => 'one to many',
      'class'               => 'EnsEMBL::ORM::Rose::Object::Login',
      'column_map'          => {'user_id' => 'user_id'},
    },
    records               => {
      'type'                => 'one to many',
      'class'               => 'EnsEMBL::ORM::Rose::Object::UserRecord',
      'column_map'          => {'user_id' => 'user_id'},
    },
    memberships           => {
      'type'                => 'one to many',
      'class'               => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'          => {'user_id' => 'user_id'},
    },
    admin_privilege       => {
      'type'                => 'one to one',
      'class'               => 'EnsEMBL::ORM::Rose::Object::AdminPrivilage',
      'column_map'          => {'user_id' => 'user_id'}
    }
  ],

  virtual_relationships => [
    bookmarks             => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'bookmark'}
    },
    configurations        => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'configuration'}
    },
    annotations           => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'annotation'}
    },
    dases                 => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'das'}
    },
    newsfilters           => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'newsfilter'}
    },
    sortables             => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'sortable'}
    },
    currentconfigs        => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'current_config'}
    },
    specieslists          => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'specieslist'}
    },
    uploads               => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'upload'}
    },
    urls                  => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'url'}
    },
    histories             => {
      'relationship'        => 'records',
      'condition'           => {'type' => 'history'}
    }
  ]
);

#############################
####                     ####
####    LOGIN METHODS    ####
####                     ####
#############################

sub activate_login {
  ## Activates the given login object after copying the information like name, organisation, country to the user and linking login object to the user object (does not save to the database afterwards)
  ## @param Login object to be linked an activated
  my ($self, $login) = @_;

  $login->copy_details_to_user($self);
  $login->activate;

  $self->add_logins([$login]);
}

sub get_local_login {
  ## Gets the local login object related to the user
  ## @return Login object if found
  return shift @{shift->find_logins('query' => ['type' => 'local'])};
}

##################################
####                          ####
####    MEMBERSHIP METHODS    ####
####                          ####
##################################

sub get_membership_object {
  ## Gets membership object related to a given group
  ## @param Group object or id of the group
  ## @param Hashref to go as arguments to find_memberships method after adding 'group_id' and 'limit' to it
  ## @return Membership object, if found, undef otherwise
  my ($self, $group, $params) = @_;
  my $group_id = ref $group ? $group->group_id : $group or return undef;
  push @{$params->{'query'} ||= []}, 'group_id', $group_id;
  return shift @{$self->find_memberships(%$params, 'limit' => 1)};
}

sub admin_memberships {
  ## Gets all the admin memberships for the user
  return shift->find_memberships('with_objects' => 'group', 'query' => ['level' => 'administrator', 'status' => 'active', 'member_status' => 'active', 'group.status' => 'active']);
}

sub nonadmin_memberships {
  ## Gets all the non-admin memberships for the user
  return shift->find_memberships('query' => ['level' => 'member', 'status' => 'active', 'member_status' => 'active']);
}

sub active_memberships {
  ## Gets all the active memberships (along with the related active groups) for the user
  return shift->find_memberships('with_objects' => 'group', 'query' => ['status' => 'active', 'member_status' => 'active', 'group.status' => 'active']);
}

sub create_membership_object {
  ## Creates a membership and group with the given details
  ## @param Hashref with keys as column (and relationships) for the membership object
  ## @return Memberhsip object with a new group (not yet saved to the database)
  my ($self, $params) = @_;

  return ($self->add_memberships([{
    'level'         => 'administrator',
    'user_id'       => $self->user_id,  # this prevents from calling save on the user object to actually link the objects
    'status'        => 'active',
    'member_status' => 'active',
    'group'         => {
      'status'        => 'active'
    },
    %{$params || {}}    
  }]))[0];
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
  my $membership = $self->get_membership_object($group, {'query' => ['status' => 'active', 'member_status' => 'active']});
  return !!$membership;
}

sub is_admin_of {
  ## Checks whether user is an admin of the given group
  ## @param Group rose object or id of the group
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $self->get_membership_object($group, {'query' => ['status' => 'active', 'member_status' => 'active', 'level' => 'administrator']});
  return !!$membership;
}

sub is_nonadminmember_of {
  ## Checks whether user is non-admin member of the given group
  ## @param Group rose object or id of the group
  ## @return 1 or undef accordingly
  my ($self, $group) = @_;
  my $membership = $self->get_membership_object($group, {'query' => ['status' => 'active', 'member_status' => 'active', 'level' => 'member']});
  return !!$membership;
}

#########################
####                 ####
#### RECORDS METHODS ####
####                 ####
#########################

sub create_record {
  ## Creates a user record of a given type (does not save it to the db)
  ## @param Type of the record
  ## @param Hashref of name value pair for columns of the new object (optional)
  my ($self, $type, $params) = @_;

  return ($self->add_records([{
    'user_id'       => $self->user_id,
    'type'          => $type,
    %{$params || {}}
  }]))[0];
}

1;
