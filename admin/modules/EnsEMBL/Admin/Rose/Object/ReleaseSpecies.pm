package EnsEMBL::Admin::Rose::Object::ReleaseSpecies;

### NAME: EnsEMBL::Admin::Rose::Object::ReleaseSpecies
### ORM class defining the release_species table in ensembl_website 

### STATUS: Stable 

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'release_species',

  columns     => [
    release_id      => {type => 'int', not_null => 1}, 
    species_id      => {type => 'int', not_null => 1}, 
  ],

  primary_key_columns => ['release_id', 'species_id'],

  relationships => [
    release => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Release',
      'column_map'  => {'release_id' => 'release_id'},
      'manager_class' => 'EnsEMBL::Admin::Rose::Manager::Release',
    },
    species => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Species',
      'column_map'  => {'species_id' => 'species_id'},
      'manager_class' => 'EnsEMBL::Admin::Rose::Manager::Species',
    },
  ],
);

sub init_db { 
  ## Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}


1;
