package EnsEMBL::Web::Component::Healthcheck::MultiAnnotate;

### 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Healthcheck);
use EnsEMBL::Web::Data::HcReport;
use EnsEMBL::Web::Data::HcAnnotation;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $species = $object->species;
  my $release = $object->release;
  my $html;

  if ($object->param('report_id')) {
    my $form = EnsEMBL::Web::Form->new('multi_annotate', '/'.$object->species.'/Healthcheck/MultiSave', 'post');

    my @report_ids = $object->param('report_id');

    $form->add_element(
      'type' => 'Header',
      'value' => 'Reports being annotated',
    );

    foreach my $id (@report_ids) {
      my $report = EnsEMBL::Web::Data::HcReport->new($id);
      $form->add_element(
        'type' => 'NoEdit',
        'name' => 'report_'.$id,
        'label' => $report->testcase,
        'value' => $report->text,
      );
      $form->add_element(
        'type'  => 'Hidden',
        'name'  => 'id',
        'value' => $id,
      );
    }

    $form->add_element(
      'type' => 'Header',
      'value' => 'Annotation',
    );


    my @actions = (
      {'value' => 'note',                     'name' => 'Note or comment'},
      {'value' => 'under_review',             'name' => 'Under review: Fixed or will be fixed/reviewed'},
      {'value' => 'healthcheck_bug',          'name' => 'Healthcheck bug: error should not appear, requires changes to healthcheck'},
      {'value' => 'manual_ok',                'name' => 'Manual ok: not a problem for this release'},
      {'value' => 'manual_ok_this_assembly',  'name' => 'Manual ok this assembly: not a problem for this species and assembly'},
      {'value' => 'manual_ok_all_releases',   'name' => 'Manual ok all release: not a problem for this species'},
    );
    $form->add_element(
      'type'    => 'DropDown',
      'name'    => 'action',
      'label'   => 'Action',
      'select'  => 'select',
      'values'  => \@actions
    );
    $form->add_element(
      'type'    => 'String',
      'name'    => 'comment',
      'label'   => 'Comment',
      'size'    => 60,
    );
    $form->add_element(
      'type'  => 'Information',
      'value' => 'N.B. You no longer need to enter your email address - it will be automatically saved based on your login ID',
    );
    $form->add_element(
      'type'    => 'Submit',
      'name'    => 'submit',
      'value'   => 'Save',
    );
    $html .= $form->render;  
  }
  else {
    $html .= $self->_error('No reports selected', "You did not select any reports to annotate. Please click on the 'Back' button and try again.");
  }

  return $html;
}

1;
