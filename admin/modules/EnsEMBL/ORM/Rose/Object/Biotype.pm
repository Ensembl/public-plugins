package EnsEMBL::ORM::Rose::Object::Biotype;

### NAME: EnsEMBL::ORM::Rose::Object::Biotype
### ORM class for the biotype table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'biotype',

  columns     => [
    biotype_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    name              => {type => 'varchar', 'length' => 64 },
    is_current        => {type => 'integer'},
    is_dumped         => {type => 'integer'},
    object_type       => {type => 'enum', default => 'gene', not_null => 1, 'values' => [qw(gene transcript)]},
    db_type           => {type => 'set' , default => 'core', not_null => 1, 'values' => [qw(
                            cdna
                            core
                            coreexpressionatlas
                            coreexpressionest
                            coreexpressiongnf
                            funcgen
                            otherfeatures
                            rnaseq
                            variation
                            vega)]
    },
    attrib_type_id    => {type => 'integer'},
    description       => {type => 'text'}
  ],

  title_column          => 'name',
  inactive_flag_column  => 'is_current',

  relationships => [
    attrib_type       => {
      'type'        => 'one to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::AttribType',
      'column_map'  => {'attrib_type_id' => 'attrib_type_id'},
    }
  ]
);

1;