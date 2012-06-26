package EnsEMBL::ORM::Rose::Object::UserRecord;

### NAME: EnsEMBL::ORM::Rose::Object::UserRecord
### ORM class for the webgroup table in user_record

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table           => 'user_record',
  columns         => [
    user_record_id  => {'type' => 'serial',  'primary_key'  => 1,   'not_null' => 1 },
    user_id         => {'type' => 'integer', 'length'       => 11,  'not_null' => 1 },
    type            => {'type' => 'varchar', 'length'       => 255                  },
    data            => {'type' => 'datamap', 'trusted'      => 1                    }
  ],
  virtual_columns => [
    url             => {'column' => 'data'},
    name            => {'column' => 'data'},
    description     => {'column' => 'data'},
    click           => {'column' => 'data'},
    species         => {'column' => 'data'}
  ],
  relationships   => [
    user            => {
      'type'          => 'many to one',
      'class'         => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'    => {'user_id' => 'user_id'},
    }
  ]
);

1;