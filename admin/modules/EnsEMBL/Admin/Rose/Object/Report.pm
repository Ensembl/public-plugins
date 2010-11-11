package EnsEMBL::Admin::Rose::Object::Report;

### NAME: EnsEMBL::Admin::Rose::Object::Report
### ORM class for the report table in healthcheck 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'report',

  columns     => [
    report_id         => {type => 'serial', primary_key => 1, not_null => 1}, 
    first_session_id  => {type => 'int', 'length' => '10'},
    last_session_id   => {type => 'int', 'length' => '10'},
    species           => {type => 'varchar', 'length' => '255'},
    database_type     => {type => 'varchar', 'length' => '255'},
    database_name     => {type => 'varchar', 'length' => '255'},
    testcase          => {type => 'varchar', 'length' => '255'},
    text              => {type => 'text'},
    team_responsible  => {type => 'varchar', 'length' => '255'},
    result            => {type => 'enum', 'values' => [qw(PROBLEM CORRECT WARNING INFO)]},
    timestamp         => {type => 'datetime'},
    created           => {type => 'datetime'},
  ],

  relationships => [
    first_session => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Session',
      'column_map'  => {'first_session_id' => 'session_id'},
    },
    last_session => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Session',
      'column_map'  => {'last_session_id' => 'session_id'},
    },
    annotation => {
      'type'        => 'one to one',
      'class'       => 'EnsEMBL::Admin::Rose::Object::Annotation',
      'column_map'  => {'report_id' => 'report_id'},
    },
  ],
);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('healthcheck'); 
}

1;
