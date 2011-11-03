package EnsEMBL::ORM::Rose::DataStructure;

## Name: EnsEMBL::ORM::Rose::DataStructure
## Class for column type 'datastructure' corresponding to Hash or Array

## An extra boolean key 'trusted' is required (defaults to value being false) to initiate the column during setup (see &trusted below)

use strict;

use EnsEMBL::ORM::Rose::DataStructureValue;

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
  no strict qw(refs);
  my $get_method = $self->accessor_method_name;
  my $set_method = $self->mutator_method_name;
  *{"${class}::_ensorm_old_$_"} = \&{"${class}::${_}"} for $get_method, $set_method;

  # create new methods
  my $new_accessor_method = sub {
    # modified method calls the actual accessor method to get the stringfied hash/array, then converts into hashref/arrayref before returning it
    my $object = shift;
    return $self->value_class->new(map($object->$_, "_ensorm_old_$get_method"), $object, $self->trusted);
  };
  my $new_mutator_method  = sub {
    # modified method stringifies the hashref/arrayref before calling the actual mutator method
    my ($object, $value) = @_;
    $value = $self->value_class->new($value, $object, $self->trusted) unless UNIVERSAL::isa($value, $self->value_class);
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
    *{"${class}::${get_method}"} = $new_accessor_mutator_method;
  }
  else {
    *{"${class}::${get_method}"} = $new_accessor_method;
    *{"${class}::${set_method}"} = $new_mutator_method;
  }
  
  return $self;
}

1;