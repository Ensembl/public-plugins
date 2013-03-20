package EnsEMBL::ORM::Rose::Object::SubJob;

### NAME: EnsEMBL::ORM::Rose::Object::SubJob
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
  table       => 'sub_job',

  columns     => [
    ticket_id     => {type => 'int', length => 10, not_null => 1},
    sub_job_id    => {type => 'int', length => 10, not_null => 1, primary_key => 1},
    modified_at   => {type => 'timestamp', not_null => 1},
    job_division  => {type => 'blob', },
  ],

  relationships => [
    ticket  => {
      type       => 'many to one',
      class      => 'EnsEMBL::ORM::Rose::Object::Ticket',
      column_map => {'ticket_id' => 'ticket_id'},
    },
    result  => {
      type        => 'one to many',
      class       => 'EnsEMBL::ORM::Rose::Object::Result',
      column_map  => {'sub_job_id' => 'sub_job_id'},
    },
  ],
);  

1;
