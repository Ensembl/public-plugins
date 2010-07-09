package EnsEMBL::ORM::Rose::Object::NewsCategory;

### NAME: EnsEMBL::ORM::Rose::Object::NewsCategory
### ORM class for the news_category table in ensembl_website 

### STATUS: Stable

### DESCRIPTION:
### news_category is a simple lookup table used by news_item

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'news_category',
  columns     => [
    news_category_id  => {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1}, 
    code              => {'type' => 'varchar', 'length' => 10},
    name              => {'type' => 'varchar', 'length' => 64},
    priority          => {'type' => 'integer'},
  ],

  relationships => [
    newsitem => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::Data::NewsItem',
      'column_map'  => {'news_category_id' => 'news_category_id'},
    },
  ], 
);

sub init_db { 
  ## Set up the db connection  
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}

1;
