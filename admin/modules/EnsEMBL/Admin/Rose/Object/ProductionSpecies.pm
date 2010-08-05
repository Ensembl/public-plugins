package EnsEMBL::Admin::Rose::Object::ProductionSpecies;

### NAME: EnsEMBL::Admin::Rose::Object::ProductionSpecies
### ORM class for the species table in ensembl_production 

### N.B. Not to be confused with Ensembl::Admin::Rose::Object::Species - 
### this module's name is intended to distinguish it from 
### ensembl_website.species, which has a different schema and
### different table relationships

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
      'map_class'   => 'EnsEMBL::Admin::Rose::Object::ChangelogSpecies',
    },
  ],
);

sub init_db { 
### Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('production'); 
}


1;
