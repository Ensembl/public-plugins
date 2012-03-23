package EnsEMBL::ORM::Rose::Manager;

### NAME: EnsEMBL::ORM::Rose::Manager
### Static class
### Sub-class of Rose::DB::Object::Manager

### DESCRIPTION:
### Parent class for all the rose object manager classes. Provides some generic data mining methods.

use strict;
use warnings;

use base qw(Rose::DB::Object::Manager);

sub get_objects {
  ## @overrides
  ## DO NOT OVERRIDE
  ## Wrapper to the manager's inbuilt get_objects method to provide 5 extra features:
  ##  - Getting all the externally related objects in a single method call, and a minimum possible number of sql queries
  ##  - Excludes the 'retired' rows, by default; includes if flag set false
  ##  - Warns all the sql queries done by rose if Object::DEBUG_SQL constant is set true
  ##  - Force returns an arrayref (no wantarray check)
  ##  - Error handling - TODO
  ## @param Hash, as accepted by default get_objects method (of Rose::DB::Object::Manager class) along with two extra keys as below:
  ##  - with_external_objects : ArrayRef of external relationship name as declared in meta->setup of the rose object
  ##  - active_only           : Flag, if on, will fetch active rows only (flag on by default)
  ## @return ArrayRef of objects, or undef if any error
  ## @example $manager->get_objects(
  ##   query                  => ['record_id' => 1, '!annotation.text' => undef],
  ##   with_objects           => ['annotation'],
  ##   with_external_objects  => ['created_by_user', 'annotation.created_by_user', 'annotation.modified_by_user'], #annotation is intermediate object, also included in with_objects
  ##   active_only            => 0
  ## )
  ## @note If any query param contains inactive_flag_column, set active_only => 0 always.
  ## @note If an externally related object is not directly related to the object, make sure the intermediate object is included in with_objects key.
  my ($self, %params) = shift->normalize_get_objects_args(@_);

  ######### This method is also called by Rose API sometimes. ###########
  ###            We don't want to override it for Rose                ###
  my $caller = caller;                                                ###
  return $self->SUPER::get_objects(%params) if $caller !~ /EnsEMBL/;  ###
  #########                   That's it!                      ###########
  
  my $with_e_objects  = delete $params{'with_external_objects'};
  $params{'debug'}    = 1 if ($params{'object_class'} || $self->object_class)->DEBUG_SQL;

  $self->add_active_only_query(\%params) if exists $params{'active_only'} ? delete $params{'active_only'} : 1;

  my $objects = $self->SUPER::get_objects(%params);

  # return objects if no external object needed, or if no object found
  return $objects unless $with_e_objects && @$with_e_objects && $objects && @$objects;

  # parse the with_external_objects string values
  my $external_rels = [];
  foreach my $with_e_object (@$with_e_objects) {
    $with_e_object = [ split /\./, $with_e_object ];
    push @$external_rels, {
      'external_relation'       => pop @$with_e_object,
      'intermediate_relations'  => $with_e_object
    };
  }

  # get foreign ids for getting all the externally related objects
  my $relation_cache    = {}; # cache the ExternalRelationship object to avoid multiple queries to metadata of the object directly related to external object
  my $required_objects  = {}; # example structure: {'EnsEMBL::ORM::Rose::Object::Record' => {'record_id' => {'102' => Rose object with record_id 102}}}
  my $internal_objects  = [];
  foreach my $object (@$objects) {
    foreach my $external_relation (@$external_rels) {
      my $relationship_name = $external_relation->{'external_relation'};
      foreach my $object_related_to_external_object (@{$self->_objects_related_to_external_object($object, [ map {$_} @{$external_relation->{'intermediate_relations'}} ])}) {
        my $relationship = $relation_cache->{ref $object_related_to_external_object}{$relationship_name} ||= $object_related_to_external_object->meta->external_relationship($relationship_name);
        my ($internal_column, $external_column) = %{$relationship->column_map};
        if (my $foreign_key = $object_related_to_external_object->$internal_column) {
          $required_objects->{$relationship->class}{$external_column}{$foreign_key} = 1;
          push @$internal_objects, $object_related_to_external_object, $relationship_name, [$relationship->class, $external_column, $foreign_key];
        }
      }
    }
  }

  # Get all the external objects with min possible queries
  while (my ($object_class, $column_values) = each %$required_objects) {
    while (my ($foreign_key_name, $foreign_keys_map) = each %$column_values) {
      $required_objects->{$object_class}{$foreign_key_name} = {map {$_->$foreign_key_name => $_} @{$self->get_objects(
        'object_class'  => $object_class,
        'query'         => [$foreign_key_name, [ keys %$foreign_keys_map ]],
        'active_only'   => 0
      )}};
    }
  }
  
  # save the external objects to the corresponding linked rose objects
  my $hash_key_name = $self->object_class->meta->EXTERNAL_RELATION_KEY_NAME;
  while (my $object_related_to_external_object = shift @$internal_objects) {
    my $relationship_name = shift @$internal_objects;
    my $path              = shift @$internal_objects;
    $object_related_to_external_object->{$hash_key_name}{$relationship_name} = $required_objects->{$path->[0]}{$path->[1]}{$path->[2]};
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
  ## @param Ref of Hash that goes to manager's get_objects_count method as arg
  ## @return int
  my ($self, $params) = @_;
  
  my $active_only     = exists $params->{'active_only'} ? delete $params->{'active_only'} : 1;
  $self->add_active_only_query($params) if $active_only;

  return $self->get_objects_count(%$params);
}

sub create_empty_object {
  ## Creates an new instance of the object class
  ## @param Rose::Object drived object (or object class) for reference (optional)
  ## @param Hash of name value pair for the params to construct the new object with
  ## @return Rose::Object drived object
  my ($self, $object, $params) = @_;

  $params = $object and $object = undef if ref $object eq 'HASH';
  return ($object ? ref $object || $object : $self->object_class)->new(%$params);
}

sub is_trackable {
  ## Returns true if Object contains the trackable fields (created_by, modified_by etc)
  ## @param Field name - column or relationship name or object - optional
  ## @return 0/1 accordingly
  return shift->object_class->meta->is_trackable(@_);
}

sub get_lookup {
  ## Gets lookups (name-value pairs) for all the object rows in the table
  ## Used for displaying options of dropdowns in forms for CRUD interface
  ## Skips the rows which are not active
  ## @param Object class string (optional - defaults to manager's default object_class)
  ## @return HashRefs with keys as primary key value and values as title value OR undef if an error
  ##  - key   : primary key's value
  ##  - title : value of the title column (Object->meta->title_column)
  my ($self, $object_class) = @_;

  my $default_object_class  = $self->object_class;
  $object_class           ||= $default_object_class;
  my $title_column_name     = $object_class->extract_column_name($object_class->meta->title_column);
  my $lookup                = {};

  for (@{$self->get_objects('object_class', $object_class) || []}) {
    next unless $_->include_in_lookup($default_object_class);
    my $key = $_->get_primary_key_value;
    $lookup->{$key} = $title_column_name ? $_->get_title : $key;
  }
  return $lookup;
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

sub add_active_only_query {
  ## Adds query params for fetching 'active only' rows from the db
  ## Override in the child class if required to provide some custom param in query key of args passed to get_objects
  ## @param HashRef of params being passed to get_objects methods after normalisation
  my ($self, $params) = @_;
  my $meta_class = ($params->{'object_class'} || $self->object_class)->meta;
  
  if (my $inactive_flag_column = $meta_class->inactive_flag_column) {
    $params->{'query'} ||= [];
    push @{$params->{'query'}}, "!$inactive_flag_column", $meta_class->inactive_flag_value;
  }
}

sub _objects_related_to_external_object {
  ## private helper method for get_objects method
  ## Goes in to the object's relationships, recursively to get the sub-object that is directly related to the required external object
  ## @return Array ref of all the intermediate objects, with the object  at the first index
  my ($self, $object, $relationships) = @_;
  
  return [] unless $object;
  unless (@$relationships) {
    $object = [ $object ] unless ref $object eq 'ARRAY';
    return $object;
  }

  if (ref $object eq 'ARRAY') {
    my $return          = [];
    my $relations_clone = [];
    $relations_clone    = [ map {$_} @$relationships ] and push @$return, @{$self->_objects_related_to_external_object($_, $relations_clone)} for @$object;
    return $return;
  }

  my $relationship    = shift @$relationships;
  my $sub_objects     = $object->$relationship;
  return [] unless $sub_objects;

  return $self->_objects_related_to_external_object($sub_objects, $relationships) if scalar @$relationships;

  $sub_objects = [ $sub_objects ] unless ref $sub_objects eq 'ARRAY';
  return $sub_objects;
}

1;
