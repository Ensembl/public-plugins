package EnsEMBL::ORM::Rose::Manager;

### NAME: EnsEMBL::ORM::Rose::Manager
### Static class
### Sub-class of Rose::DB::Object::Manager
### Contains some generic methods for data-mining, update and delete on the table and it's related table

### DESCRIPTION:
### Parent class for all the rose object manager classes. Provides some generic data mining methods.
### Can be used directly, without the child classes, provided object_class parameter is given while making a method call.

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::User;

use base qw(Rose::DB::Object::Manager);

use constant DEBUG_SQL => 0;

sub get_objects {
  ## @overrides
  ## DO NOT OVERRIDE
  ## Wrapper to the manager's inbuilt get_objects method to provide 3 extra features:
  ##  - Getting all the linked users from the user table in single method call
  ##  - Excludes the 'retired' rows, by default; includes if flag set false
  ##  - Warns all the sql queries done by rose if DEBUG_SQL constant is set true
  ## @param Hash, as accepted by default get_objects method (of Rose::DB::Object::Manager class) along with two extra keys as below:
  ##  - with_users  : ArrayRef of columns that contain user ids as foreign keys
  ##  - active_only : Flag, if on, will fetch active rows only (flag on by default)
  ## @return ArrayRef of objects, or undef if any error
  ## @example $manager->get_objects(
  ##   query        => ['record.record_id' => 1],
  ##   with_objects => ['record'],
  ##   with_users   => ['created_by', 'record.created_by', 'record.modified_by'],
  ##   active_only  => 0
  ## )
  ## IMP: If any query param contains INACTIVE_FLAG column, set active_only => 0 always.
  my ($self, %params) = shift->normalize_get_objects_args(@_);

  ######### This method is also called by Rose API sometimes. ###########
  ###            We don't want to override it for Rose                ###
  my $caller = caller;                                                ###
  return $self->SUPER::get_objects(%params) if $caller !~ /EnsEMBL/;  ###
  #########                   That's it!                      ###########
  
  my $with_users      = delete $params{'with_users'};
  my $active_only     = exists $params{'active_only'} ? delete $params{'active_only'} : 1;

  $params{'debug'}    = 1 if $self->DEBUG_SQL;

  $self->_add_active_only_query(\%params) if $active_only;

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
      'query'         => ['user_id', [ keys %$all_ids ]],
      'active_only'   => 0
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
  warn "Method object_class can not be called on base Manager class. Either provide 'object_class' as a key in the argument hash of the required method or call this method on Manager drived class." and return if $_[0] eq __PACKAGE__;
  (my $object_class = shift) =~ s/Rose::Manager/Rose::Object/;
  return $object_class;
}

sub primary_keys {
  ## Returns all the primary keys for the object table
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return ArrayRef of Strings
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->object_class)->meta->primary_key_column_names;
}

sub primary_key {
  ## Returns the primary key for the object table (use this if no composite primary keys)
  ## @param Rose::Object drived object (or object class) for reference (optional)
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
  push @{$params->{'query'}}, $self->primary_key($params->{'object_class'}), $ids;

  return @$ids ? $self->get_objects(%$params) : undef;
}

sub fetch_by_page {
  ## Returns objects from the database according to pagination parameters
  ## @param Number of objects to be returned
  ## @param Page number
  ## @param HashRef of extra params for get_objects
  ## @return ArrayRef of Rose::Object drived objects OR undef if any error
  my ($self, $pagination, $page, $params) = @_;
  
  $params ||= {};
  if ($pagination) {
    $params->{'per_page'} = $pagination;
    $params->{'page'}     = $page;
  }

  return $self->get_objects(%$params);
}

sub count {
  ## Gives the number of all the active rows in the table
  ## @param HashRef of Hash that goes to manager's get_objects_count method as arg
  ## @return int
  my ($self, $params) = @_;
  
  my $active_only     = exists $params->{'active_only'} ? delete $params->{'active_only'} : 1;
  $self->_add_active_only_query($params) if $active_only;

  return $self->get_objects_count(%$params);
}

sub create_empty_object {
  ## Creates an new instance of the object class
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return Rose::Object drived object
  my ($self, $object) = @_;

  my $object_class = $object ? (ref $object ? ref $object : $object) : $self->object_class;

  return $object_class->new;
}

sub is_trackable {
  ## Returns true if Object contains the trackable fields (created_by, modified_by etc)
  ## @return 0/1 accordingly
  return shift->object_class->is_trackable;
}

sub get_lookup {
  ## Gets lookups (name-value pairs) for all the object rows in the table
  ## Used for displaying options of dropdowns in forms for CRUD interface
  ## Skips the rows which are not active
  ## @param Object class string (optional - defaults to manager's default object_class)
  ## @return HashRefs with keys as primary key value and values as title value OR undef if an error
  ##  - key   : primary key's value
  ##  - title : value of column as declared at Object::TITLE_COLUMN
  my ($self, $object_class) = @_;
  
  $object_class ||= $self->object_class;

  my $key   = $object_class->primary_key;
  my $title = $object_class->TITLE_COLUMN;

  my $objects = $self->get_objects(
    'object_class'  => $object_class,
    'select'        => $title ? [ $key, $title ] : $key,
    'sort_by'       => $title || $key,
  );
  
  return unless $objects;

  return { map {$_->$key => $title ? $_->$title : $_->$key} @$objects };
}

sub get_columns {
  ## Returns all column objects for a table
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return ArrayRef of Rose::*::Column objects
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->object_class)->meta->columns;
}

sub get_column_names {
  ## Returns all column's name for a table
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return ArrayRef of strings
  my ($self, $object) = @_;

  return my $arrayref = ($object || $self->object_class)->meta->column_names;
}

sub get_relationships {
  ## Returns all relationships for an object
  ## @param Relationship type string (eg. 'many to many', 'one to one' etc) - Optional - will give all relationships if not provided
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return ArrayRef of Rose::DB::Object::Metadata::Relationship objects
  my ($self, $relation, $object) = @_;

  $relation and ref $relation and $object = $relation and $relation = undef;
  $object ||= $self->object_class;

  my $relations = [];
  (!$relation || $relation && $_->type eq $relation) and push @$relations, $_ for @{$object->meta->relationships};
  return $relations;
}

sub get_relationship_names {
  ## Returns all relationships' name for an object
  ## @param Relationship type string (eg. 'many to many', 'one to one' etc) - Optional - will give all relationships if not provided
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @return ArrayRef of strings
  my $self = shift;
  
  return [ map {$_->name} @{$self->get_relationships(@_)} ];
}

sub _add_active_only_query {
  ## private helper method
  my ($self, $params) = @_;
  my $object_class = $params->{'object_class'} || $self->object_class;
  
  if ($object_class->INACTIVE_FLAG) {
    $params->{'query'} ||= [];
    push @{$params->{'query'}}, '!'.$object_class->INACTIVE_FLAG, $object_class->INACTIVE_FLAG_VALUE;
  }
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
