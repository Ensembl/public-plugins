package EnsEMBL::Admin::Rose::Object::ChangelogSpecies;

### NAME: EnsEMBL::Admin::Rose::Object::ChangelogSpecies
### ORM class defining the changelog_species table in ensembl_production 

### STATUS: Stable 

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'changelog_species',

  columns     => [
    changelog_id      => {type => 'int', not_null => 1}, 
    species_id        => {type => 'int', not_null => 1}, 
  ],

  primary_key_columns => ['changelog_id', 'species_id'],

  relationships => [
    changelog => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Changelog',
      'column_map'  => {'changelog_id' => 'changelog_id'},
    },
    species => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::ProductionSpecies',
      'column_map'  => {'species_id' => 'species_id'},
      'manager_class' => 'EnsEMBL::Admin::Rose::Manager::ProductionSpecies',
    },
  ],
);

sub init_db { 
  ## Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('production'); 
}


1;
