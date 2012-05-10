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
      'values'        => [keys %{{__PACKAGE__->annotation_actions}}]
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

sub annotation_actions {
  ## @static
  my ($class, $flag) = @_;
  my @manual_ok = (
    'manual_ok'                       => 'Manual ok: not a problem for this release',
    'manual_ok_all_releases'          => 'Manual ok all release: not a problem for this species',
    'manual_ok_this_assembly'         => 'Manual ok this assembly',
    'manual_ok_this_genebuild'        => 'Manual ok this genebuild',
    'manual_ok_this_regulatory_build' => 'Manual ok this regulatory build',
    'healthcheck_bug'                 => 'Healthcheck bug: error should not appear, requires changes to healthcheck',
  );
  return $flag && $flag eq 'manual_ok' ? @manual_ok : ( @manual_ok,
    'under_review'                    => 'Under review: Fixed or will be fixed/reviewed',
    'note'                            => 'Note or comment',
  );
}

1;