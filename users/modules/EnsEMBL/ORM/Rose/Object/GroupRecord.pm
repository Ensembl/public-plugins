package EnsEMBL::ORM::Rose::Object::GroupRecord;

### NAME: EnsEMBL::ORM::Rose::Object::GroupRecord
### ORM class for the group_record table in user database

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table           => 'group_record',
  columns         => [
    group_record_id => {'type' => 'serial',  'primary_key'  => 1,   'not_null' => 1 },
    webgroup_id     => {'type' => 'integer', 'length'       => 11,  'not_null' => 1, 'alias' => 'group_id' },
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
    group           => {
      'type'          => 'many to one',
      'class'         => 'EnsEMBL::ORM::Rose::Object::Group',
      'column_map'    => {'webgroup_id' => 'webgroup_id'},
    }
  ]
);

1;