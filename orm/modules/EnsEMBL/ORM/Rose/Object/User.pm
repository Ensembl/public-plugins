package EnsEMBL::ORM::Rose::Object::User;

### NAME: EnsEMBL::ORM::Rose::Object::User
### ORM class for the user table in ensembl_web_user_db 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  user_db     => 1,

  table       => 'user',

  columns     => [
    user_id             => {type => 'serial', primary_key => 1, not_null => 1},
    name                => {type => 'varchar', 'length' => '255'},
    email               => {type => 'varchar', 'length' => '255'},
    salt                => {type => 'varchar', 'length' => '8'},
    password            => {type => 'varchar', 'length' => '64'},
    data                => {type => 'text'},
    organisation        => {type => 'text'},
    status              => {type => 'enum', 'values' => [qw(active pending suspended)]}
  ],

  title_column          => 'name',
  inactive_flag_column  => 'status',
  inactive_flag_value   => 'suspended',

  relationships => [
#     record => {
#       'type'        => 'one to many',
#       'class'       => 'EnsEMBL::ORM::Rose::Object::UserRecord',
#     },
    membership => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'user_id' => 'user_id'},
    }
  ]
);

1;