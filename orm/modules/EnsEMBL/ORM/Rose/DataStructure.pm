package EnsEMBL::ORM::Rose::DataStructure;

### Name: EnsEMBL::ORM::Rose::DataStructure
### Class for column type 'datastructure' for saving a Hash or Array

### An extra boolean key 'trusted' is required (defaults to value being false) to initiate the column during AnyRoseObject->meta->setup (see &trusted below)
### In the Metadata class, method modify_methods is called on this column object soon after setup of the Object class to modify existing accessor and mutator method (see &modify_methods below)

use strict;

use EnsEMBL::ORM::Rose::DataStructureValue;
use EnsEMBL::Web::Tools::MethodMaker qw(copy_method add_method);

use base qw(Rose::DB::Object::Metadata::Column::Text);

sub value_class {
  ## Returns the name of the class that will be instantiated to represent value of this column
  return 'EnsEMBL::ORM::Rose::DataStructureValue';
}

sub type {
  ## Returns the type of the column (polymorphic method)
  return 'datastructure';
}

sub trusted {
  ## Sets/Gets trusted flag on the column
  ## If the column value is trusted to be safely 'eval'able, keep this flag on
  ## @param Flag value
  ##  - If on, string value is 'eval'ed straight without any security validation before setting it as a value of this column (insure but faster)
  ##  - If off, value is set to this column after validation checks (secure but slower)
  my $self = shift;
  $self->{'_ens_trusted'} = shift @_ ? 1 : 0 if @_;
  return $self->{'_ens_trusted'} || 0;
}

sub modify_methods {
  ## @constructor
  ## modifies the get/set methods for a datastructure column
  my $self  = shift;
  my $class = $self->parent->class;

  # copy the old methods first
  my $get_method = $self->accessor_method_name;
  my $set_method = $self->mutator_method_name;
  copy_method($class, $_, "_ensorm_old_$_") for $get_method, $set_method;

  # create new methods
  my $new_accessor_method = sub {
    # modified accessor method calls the actual accessor method to get the stringfied hash/array, then converts into hashref/arrayref before returning it
    my $object = shift;
    return $self->value_class->new(map($object->$_, "_ensorm_old_$get_method"), $self->trusted);
  };
  my $new_mutator_method  = sub {
    # modified mutator method stringifies the hashref/arrayref and then calls the actual mutator method to save the stringified form
    my ($object, $value) = @_;
    $value = $self->value_class->new($value, $self->trusted) unless UNIVERSAL::isa($value, $self->value_class);
    map($object->$_("$value"), "_ensorm_old_$set_method");
    return &$new_accessor_method($object);
  };
  my $new_accessor_mutator_method = sub {
    # method that sets the value in arrayref/hashref form, if provided before returning the new set value, using the existing methods
    my $object = shift;
    return &$new_mutator_method($object, shift) if @_;
    return &$new_accessor_method($object);
  };

  # replace the old methods with new ones
  if ($get_method eq $set_method) {
    add_method($class, $get_method, $new_accessor_mutator_method);
  }
  else {
    add_method($class, $get_method, $new_accessor_method);
    add_method($class, $set_method, $new_mutator_method);
  }

  return $self;
}

1;