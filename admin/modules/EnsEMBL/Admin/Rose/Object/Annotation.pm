package EnsEMBL::Admin::Rose::Object::Annotation;

### NAME: EnsEMBL::Admin::Rose::Object::Annotation
### ORM class for the annotation table in healthcheck 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'annotation',

  columns     => [
    report_id     => {type => 'serial', primary_key => 1, not_null => 1}, 
    action        => {type => 'enum', 
                      'values' => [qw(
                                    manual_ok 
                                    under_review 
                                    note 
                                    healthcheck_bug 
                                    manual_ok_all_releases 
                                    manual_ok_this_assembly 
                                    manual_ok_this_genebuild
                                  )]},
    comment       => {type => 'varchar', 'length' => '255'},
    created_by    => {type => 'integer'},
    created_at    => {type => 'datetime'},
    modified_by   => {type => 'integer'},
    modified_at   => {type => 'datetime'},
  ],

  relationships => [
    report => {
      'type'        => 'one to one',
      'map_class'   => 'EnsEMBL::Admin::Rose::Object::Report',
      'column_map'  => {'report_id' => 'report_id'},
    },
  ],

);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('healthcheck'); 
}

1;
