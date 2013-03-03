package EnsEMBL::ORM::Rose::Object::Job;

### NAME: EnsEMBL::ORM::Rose::Object::Job
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
  table       => 'job_type',

  columns     => [
    job_type_id => {type => 'tinyint', primary_key => 1, not_null=>1},
    job_type    => {type => 'varchar', length => 10, not_null => 1},
    job_name    => {type => 'varchar', length => 32, not_null => 1},
  ],

  relationships => [
    ticket => {
      type        => 'one to one',
      class       => 'EnsEMBL::ORM::Rose::Object::Ticket', 
      column_map  => {'job_type_id' => 'job_type_id'},
    },
  ],
);

1;

