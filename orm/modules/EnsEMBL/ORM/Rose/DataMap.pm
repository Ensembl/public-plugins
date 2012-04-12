package EnsEMBL::ORM::Rose::DataMap;

### Name: EnsEMBL::ORM::Rose::DataMap
### Class for column type 'datamap' corresponding to single dimensional Hash

### An extra key 'virtual_columns' is required for meta->setup to make keys of a DataMap column accessible
### These keys then can be accessed by calling them (or their alias) as method names on the rose object itself just like other columns

### Reserved keys:
### Since keys for the datamap can be accessed as methods on the rose object, any method name that is reserved in the rose object should be provided an 'alias' name

### Example:
### package MyObject;
### use base qw(Rose::DB::Object);
### __PACKAGE__->meta->setup(
###   columns => [
###     'data'  => {'type' => 'datamap', 'trusted' => 1, 'not_null' => 1}
###   ],
###   virtual_columns => [
###     'name'  => {'column' => 'data'},
###     'db'    => {'column' => 'data', 'alias' => 'data_db'} # this column will be accessible by method 'data_db' not 'db'
###   ]
### );

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

1;