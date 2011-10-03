package EnsEMBL::ORM::Rose::Object::Session;

### NAME: EnsEMBL::ORM::Rose::Object::Session
### ORM class for the session table in healthcheck 

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

use constant ROSE_DB_NAME => 'healthcheck';

## Define schema
__PACKAGE__->meta->setup(
  table         => 'session',

  columns       => [
    session_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_release        => {type => 'integer'},
    start_time        => {type => 'datetime'},
    end_time          => {type => 'datetime'},
    host              => {type => 'varchar', 'length' => '255'},
    config            => {type => 'text'}
  ],

  relationships => [
    report      => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Report',
      'column_map'  => {'session_id' => 'last_session_id'},
    },
  ]
);

1;