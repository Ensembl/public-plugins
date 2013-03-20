package EnsEMBL::ORM::Rose::Object::Analysis;

### NAME: EnsEMBL::ORM::Rose::Object::Analysis
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
  table       => 'analysis_object',

  columns     => [
    ticket_id   => {type => 'int', length => 10, primary_key => 1, not_null => 1},
    modified_at   => {type => 'timestamp', not_null => 1},
    object      => {type =>'blob', not_null =>1},
  ],
  
  relationships => [
    ticket  => {
      type       => 'one to one',
      class      => 'EnsEMBL::ORM::Rose::Object::Ticket',
      column_map => {'ticket_id' => 'ticket_id'},
    },
  ],

);

1;

