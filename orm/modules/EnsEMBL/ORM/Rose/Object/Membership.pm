package EnsEMBL::ORM::Rose::Object::Membership;

### NAME: EnsEMBL::ORM::Rose::Object::Membership
### ORM class for the group_member table in ensembl_web_user_db 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME        => 'user',
  TITLE_COLUMN        => '',
  INACTIVE_FLAG       => 'member_status',
  INACTIVE_FLAG_VALUE => 'removed'
};

## Define schema
__PACKAGE__->meta->setup(
  user_db     => 1,

  table       => 'group_member',

  columns     => [
    group_member_id   => {type => 'serial', primary_key => 1, not_null => 1},
    webgroup_id       => {type => 'integer'},
    user_id           => {type => 'integer'},
    level             => {type => 'enum', 'values' => [qw(member administrator superuser)]},
    status            => {type => 'enum', 'values' => [qw(active inactive pending barred)]}, ## TODO - what is this?
    member_status     => {type => 'enum', 'values' => [qw(active inactive pending barred removed)]}, ##TODO - add removed to db
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
    }
  ]
);

1;