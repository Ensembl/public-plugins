package EnsEMBL::ORM::Rose::Object::UserRecord;

### NAME: EnsEMBL::ORM::Rose::Object::UserRecord
### ORM class for the webgroup table in user_record

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME => 'user',
  TABLE_NAME   => 'user_record'
};

## Define schema
__PACKAGE__->meta->setup(
  table         => __PACKAGE__->TABLE_NAME,
  columns       => [
    user_record_id    => {'type' => 'serial',  'primary_key' => 1, 'not_null' => 1},
    user_id           => {'type' => 'integer', 'length' => 11,     'not_null' => 1},
    type              => {'type' => 'varchar', 'length' => 255},
    data              => {'type' => 'datamap', 'trusted' => 1, 'keys' => [qw(url click name species)] }
  ],
  relationships => [
    user              => {
      'type'            => 'many to one',
      'class'           => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'      => {'user_id' => 'user_id'},
    }
  ]
);

1;