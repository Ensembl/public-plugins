package EnsEMBL::Web::Command::Healthcheck::MultiSave;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Data::HcAnnotation;

use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;

  my @report_ids = $object->param('report_id');
  foreach my $id (@report_ids) {
    ## Check if this report is already annotated
    my $annotation = EnsEMBL::Web::Data::HcAnnotation->find('report_id' => $id);
    unless ($annotation) {
      EnsEMBL::Web::Data::HcAnnotation->new();
      $annotation->report_id = $id;
    }
    $annotation->action = $object->param('action');
    $annotation->comment = $object->param('comment');
    $annotation->save;
  }

  $object->redirect('/'.$object->species.'/Healthcheck/Details');
}

}

1;

