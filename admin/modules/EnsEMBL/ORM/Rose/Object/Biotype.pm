package EnsEMBL::ORM::Rose::Object::Biotype;

### NAME: EnsEMBL::ORM::Rose::Object::Biotype
### ORM class for the biotype table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME        => 'production',
  TITLE_COLUMN        => 'name',
  INACTIVE_FLAG       => 'is_current',
  INACTIVE_FLAG_VALUE => '0',
};

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
    description       => {type => 'text'}
  ],

#   relationships => [
#     changelog => {
#       'type'        => 'many to many',
#       'map_class'   => 'EnsEMBL::ORM::Rose::Object::ChangelogSpecies',
#       'map_to'      => 'changelog',
#       'map_from'    => 'species'
#     },
#   ],
);

1;