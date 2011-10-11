package EnsEMBL::ORM::Rose::Object::Group;

### NAME: EnsEMBL::ORM::Rose::Object::Group
### ORM class for the webgroup table in ensembl_web_user_db 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table                 => 'webgroup',

  columns               => [
    webgroup_id   => {type => 'serial', primary_key => 1, not_null => 1},
    name          => {type => 'varchar', 'length' => '255'},
    blurb         => {type => 'text'},
    data          => {type => 'text'},
    type          => {type => 'enum', 'values' => [qw(open restricted private)]},
    status        => {type => 'enum', 'values' => [qw(active inactive)]}
  ],

  title_column          => 'name',
  inactive_flag_column  => 'status',
  inactive_flag_value   => 'inactive',

  relationships   => [
    memberships     => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Membership',
      'column_map'  => {'webgroup_id' => 'webgroup_id'},
    }
  ]
);

1;