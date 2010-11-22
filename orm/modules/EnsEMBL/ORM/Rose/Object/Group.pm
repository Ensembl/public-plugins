package EnsEMBL::ORM::Rose::Object::Group;

### NAME: EnsEMBL::ORM::Rose::Object::Group
### ORM class for the webgroup table in ensembl_web_user_db 

### STATUS: Under Development

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'webgroup',

  columns     => [
    webgroup_id     => {type => 'serial', primary_key => 1, not_null => 1},
    name              => {type => 'varchar', 'length' => '255'},
    blurb             => {type => 'text'},
    data              => {type => 'text'},
    type              => {type => 'enum', 'values' => [qw(open restricted private)]},
    status            => {type => 'enum', 'values' => [qw(active inactive)]},
    created_by        => {type => 'integer'},
    created_at        => {type => 'datetime'},
    modified_by       => {type => 'integer'},
    modified_at       => {type => 'datetime'},
  ],

  relationships => [
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