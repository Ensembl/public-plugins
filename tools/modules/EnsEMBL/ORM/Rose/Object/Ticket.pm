package EnsEMBL::ORM::Rose::Object::Ticket;

### NAME: EnsEMBL::ORM::Rose::Object::Ticket
### ORM class for the user table in test_ticket_db
 
### STATUS: Under Development

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

use constant {
  ROSE_DB_NAME => 'ticket',
};

## Define schema
__PACKAGE__->meta->setup(
  table       => 'ticket',

  columns     => [
    ticket_id     => {type => 'serial', primary_key => 1, not_null => 1},
    owner_id      => {type => 'varchar', length => 32, not_null => 1},
    job_type_id   => {type => 'tinyint', not_null=>1},
    ticket_name   => {type => 'varchar', length => 32, not_null => 1},
    ticket_desc   => {type => 'varchar', length =>160},
    created_at    => {type => 'timestamp', not_null => 1},
    modified_at   => {type => 'timestamp', not_null => 1},
    status        => {type => 'enum', 'values' => [qw( Queued Current Pending Running Parsing Completed Deleted Failed)], 'default' => 'Queued'},
    status_report => {type => 'text'},
    site_type     => {type => 'varchar', length => 32, not_null => 1},
  ],

  relationships => [
    analysis => {
      type        =>  'one to one',
      class       =>  'EnsEMBL::ORM::Rose::Object::Analysis',
      column_map  =>  {'ticket_id' => 'ticket_id'},
    },
    job => {
      type        => 'one to one',
      class       => 'EnsEMBL::ORM::Rose::Object::Job',  
      column_map  => {'job_type_id' => 'job_type_id'},
    },
    sub_job => {
      type        => 'one to many',
      class       => 'EnsEMBL::ORM::Rose::Object::SubJob',
      column_map  => {'ticket_id' => 'ticket_id'},
    },
    result => {
      type        => 'one to many',
      class       => 'EnsEMBL::ORM::Rose::Object::Result',
      column_map  => {'ticket_id' => 'ticket_id'},
    },
  ],

);

1;

