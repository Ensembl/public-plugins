package EnsEMBL::ORM::Rose::Object::SpeciesAlias;

### NAME: EnsEMBL::ORM::Rose::Object::SpeciesAlias
### ORM class for the species_alias table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'species_alias',

  columns     => [
    species_alias_id  => {type => 'serial', primary_key => 1, not_null => 1},
    species_id        => {type => 'integer',                  not_null => 1},
    alias             => {type => 'varchar', 'length' => 255, not_null => 1},
    is_current        => {type => 'integer'},
  ],

  title_column          => 'alias',

  inactive_flag_column  => 'is_current',

  relationships         => [
    species         => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Species',
      'column_map'  => {'species_id' => 'species_id'}
    }
  ],
);

1;