package EnsEMBL::Admin::Rose::Object::Session;

### NAME: EnsEMBL::Admin::Rose::Object::Session
### ORM class for the session table in healthcheck 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'session',

  columns     => [
    session_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_release        => {type => 'integer'},
    host              => {type => 'varchar', 'length' => '255'},
    config            => {type => 'text'},
  ],
);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('healthcheck'); 
}

1;
