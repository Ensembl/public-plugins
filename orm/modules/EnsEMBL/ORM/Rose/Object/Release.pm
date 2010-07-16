package EnsEMBL::ORM::Rose::Object::Release;

### NAME: EnsEMBL::ORM::Rose::Object::Release
### ORM class for the ens_release table in ensembl_website 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'ens_release',
  columns     => [
    release_id  => {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1}, 
    number      => {'type' => 'varchar', 'length' => 5},
    date        => {'type' => 'date'},
    archive     => {'type' => 'varchar', 'length' => 7},
    online      => {'type' => 'enum', 'values' => [qw(N Y)]},
    mart        => {'type' => 'enum', 'values' => [qw(N Y)]},
  ],

  relationships => [
    newsitem => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::NewsItem',
      'column_map'  => {'release_id' => 'release_id'},
    },
    species => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::ReleaseSpecies',
    },
  ], 

);

=pod
=cut

sub init_db { 
  ## Set up the db connection  
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}

1;
