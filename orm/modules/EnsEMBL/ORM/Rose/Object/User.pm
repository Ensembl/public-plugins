package EnsEMBL::ORM::Rose::Object::User;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the user table in ensembl_web_user_db 

### STATUS: Under Development

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'user',

  columns     => [
    user_id        => {type => 'serial', primary_key => 1, not_null => 1},
    name              => {type => 'varchar', 'length' => '255'},
    email             => {type => 'varchar', 'length' => '255'},
    salt              => {type => 'varchar', 'length' => '8'},
    password          => {type => 'varchar', 'length' => '64'},
    data              => {type => 'text'},
    organisation      => {type => 'text'},
    status            => {type => 'enum', 'values' => [qw(active pending suspended)]},
    created_by        => {type => 'integer'},
    created_at        => {type => 'datetime'},
    modified_by       => {type => 'integer'},
    modified_at       => {type => 'datetime'},
  ],

  relationships => [
#     record => {
#       'type'        => 'one to many',
#       'map_class'   => 'EnsEMBL::ORM::Rose::Object::UserRecord',
#     },
    membership => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'user_id' => 'user_id'},
    },
  ],
);

sub init_db { 
### Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('user'); 
}

1;