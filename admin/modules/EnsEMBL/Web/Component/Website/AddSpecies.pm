package EnsEMBL::Web::Component::Website::AddSpecies;

### Custom form for adding a new species to a release

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::Species;

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
  my $html = '<h1>Add a new species</h1>';

  my $form = EnsEMBL::Web::Form->new('add_species', '/Website/SaveSpecies', 'post');

  $form->add_element(
    'name' => 'name',
    'type' => 'String',
    'label' => 'Binomial name',
    'value' => $object->param('name'),
    'required' => 'yes',
  );
  $form->add_element(
    'name' => 'common_name',
    'type' => 'String',
    'label' => 'Common name',
    'value' => $object->param('common_name'),
    'required' => 'yes',
  );
  $form->add_element(
    'name' => 'assembly',
    'type' => 'String',
    'label' => 'Current assembly',
    'value' => $object->param('assembly'),
    'required' => 'yes',
  );
  $form->add_element(
    'name' => 'submit',
    'type' => 'Submit',
    'value' => 'Save',
  );

  $html .= $form->render;
  return $html;
}

1;
