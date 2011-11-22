package EnsEMBL::ORM::Rose::DataMapValue;

## Name: EnsEMBL::ORM::Rose::DataMapValue
## Class representing the value provided to column type 'datamap'
## Each key in the datamap can be called as a method to this class

use strict;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::ORM::Rose::DataStructureValue);

use constant EXTRA_KEY => '--ens-datamap-key';

sub new {
  ## @overrides
  ## @constructor
  ## @exception ORMException::UnknownDataType if data is of any other than a hash 
  my ($class, $data, $object) = @_;
  my $self = $class->SUPER::new($data || {}, $object);
  throw exception('ORMException::UnknownDataType', 'Column of type datatype can only accept stringified hash values.') unless $self->isa('HASH');

  $self->{$self->EXTRA_KEY} = { 'object' => $object };

  return $self;
}

sub clone {
  ## @overrides
  ## Clones the hash blessed in the object after ignoring the extra hidden key
  my $self  = shift;
  my $extra = delete $self->{$self->EXTRA_KEY};
  my $clone = $self->SUPER::clone;

  $self->{$self->EXTRA_KEY} = $extra;

  return $clone;
}

sub has_key {
  ## Tells whether a key exists in the datamap or not
  ## @param String value of the key
  my ($self, $key) = @_;
  return $key ne $self->EXTRA_KEY && exists $self->{$key};
}

###
#
# Some private methods
#
###

sub _set_key {
  ## Sets the value of a key in the datamap
  ## Don't use this method, use the name of the key as method on the object
  ## @param String value of the key
  ## @param New value of the key
  ## @param Mutator method name
  ## @exception ORMException::InaccessibleKeyException If tried to set the EXTRA_KEY
  my ($self, $key, $value, $mutator_method) = @_;

  throw exception('ORMException::InaccessibleKeyException', 'Key to be set can not be the EXTRA_KEY') if $key eq $self->EXTRA_KEY;

  $self->{$key} = $value;
  $self->{$self->EXTRA_KEY}{'object'}->$mutator_method($self);
}

sub _get_key {
  ## Gets the value of a key in the datamap
  ## Don't use this method, use the name of the key as method on the object
  ## @param String value of the key
  ## @exception ORMException::InaccessibleKeyException if tried to get the EXTRA_KEY
  my ($self, $key) = @_;

  throw exception('ORMException::InaccessibleKeyException', 'Key to be set can not be the EXTRA_KEY') if $key eq $self->EXTRA_KEY;

  return $self->{$key};
}


1;