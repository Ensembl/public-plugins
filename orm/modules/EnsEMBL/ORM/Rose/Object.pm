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
use EnsEMBL::Web::Exceptions;

use Rose::DB::Object::Helpers qw(as_tree forget_related has_loaded_related clone_and_reset);  ## Some extra methods that can be called on any child class object

use base qw(Rose::DB::Object);

use constant {
  ROSE_DB_NAME  => undef,         ## Name of the database connection as registered with Rose::DB (Override in child class)
  DEBUG_SQL     => undef,         ## Warns out all the mysql queries if flag is set '1'
};

__PACKAGE__->meta->error_mode('return');    ## When debugging, change from 'return' to 'carp'/'cluck'/'confess'/'croak' to produce the desired Carp behaviour
__PACKAGE__->meta->column_type_class(       ## Add extra column type(s)
  'datastructure' => 'EnsEMBL::ORM::Rose::DataStructure',
  'datamap'       => 'EnsEMBL::ORM::Rose::DataMap',
);

sub new {
  ## @overrides
  ## Provides default values to virtual columns after creating a new object
  my $self = shift->SUPER::new(@_);
  $_->default_exists and $self->virtual_column_value($_, $_->default) for $self->meta->virtual_columns;
  return $self;
}

sub save {
  ## @overrides
  ## Tries to save the object, but does not exit perl
  ## If any error occours, object->error can return the string values of the error
  ## @return Object if saved successfully, undef otherwise
  ## @overrides
  my $self = shift;
  $Rose::DB::Object::Debug = $self->DEBUG_SQL;
  eval {
    $self->SUPER::save(@_);
  };
}

sub meta_class {
  return 'EnsEMBL::ORM::Rose::MetaData';
}

sub include_in_lookup {
  ## Flag to control wether or not to include this object in manager's get_lookup method's return value
  ## @param Class name of the related rose object
  return 1;
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
  ## Returns the name of the object as defined as title_column in meta
  ## @return String
  my $self    = shift;
  my $column  = $self->meta->title_column || $self->primary_key;

  return $column ? $self->column_value($column) : '';
}

sub get_primary_key_value {
  ## Gets the value of the primary key column
  ## @return Value if primary key exists, undef otherwise
  my $self = shift;
  my $key  = $self->primary_key;
  return $key ? $self->column_value($key) : undef;
}

sub column_value {
  ## Gets/sets value for a given column
  ## It is recommended to use this method as it takes care of any column alias or datamap columns
  ## @param Column name OR Rose::DB::Object::Metadata::Column drived object OR datamap column name
  ## @param Value (only if setting the value)
  ## @return Column value when using as a getter
  my $self      = shift;
  my $col_name  = shift;
  my $meta      = $self->meta;

  my $column    = ref $col_name ? $col_name : $meta->column($col_name) || $meta->virtual_column($col_name) or throw exception('ORMException::UnknownColumnException', sprintf(q(No column with name '%s' found for %s), $col_name, ref $self));

  return $self->virtual_column_value($column, @_) if $column->isa('EnsEMBL::ORM::Rose::VirtualColumn');
  return $self->$_(@_) for (@_ ? $column->mutator_method_name : $column->accessor_method_name);
}

sub virtual_column_value {
  ## Gets/sets value of a virtual column
  ## @param Virtual column object or virtual column name
  ## @param Value (only if setting the value)
  ## @return Virtual column value when using as a getter
  my $self      = shift;
  my $col_name  = shift;

  my $column    = ref $col_name ? $col_name : $self->meta->virtual_column($col_name) or throw exception('ORMException::UnknownColumnException', sprintf(q(No virtual column with name '%s' found for %s), $col_name, ref $self));

  my $datamap   = $column->column;
  my $accessor  = $datamap->accessor_method_name;
  my $hash      = $self->$accessor;

  if (@_) {
    my $mutator       = $datamap->mutator_method_name;
    $hash->{$column}  = shift;
    $self->$mutator($hash);
  }

  return $hash->{$column};
}

sub relationship_value {
  ## Gets/sets value for a given relationship name
  ## It is recommended to use this method as it takes care of any relationship alias, and can set relationships if only foreign key values are provided
  ## @param Rose::DB::Object::Metadata::Relationship drived object, or relationship name
  ## @param Value (only if setting the value) - Can be a Rose object or a foreign key value, or a hashref containing method name key and value for singular relationships,
  ##   OR an arrayref of any of the options for multiple relationship
  ## @return Relationship value when using as a getter
  my $self      = shift;
  my $meta      = $self->meta;
  my $rel_name  = shift;
  my $relation  = ref $rel_name ? $rel_name : $meta->relationship($rel_name) or throw exception('ORMException::UnknownRelationException', sprintf(q(No relationship with name '%s' found for %s), $rel_name, ref $self));
  my $method    = $relation->method_name('get_set_on_save');
  if (@_) {
    my $value = ref $_[0] eq 'ARRAY' ? shift : [ shift ];
    if ($relation->is_singular) {
      $value = $value->[0] || undef; # no blank strings or zeros - zero will end up addind a new row to the related table
      unless (ref $value) { # if foreign key value
        my ($foreign_key)   = $relation->column_map;
        my $accessor_method = $meta->column_accessor_method_name($foreign_key);
        my $old_value       = $self->$accessor_method;
        return 1 if !$old_value && !$value || $old_value && $value && $old_value eq $value; # ignore if value not changed - this may prevent an extra SQL query on save
        $method             = $meta->column_mutator_method_name($foreign_key);
        $self->forget_related($relation->name);
      }
    }
    else {
      $value = [ grep {$_} @$value ]; # prevent adding a new row to related table by filtering out null value
    }
    return $self->$method($value);
  }
  else {
    return $self->$method;
  }
}

sub external_relationship_value {
  ## Get/set an external relationships value
  ## @param ExternalRelationship object or name
  ## @param Value to be set (optional) - Foreign rose object or value of the mapped column of the foreign rose object (or arrayref of either for '* to many' relation)
  ## @return Rose object
  my $self     = shift;
  my $meta     = $self->meta;
  my $relation = ref $_[0] ? shift : $meta->external_relationship(shift);
  my $manager  = 'EnsEMBL::ORM::Rose::Manager';
  my $key_name = $meta->EXTERNAL_RELATIONS_KEY_NAME;

  my ($r_name, $r_class, $r_is_singular, $r_map)  = map {$relation->$_} qw(name class is_singular column_map);
  my ($column_internal, $column_external)         = %$r_map;

  if (@_) { # Set value
    my $rose_value  = shift || []; # no '0' value
    $rose_value     = [$rose_value] unless ref $rose_value eq 'ARRAY';
    $rose_value     = $r_is_singular ? [shift @$rose_value] : $rose_value;

    # Get related rose object(s) if only foreign key value(s) provided
    if (@$rose_value && $rose_value->[0] && !UNIVERSAL::isa($rose_value->[0], $r_class)) {
      $rose_value = $manager->get_objects(
        'query'         => [$column_external, $rose_value],
        'object_class'  => $r_class
      ); #TODO - add error handling
    }

    # cache rose object
    $self->{$key_name}{$r_name} = $r_is_singular ? $rose_value->[0] : $rose_value;

    # save foreign key(s)
    $rose_value = [map {$_->$column_external} $r_is_singular ? $rose_value->[0] : @$rose_value];
    $self->$column_internal($r_is_singular ? $rose_value->[0] : $rose_value);
  }

  # return if already cached
  return $self->{$key_name}{$r_name} if exists $self->{$key_name}{$r_name};

  # otherwise get on from the db, cache and return
  my $foreign_keys = $self->$column_internal || [];
  $foreign_keys    = [$foreign_keys] unless ref $foreign_keys eq 'ARRAY';

  my $value = @$foreign_keys ? $manager->get_objects(
    'query'           => [$column_external, $foreign_keys],
    'object_class'    => $r_class,
    'active_only'     => 0,
  ) : [];

  return $self->{$key_name}{$r_name} = $r_is_singular ? shift @$value : $value;
}

sub virtual_relationship_value {
  ## Get/set a virtual relationships value
  ## @param VirtualRelationship object or name
  ## @param Value to be set (optional) - Rose object or foreign key value (or arrayref of either for multiple values)
  ## @return Arrayref related rose object
  my $self          = shift;
  my $relation_name = shift;

  my $virtual_rel   = ref $relation_name ? $relation_name : $self->meta->virtual_relationship($relation_name) or throw exception('ORMException::UnknownRelationshipException', sprintf(q(No virtual relationship with name '%s' found for %s), $relation_name, ref $self));
  my $actual_rel    = $virtual_rel->relationship;
  my $condition     = $virtual_rel->condition;
  my $all_values    = $self->relationship_value($actual_rel);

  if (@_) {
    my $values      = [];
    
    # filter aside all the values that do not categorise as this virtual column
    VALUE:
    foreach my $value (@$all_values) {
      $value->column_value($_) ne $condition->{$_} and push @$values, $value and next VALUE for keys %$condition;
    }

    # for all new values, add the condition values if value is an unsaved hashref
    foreach my $value (ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0]) {
      if (ref $value eq 'HASH') {
        $value = { %$value, %$condition };
      } else {
        $value->column_value($_, $condition->{$_}) for keys %$condition;
      }
      push @$values, $value;
    }
    $all_values = $self->relationship_value($actual_rel, $values);
  }

  my $values = [];
  VALUE:
  foreach my $value (@$all_values) {
    $value->column_value($_) ne $condition->{$_} and next VALUE for keys %$condition;
    push @$values, $value;
  }

  return $values;
}

sub field_value {
  ## Gets/sets value for a column, relationship, external relationship or a key saved in a datamap column
  ## Works as a combination of column_value, relationship_value and external_relationship_value
  ## @param Column/Relationship/ExternalRelationship name or object or a datamap key
  ## @param Optional - value as required by column_value, relationship_value or external_relationship_value methods
  my ($self, $field, @args) = @_;
  my $return;
  my $error;
  try {
    $return = $self->column_value($field, @args);
  } catch { try {
    $return = $self->relationship_value($field, @args);
  } catch { try {
    $return = $self->external_relationship_value($field, @args);
  } catch {
    $error  = 1;
  }}};

  return $return unless $error;

  throw exception('ORMException::UnknownFieldException', sprintf(q(No column, relationship or external relationship with name '%s' found for %s), $field, ref $self));
}

1;
