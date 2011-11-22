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

use Rose::DB::Object::Helpers qw(as_tree forget_related has_loaded_related clone_and_reset);  ## Some extra methods that can be called on any child class object

use base qw(Rose::DB::Object);

use constant {
  ROSE_DB_NAME  => undef,         ## Name of the database connection as registered with Rose::DB (Override in child class)
  DEBUG_SQL     => undef,         ## Warns out all the mysql queries is flag is set '1'
};

__PACKAGE__->meta->error_mode('return');    ## When debugging, change from 'return' to 'carp'/'cluck'/'confess'/'croak' to produce the desired Carp behaviour
__PACKAGE__->meta->column_type_class(       ## Add extra column type(s)
  'datastructure' => 'EnsEMBL::ORM::Rose::DataStructure',
  'datamap'       => 'EnsEMBL::ORM::Rose::DataMap',
);

sub save {
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
  my $self  = shift;
  my $title = $self->meta->title_column || $self->primary_key;
  
  return $self->$title;
}

sub get_primary_key_value {
  ## Gets the values of the primary key column
  my $self = shift;
  my $key  = $self->primary_key;
  return $key ? $self->$key || undef : undef;
}

sub external_relationship {
  ## Get/set an external relationships value
  ## @param ExternalRelationship object
  ## @param Value to be set (optional) - Foreign rose object or value of the mapped column of the foreign rose object (or arrayref of either for '* to many' relation)
  ## @return Rose object
  my $self     = shift;
  my $relation = shift;
  my $manager  = 'EnsEMBL::ORM::Rose::Manager';
  my $key_name = $self->meta->EXTERNAL_RELATION_KEY_NAME;

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

1;
