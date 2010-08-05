package EnsEMBL::Admin::Rose::Object::Species;

### NAME: EnsEMBL::Admin::Rose::Object::Species
### ORM class for the species table in ensembl_website 

### STATUS: Stable 

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'species',

  columns     => [
    species_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    code              => {type => 'text'},
    name              => {type => 'text'},
    common_name       => {type => 'text'},
    dump_notes        => {type => 'text'},
    vega              => {type => 'enum', 'values' => [qw(N Y)]},
    online            => {type => 'enum', 'values' => [qw(N Y)]},
  ],

  relationships => [
    newsitem => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::Admin::Rose::Object::NewsSpecies',
    },
    release => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::Admin::Rose::Object::ReleaseSpecies',
    },
  ],
);

sub init_db { 
### Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}


1;
