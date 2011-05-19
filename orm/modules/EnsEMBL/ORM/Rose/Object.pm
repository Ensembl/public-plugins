package EnsEMBL::ORM::Rose::Object;

### NAME: EnsEMBL::Rose::ORM::Object
### Should be used only as a base class, and for a Rose-based object only

### DESCRIPTION:
### This module's children provide access to non-genomic databases, using the Rose::DB::Object suite

use strict;
use warnings;

use EnsEMBL::ORM::Rose::DbConnection;
use EnsEMBL::ORM::Rose::Manager;
use EnsEMBL::ORM::Rose::MetaData;

use base qw(Rose::DB::Object);

use constant {                        ## Override in child class
  ROSE_DB_NAME        => undef,       ## Name of the database connection as registered with Rose::DB
  TITLE_COLUMN        => '',          ## Column which contains the 'title' of the record (if any)
  INACTIVE_FLAG       => '',          ## Column that indicates that the row is to be considered deleted if its value is set as INACTIVE_FLAG_VALUE
  INACTIVE_FLAG_VALUE => '',          ## Value of the INACTIVE_FLAG

  LINKED_USERS_KEY    => '__linked_users'
};

__PACKAGE__->meta->error_mode('return'); ## When debugging, change from 'return' to 'carp'/'cluck'/'confess'/'croak' to produce the desired Carp behaviour

sub meta_setup {
  ## Wrapper around meta->setup method
  return shift->meta->setup(@_);
}

sub primary_key {
  ## Returns the name of the primary key (no composite keys)
  ## @return String
  return shift->meta->primary_key_column_names->[0];
}

sub init_db {
  ## Method called by Rose to creat connection to database
  ## Override ROSE_DB_NAME constant instead of this method
  EnsEMBL::ORM::Rose::DbConnection->new_or_cached(shift->ROSE_DB_NAME);
}

sub get_title {
  ## Returns the name of the object as defined by TITLE_COLUMN
  ## @return String
  my $self  = shift;
  my $title = $self->TITLE_COLUMN || $self->primary_key;
  
  return $self->$title;
}

sub get_primary_key_value {
  ## Gets the values of the primary key column
  my $self = shift;
  my $key  = $self->primary_key;
  return $key ? $self->$key || undef : undef;
}

sub is_trackable {
  ## Returns true if Object contains the trackable fields (created_by, modified_by etc)
  ## @return 0/1 accordingly
  return 0;
}

sub get_user {
  ## Gets the user linked to the object with the given column
  ## If user objects are required for multiple rows, use 'with_users' key in get_objects method to avoid multiple queries
  ## @param Column name
  ## @return User object if found, undef otherwise
  my ($self, $column_name) = @_;

  require EnsEMBL::ORM::Rose::Object::User; # Don't 'use' on top - circular dependency

  return $self->{$self->LINKED_USERS_KEY}{$column_name} if exists $self->{$self->LINKED_USERS_KEY} && exists $self->{$self->LINKED_USERS_KEY}{$column_name};

  return $self->{$self->LINKED_USERS_KEY}{$column_name} = $self->$column_name
    ? EnsEMBL::ORM::Rose::Manager->fetch_by_primary_key($self->$column_name, {'object_class' => 'EnsEMBL::ORM::Rose::Object::User'})
    : undef;
}

sub set_user {
  ## Sets the user_id to a given column for a given user object
  ## @param Column name
  ## @param User object
  my ($self, $column_name, $user) = @_;
  
  $user = undef unless UNIVERSAL::isa($user, 'EnsEMBL::ORM::Rose::Object::User');

  $self->$column_name($user ? $user->user_id : 0);
  $self->{$self->LINKED_USERS_KEY}{$column_name} = $user;
}

1;