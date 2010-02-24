package EnsEMBL::Web::Command::Healthcheck::Interface::Annotation;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::HcAnnotation;
use EnsEMBL::Web::Data::HcReport;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;

  ## Create interface object, which controls the forms
  my $interface = $self->interface;

  my $data = EnsEMBL::Web::Data::HcAnnotation->find_or_create({'report_id' => $object->param('id')});

  $interface->data($data);
  $interface->discover;

  my $report = EnsEMBL::Web::Data::HcReport->new($object->param('report_id'));
  if ($report) {
    $interface->element('report_header', {
      'type' => 'Header',
      'value' => 'Reports being annotated',
    });
    $interface->element('report', {
      'type'=>'NoEdit', 
      'label' => $report->testcase,
      'value' => $report->text,
    });
  }

  $interface->element('annotation_header', {
    'type' => 'Header',
    'value' => 'Annotation',
  });
  my @actions = (
    {'value' => 'note',                     'name' => 'Note or comment'},
    {'value' => 'under_review',             'name' => 'Under review: Fixed or will be fixed/reviewed'},
    {'value' => 'healthcheck_bug',          'name' => 'Healthcheck bug: error should not appear, requires changes to healthcheck'},
    {'value' => 'manual_ok',                'name' => 'Manual ok: not a problem for this release'},
    {'value' => 'manual_ok_this_assembly',  'name' => 'Manual ok this assembly: not a problem for this species and assembly'},
    {'value' => 'manual_ok_all_releases',   'name' => 'Manual ok all release: not a problem for this species'},
  );
  $interface->modify_element('action', {'type' => 'DropDown', 'values' => \@actions});
  $interface->modify_element('comment', {'size' => 60});
  $interface->element('email', {
      'type'  => 'Information',
      'value' => 'N.B. You no longer need to enter your email address - it will be automatically saved based on your login ID',
    });


## Form elements
  $interface->no_preview(1); ## Keeps automated interface simple and in line with MultiAnnotate
  $interface->element_order(['report_header', 'report', 'annotation_header', 'action', 'comment', 'email']);
  $interface->set_landing_page('/'.$object->species.'/Healthcheck/Details');

  $interface->configure($self->webpage, $object);

}

}

1;
