package EnsEMBL::ORM::Rose::Object::ChangelogSpecies;

### NAME: EnsEMBL::ORM::Rose::Object::ChangelogSpecies
### ORM class defining the changelog_species table in ensembl_production 

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'changelog_species',

  columns     => [
    changelog_id      => {type => 'int', not_null => 1, primary_key => 1}, 
    species_id        => {type => 'int', not_null => 1, primary_key => 1}, 
  ],

  relationships => [
    changelog => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Changelog',
      'column_map'  => {'changelog_id' => 'changelog_id'},
    },
    species => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Species',
      'column_map'  => {'species_id' => 'species_id'}
    },
  ],
);

1;