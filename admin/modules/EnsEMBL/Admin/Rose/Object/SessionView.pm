package EnsEMBL::Admin::Rose::Object::SessionView;

### NAME: EnsEMBL::Admin::Rose::Object::SessionView
### ORM class for the session_v view in healthcheck 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'session_v',

  columns     => [
    session_id  => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_release  => {type => 'integer'},
    host        => {type => 'varchar', 'length' => '255'},
    config      => {type => 'varchar', 'length' => '255'},
    start_time  => {type => 'datetime'},
    end_time    => {type => 'datetime'},
    duration    => {type => 'time'},
  ],
);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('healthcheck'); 
}

1;
