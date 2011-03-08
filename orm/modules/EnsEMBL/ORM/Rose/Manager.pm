package EnsEMBL::ORM::Rose::Manager;

### NAME: EnsEMBL::ORM::Rose::Manager
### Static class
### Sub-class of Rose::DB::Object::Manager
### Contains some generic methods for data-mining, update and delete on the table and it's related table

### DESCRIPTION:
### Parent class for all the rose object manager classes. Provides some generic data mining methods.

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::User;

use base qw(Rose::DB::Object::Manager);

use constant DEBUG_SQL => 0;

sub get_objects {
  ## @overrides
  ## Wrapper to the manager's inbuilt get_objects method to provide 3 extra features:
  ##  - Getting all the linked users from the user table in single method call
  ##  - Excludes the 'retired' rows, by default; includes if flag set false
  ##  - Warns all the sql queries done by rose if DEBUG_SQL constant is set true
  ## @param Hash, as accepted by default get_objects method along with two extra keys as below:
  ##  - with_users  : ArrayRef of columns that contain user ids as foreign keys
  ##  - active_only : Flag, if on, will fetch active rows only (flag on by default)
  ## @return ArrayRef of objects, or undef if any error
  ## @example $manager->get_objects(
  ##   query        => ['record.record_id' => 1],
  ##   with_objects => ['record'],
  ##   with_users   => ['created_by', 'record.created_by', 'record.modified_by'],
  ##   active_only  => 0
  ## )
  my ($self, %params) = @_;
  my $with_users      = delete $params{'with_users'};
  my $active_only     = exists $params{'active_only'} ? delete $params{'active_only'} : 1;

  $params{'debug'}    = 1 if $self->DEBUG_SQL;
  $params{'query'}  ||= [] and push @{$params{'query'}}, @{$self->_query_active_only->{'query'} || []} if $active_only;

  my $objects         = $self->SUPER::get_objects(%params);
  
  # return objects if no user needed, or if no object found
  return $objects unless $with_users && @$with_users && $objects && @$objects;

  my $user_rels = [];
  foreach my $with_user (@$with_users) {
    $with_user = [ split /\./, $with_user ];
    push @$user_rels, {
      'column'    => pop @{$with_user},
      'relations' => $with_user
    };
  }

  my $all_ids = {};
  foreach my $object (@$objects) {
    foreach my $user_relation (@$user_rels) {
      my $column = $user_relation->{'column'};
      $_ = $_->$column and $_ and $all_ids->{$_} = 1 for @{$self->_objects_related_to_user($object, [ map {$_} @{$user_relation->{'relations'}} ])};
    }
  }

  if (scalar keys %$all_ids) {

    my $users = { map {$_->user_id => $_} @{$self->get_objects(
      'object_class'  => 'EnsEMBL::ORM::Rose::Object::User',
      'query'         => ['user_id', [ keys %$all_ids ]]
    )}};
    
    foreach my $object (@$objects) {
      foreach my $user_relation (@$user_rels) {
        my $column = $user_relation->{'column'};
        $_->{$self->object_class->LINKED_USERS_KEY}{$column} = $_->$column ? $users->{$_->$column} : undef for @{$self->_objects_related_to_user($object, [ map {$_} @{$user_relation->{'relations'}} ])};
      }
    }
  }
  return $objects;
}

sub object_class {
  ## Returns the corresponding object class - defaults to the one in same namespace
  ## Override in the child classes, if required
  (my $self = shift) =~ s/Rose::Manager/Rose::Object/;
  return $self;
}

sub primary_keys {
  ## Returns all the primary keys for the object table
  ## @param  Rose::Object drived object for reference
  ## @return ArrayRef of Strings
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->create_empty_object)->meta->primary_key_column_names;
}

sub primary_key {
  ## Returns the primary key for the object table (use this if no composite primary keys)
  ## @param  Rose::Object drived object for reference
  ## @return String
  my ($self, $object) = @_;
  return $self->primary_keys($object)->[0];
}

sub fetch {
  ## Alias of get_objects, but needs HashRef as argument instead of Hash
  ## @param HashRef of params for get_objects
  my ($self, $params) = @_;
  
  return $self->get_objects(%$params);
}

sub fetch_by_primary_key {
  ## Wrapper around fetch_by_primary_keys for single value
  ## Does NOT work for composite primary keys
  ## @param Primary key value (string)
  ## @param (Optional) Hashref of extra parameters that are passed to get_objects methods
  ## @return Rose::Object drived object OR undef if any error
  my ($self, $id, $params) = @_;

  my $return = $self->fetch_by_primary_keys([$id], $params);
  return $return ? $return->[0] : undef;
}

sub fetch_by_primary_keys {
  ## Gets all the objects with the given primary keys
  ## Does NOT work for composite primary keys
  ## @param ArrayRef containing values of primary key
  ## @param (Optional) Hashref of extra parameters that are passed to get_objects methods
  ## @return ArrayRef of Rose::Object drived objects OR undef if any error
  my ($self, $ids, $params) = @_;

  $params->{'query'} ||= [];
  push @{$params->{'query'}}, $self->primary_key, $ids;

  return @$ids ? $self->get_objects(%$params) : undef;
}

sub fetch_by_page {
  ## Returns objects from the database according to pagination parameters
  ## @param Number of objects to be returned
  ## @param Page number
  ## @return ArrayRef of Rose::Object drived objects OR undef if any error
  my ($self, $pagination, $page) = @_;

  return $self->get_objects(
    per_page => $pagination,
    page     => $page
  );
}

sub count {
  ## Gives the number of all the active rows in the table
  ## @return int
  my $self = shift;

  return $self->get_objects_count(%{$self->_query_active_only});
}

sub create_empty_object {
  ## Creates an new instance of the object class
  ## @return Rose::Object drived object
  my $self = shift;

  return $self->object_class->new;
}

sub get_lookup {
  ## Gets lookups (name-value pairs) for all the object rows in the table
  ## Used for displaying options of dropdowns in forms for CRUD interface
  ## Skips the rows which are not active
  ## @return HashRefs with keys as primary key value and values as title value OR undef if an error
  ##  - key   : primary key's value
  ##  - title : value of column as declared at Object::TITLE_COLUMN
  my $self = shift;
  
  my $key   = $self->primary_key;
  my $title = $self->object_class->TITLE_COLUMN;

  my $objects = $self->get_objects(
    'select'      => $title ? [ $key, $title ] : $key,
    'active_only' => 1,
  );
  
  return unless $objects;

  return { map {$_->$key => $title ? $_->$title : $_->$key} @$objects };
}

sub get_columns {
  ## Returns all column objects for a table
  ## @param  Rose::Object drived object for reference (optional)
  ## @return ArrayRef of Rose::*::Column objects
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->create_empty_object)->meta->columns;
}

sub get_column_names {
  ## Returns all column's name for a table
  ## @param  Rose::Object drived object for reference
  ## @return ArrayRef of strings
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->create_empty_object)->meta->column_names;
}

sub _query_active_only {
  ## private helper method
  my $self = shift;

  return $self->object_class->INACTIVE_FLAG ? {query => ['!'.$self->object_class->INACTIVE_FLAG => $self->object_class->INACTIVE_FLAG_VALUE]} : {};
}

sub _objects_related_to_user {
  ## private helper method for get_objects method
  ## Goes down to the object's relationships, recursively to get the sub-object that is directly related to user
  my ($self, $object, $relationships) = @_;
  
  return [] unless $object;
  unless (@$relationships) {
    $object = [ $object ] unless ref $object eq 'ARRAY';
    return $object;
  }

  if (ref $object eq 'ARRAY') {
    my $return = [];
    my $relations_clone = [];
    $relations_clone = [ map {$_} @$relationships ] and push @$return, @{$self->_objects_related_to_user($_, $relations_clone)} for @$object;
    return $return;
  }

  my $relationship    = shift @$relationships;
  my $sub_objects     = $object->$relationship;
  return [] unless $sub_objects;

  return $self->_objects_related_to_user($sub_objects, $relationships) if scalar @$relationships;

  $sub_objects = [ $sub_objects ] unless ref $sub_objects eq 'ARRAY';
  return $sub_objects;
}

1;