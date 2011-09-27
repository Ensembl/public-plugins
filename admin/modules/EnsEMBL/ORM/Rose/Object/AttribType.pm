package EnsEMBL::ORM::Rose::Object::AttribType;

### NAME: EnsEMBL::ORM::Rose::Object::AnalysisDescription
### ORM class for the master_attrib_type table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME        => 'production',
  TITLE_COLUMN        => 'code',
  INACTIVE_FLAG       => 'is_current',
  INACTIVE_FLAG_VALUE => '0',
};

## Define schema
__PACKAGE__->meta->setup(
  table         => 'master_attrib_type',

  columns       => [
    attrib_type_id  => {type => 'serial', primary_key => 1, not_null => 1},
    code            => {type => 'varchar', 'length' => 15,  not_null => 1},		
    name            => {type => 'varchar', 'length' => 255, not_null => 1},			
    description     => {type => 'text'},
    is_current      => {type => 'int', 'default' => 1,      not_null => 1}
  ],
  
  unique_key    => ['code'],
  
  relationships => [
    biotype         => {
      'type'        => 'one to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Biotype',
      'column_map'  => {'attrib_type_id' => 'attrib_type_id'},
    }
  ]
);

1;