package EnsEMBL::ORM::Rose::Object::ProductionSpecies;

### NAME: EnsEMBL::ORM::Rose::Object::ProductionSpecies
### ORM class for the species table in ensembl_production 

### STATUS: Stable 

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'species',

  columns     => [
    species_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_name           => {type => 'text'},
    common_name       => {type => 'text'},
    web_name          => {type => 'text'},
    is_current        => {type => 'integer'},
  ],

  relationships => [
    changelog => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::ChangelogSpecies',
    },
  ],
);

sub init_db { 
### Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('production'); 
}


1;
