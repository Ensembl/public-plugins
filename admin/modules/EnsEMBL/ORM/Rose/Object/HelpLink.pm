package EnsEMBL::ORM::Rose::Object::HelpLink;

### NAME: EnsEMBL::ORM::Rose::Object::HelpLink
### ORM class for the help_link table in ensembl_website

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

use constant ROSE_DB_NAME => 'website';

## Define schema
__PACKAGE__->meta->setup(
  table         => 'help_link',

  columns       => [
    help_link_id    => {type => 'serial', not_null => 1, primary_key => 1},
    page_url        => {type => 'text'},
    help_record_id  => {type => 'integer', 'length' => 11},
  ],
  
  title_column  => 'page_url',
  
  relationships => [
    help_record => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::HelpRecord',
      'column_map'  => {'help_record_id' => 'help_record_id'},
    }
  ]
);

1;