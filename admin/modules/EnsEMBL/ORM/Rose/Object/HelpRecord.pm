package EnsEMBL::ORM::Rose::Object::HelpRecord;

### NAME: EnsEMBL::ORM::Rose::Object::HelpRecord
### ORM class for the help_record table in ensembl_website

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'website';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'help_record',

  columns     => [
    help_record_id => {type => 'serial',                    not_null => 1, primary_key => 1},
    type           => {type => 'varchar',  'length' => 255, not_null => 1},
    keyword        => {type => 'text'},
    data           => {type => 'datamap',  'trusted' => 1,  not_null => 1, 'keys' => [qw(question answer category word expanded meaning list_position length youtube_id title ensembl_object ensembl_action content)]},
    status         => {type => 'enum',     'values' => [qw(draft live dead)] },
    helpful        => {type => 'int',      'length' => 11},
    not_helpful    => {type => 'int',      'length' => 11}
  ]
);

1;