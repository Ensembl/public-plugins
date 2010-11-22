package EnsEMBL::ORM::Rose::Object::Membership;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the group_member table in ensembl_web_user_db 

### STATUS: Under Development

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'group_member',

  columns     => [
    group_member_id   => {type => 'serial', primary_key => 1, not_null => 1},
    webgroup_id       => {type => 'integer'},
    user_id           => {type => 'integer'},
    level             => {type => 'enum', 'values' => [qw(member administrator superuser)]},
    status            => {type => 'enum', 'values' => [qw(active inactive pending barred)]},
    member_status     => {type => 'enum', 'values' => [qw(active inactive pending barred)]},
    created_by        => {type => 'integer'},
    created_at        => {type => 'datetime'},
    modified_by       => {type => 'integer'},
    modified_at       => {type => 'datetime'},
  ],

  relationships => [
    user => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'  => {'user_id' => 'user_id'},
    },
    group => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Group',
      'column_map'  => {'webgroup_id' => 'webgroup_id'},
    },
  ],
);

sub init_db { 
### Set up the db connection
  EnsEMBL::ORM::Rose::DbConnection->new('user'); 
}

1;