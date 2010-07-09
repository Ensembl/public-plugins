package EnsEMBL::ORM::Rose::Object::NewsItem;

### NAME: EnsEMBL::ORM::Rose::Object::NewsItem
### ORM class for the news_item table in ensembl_website 

### STATUS: Under Development

### TODO - add relationships to Species and Release

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'news_item',

  columns     => [
    news_item_id      => {type => 'serial', primary_key => 1, not_null => 1}, 
    news_category_id  => {type => 'integer'},
    release_id        => {type => 'integer'},
    title             => {type => 'varchar'},
    content           => {type => 'text'},
    priority          => {type => 'integer'},
    status            => {type => 'enum', 'values' => [qw(draft published dead)]},
    created_by        => {type => 'integer'},
    created_at        => {type => 'datetime'},
    modified_by       => {type => 'integer'},
    modified_at       => {type => 'datetime'},
    declaration       => {type => 'text'},
    notes             => {type => 'text'},
    dec_status        => {type => 'enum', 'values' => [qw(declared handed_over postponed cancelled)]},
    data              => {type => 'text'},
    news_done         => {type => 'enum', 'values' => [qw(N Y X)]},
  ],

  relationships => [
    category => {
      'type'          => 'many to one',
      'class'         => 'EnsEMBL::ORM::Rose::Object::NewsCategory',
      'column_map'    => {'news_category_id' => 'news_category_id'},
    },
    ens_release => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Release',
      'column_map'  => {'release_id' => 'release_id'},
    },
    species => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::NewsSpecies',
    },
  ],

);

sub init_db { 
  ## Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}

1;
