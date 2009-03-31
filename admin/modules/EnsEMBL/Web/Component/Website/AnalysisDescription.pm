package EnsEMBL::Web::Component::Website::AnalysisDescription;

### Custom form for editing an analysis

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::Analysis;
use EnsEMBL::Web::Data::AnalysisDescription;

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
  my $species = $object->species_defs->ENSEMBL_PRIMARY_SPECIES;
  my $html = '<h1>Add/Edit analysis description</h1>';

  my $form = EnsEMBL::Web::Form->new('edit_analysis', '/Website/SaveAnalysisDesc', 'post');

  my $core_object = EnsEMBL::Web::Data::Analysis->new;
  my $connected = $core_object->connect;

  my $analysis = $core_object->new($object->param('analysis_id'));

  $form->add_element(
    'type' => 'Hidden',
    'name' => 'analysis_id',
    'value' => $analysis->id,
  );

  $form->add_element(
    'type'  => 'NoEdit',
    'name'  => 'logic_name',
    'label' => 'Logic name',
    'value' => $analysis->logic_name,
  );

  #my $ad_obj = EnsEMBL::Web::Data::AnalysisDescription->new;
  #$ad_obj->db_Main($core_object->db_Main);

  #my $ad = $ad_obj->new($object->param('analysis_id'));
  my $ad = $analysis->analysis_description;

  my ($display_label, $description);
  if ($ad) {
    $display_label = $ad->display_label;
    $description = $ad->description;
  }

  $form->add_element(
    'type' => 'String',
    'name' => 'display_label',
    'label' => 'Display label',
    'value' => $display_label, 
  );

  $form->add_element(
    'type' => 'Html',
    'name' => 'description',
    'label' => 'Description',
    'value' => $description, 
  );

  $form->add_element(
    'type' => 'Information',
    'value' => 'This information will be saved to the human core database first and then copied to all the other species',
  );

  $form->add_element(
    'name' => 'submit',
    'type' => 'Submit',
    'value' => 'Next',
  );

  $html .= $form->render;
  return $html;
}

1;
