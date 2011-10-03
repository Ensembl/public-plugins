package EnsEMBL::ORM::Rose::Object::Annotation;

### NAME: EnsEMBL::ORM::Rose::Object::Annotation
### ORM class for the annotation table in healthcheck 

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'healthcheck';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'annotation',

  columns     => [
    annotation_id => {type => 'serial', primary_key => 1, not_null => 1}, 
    report_id     => {type => 'integer'},
    action        => {
      'type'          => 'enum', 
      'values'        => [qw(
                            manual_ok 
                            under_review 
                            note 
                            healthcheck_bug 
                            manual_ok_all_releases 
                            manual_ok_this_assembly 
                            manual_ok_this_genebuild
      )]
    },
    comment       => {type => 'text'},
  ],

  title_column  => 'comment',

  relationships => [
    report => {
      'type'        => 'one to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::Report',
      'column_map'  => {'report_id' => 'report_id'},
    },
  ]
);

1;