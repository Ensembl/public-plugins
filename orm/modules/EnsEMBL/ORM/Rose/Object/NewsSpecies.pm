package EnsEMBL::ORM::Rose::Object::NewsSpecies;

### NAME: EnsEMBL::ORM::Rose::Object::NewsSpecies
### ORM class defining the item_species table in ensembl_production 

### STATUS: Stable 

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'item_species',

  columns     => [
    news_item_id      => {type => 'int', not_null => 1}, 
    species_id        => {type => 'int', not_null => 1}, 
  ],

  primary_key_columns => ['news_item_id', 'species_id'],

  relationships => [
    newsitem => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::NewsItem',
      'column_map'  => {'news_item_id' => 'news_item_id'},
    },
    species => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Species',
      'column_map'  => {'species_id' => 'species_id'},
      'manager_class' => 'EnsEMBL::ORM::Rose::Manager::Species',
    },
  ],
);

sub init_db { 
  ## Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}


1;
