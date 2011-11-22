package EnsEMBL::ORM::Rose::DataMap;

### Name: EnsEMBL::ORM::Rose::DataMap
### Class for column type 'datamap' corresponding to single dimensional Hash

### An extra key 'keys' (or optionally 'alias_keys' for reserved key names) is required during meta->setup to initiate a DataMap column to include the allowed keys for the datamap
### These keys then can be accessed by calling them as method names on the value of this column

### Reserved keys:
### Since keys for the datamap can be accessed as methods on the value object, any method name that is already there in the DataMapValue thus can not be overwritten with a key-accessor method
### Thus the reserved keys are: new, clone, raw, has_key, to_string, _set_key and _get_key

use strict;

use EnsEMBL::ORM::Rose::DataMapValue;
use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::ORM::Rose::DataStructure);

sub value_class {
  ## @overrides
  return 'EnsEMBL::ORM::Rose::DataMapValue';
}

sub type {
  return 'datamap';
}

sub keys {
  ## Gets all the key names in the data map
  ## @exception ORMException::InvalidKeyNameException if key name contains invalid characters
  ## @exception ORMException::ReservedKeyNameException if key name provided is one among the reserved keys
  my ($self, $keys) = @_;

  if (caller eq 'Rose::Object') { # only if called by Rose::Object::init()
    $self->{'_ens_keys'} = [];
    foreach my $key (@$keys) {
      throw exception('ORMException::InvalidKeyNameException', 'Key name for datamap column type can only contain alphabets, numbers and underscore.') if $key !~ /[a-z0-9_]+/i;
      my $class = $self->value_class;
      throw exception('ORMException::ReservedKeyNameException', "$key is a reserved key name for datamap column type") if $class->can($key);
      no strict qw(refs);
      *{"${class}::${key}"} = sub {
        my $datamap = shift;
        $datamap->_set_key($key, shift, $self->mutator_method_name) if @_;
        return $datamap->_get_key($key);
      };
      push @{$self->{'_ens_keys'}}, $key;
    }
  }
  return [ map $_, @{$self->{'_ens_keys'} || []} ];
}

1;