package EnsEMBL::ORM::Rose::Object::Species;

### NAME: EnsEMBL::ORM::Rose::Object::Species
### ORM class for the species table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME        => 'production',
  TITLE_COLUMN        => 'web_name',
  INACTIVE_FLAG       => 'is_current',
  INACTIVE_FLAG_VALUE => '0',
};

## Define schema
__PACKAGE__->meta_setup(
  table       => 'species',

  columns     => [
    species_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_name           => {type => 'varchar', 'length' => 32 },
    common_name       => {type => 'varchar', 'length' => 32 },
    web_name          => {type => 'varchar', 'length' => 32 },
    is_current        => {type => 'integer'},
  ],

  relationships => [
    changelog => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::ChangelogSpecies',
    },
  ],
);

1;