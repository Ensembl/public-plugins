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
    title             => {type => 'text'},
    content           => {type => 'text'},
    priority          => {type => 'integer'},
    status            => {type => 'enum', 'values' => [qw(declared handed_over postponed cancelled)]},
  ],

  relationships => [
    news_category => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::NewsCategory',
      'key_columns' => {'news_category_id' => 'news_category_id'},
    },
  ],

);

sub init_db { 
  ## Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}

1;
