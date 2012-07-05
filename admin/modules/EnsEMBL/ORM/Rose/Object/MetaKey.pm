package EnsEMBL::ORM::Rose::Object::MetaKey;

### NAME: EnsEMBL::ORM::Rose::Object::MetaKey
### ORM class for the metakey table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'meta_key',

  columns     => [
    meta_key_id       => {type => 'serial', primary_key => 1, not_null => 1}, 
    name              => {type => 'varchar', 'length' => 64 },
    is_current        => {type => 'integer', 'default' => 1 },
    is_optional       => {type => 'integer'},
    db_type           => {type => 'set', default => 'core', not_null => 1, 'values' => [qw(
                            cdna
                            core
                            funcgen
                            otherfeatures
                            presite
                            rnaseq
                            sangervega
                            variation
                            vega)]
    },
    description       => {type => 'text'}
  ],

  relationships => [
    species => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::MetaKeySpecies',
      'map_from'    => 'meta_key',
      'map_to'      => 'species',
    },
  ],

  title_column          => 'name',
  inactive_flag_column  => 'is_current'
);

1;