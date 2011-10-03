package EnsEMBL::ORM::Rose::Object::MetaKeySpecies;

### NAME: EnsEMBL::ORM::Rose::Object::MetaKeySpecies
### ORM class defining the meta_key_species table in ensembl_production 

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'meta_key_species',

  columns     => [
    meta_key_id      => {type => 'int', not_null => 1, primary_key => 1}, 
    species_id       => {type => 'int', not_null => 1, primary_key => 1}, 
  ],

  relationships => [
    meta_key => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::MetaKey',
      'column_map'  => {'meta_key_id' => 'meta_key_id'},
    },
    species => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Species',
      'column_map'  => {'species_id' => 'species_id'}
    },
  ],
);

1;