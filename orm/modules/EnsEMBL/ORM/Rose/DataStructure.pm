package EnsEMBL::ORM::Rose::DataStructure;

## Name: EnsEMBL::ORM::Rose::DataStructure
## Class for column type 'datastructure' corresponding to Hash or Array

use strict;

use base qw(Rose::DB::Object::Metadata::Column::Text);

sub type {
  return 'datastructure';
}

1;