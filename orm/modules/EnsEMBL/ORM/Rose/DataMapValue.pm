package EnsEMBL::ORM::Rose::DataMapValue;

## Name: EnsEMBL::ORM::Rose::DataMapValue
## Class representing the value provided to column type 'datamap'

use strict;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::ORM::Rose::DataStructureValue);

sub new {
  ## @overrides
  ## @constructor
  ## @exception ORMException::UnknownDataType if data is of any other than a hash 
  my ($class, $data, $trusted) = @_;
  my $self = $class->SUPER::new($data || {}, $trusted);
  throw exception('ORMException::UnknownDataType', 'Column of type datatype can only accept stringified hash values.') unless $self->isa('HASH');

  return $self;
}

sub has_key {
  ## Tells whether a key exists in the datamap or not
  ## @param String value of the key
  my ($self, $key) = @_;
  return exists $self->{$key};
}

1;