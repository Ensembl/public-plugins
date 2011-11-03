package EnsEMBL::ORM::Rose::DataMap;

## Name: EnsEMBL::ORM::Rose::DataMap
## Class for column type 'datamap' corresponding to single dimensional Hash

## An extra key 'keys' is required during meta->setup to initiate a DataMap column to include the allowed keys for the datamap
## These keys then can be accessed by calling them as method names on the value of this column

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
  my ($self, $keys) = @_;

  if (caller eq 'Rose::Object') { # only if called by Rose::Object::init()
    $self->{'_ens_keys'} = [];
    foreach my $key (@$keys) {
      throw exception('ORMException::InvalidKeyNameException', 'Key name for datamap column type can only contain alphabets, numbers and underscore.') if $key !~ /[a-z0-9_]+/i;
      my $class = $self->value_class;
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