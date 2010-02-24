package EnsEMBL::Web::Component::Website::SelectAnalysis;

### Custom form for selecting an analysis

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::Analysis;

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
  my $html = '<h1>Select an analysis</h1>';

  my $core_object = EnsEMBL::Web::Data::Analysis->new;
  my $connected = $core_object->connect;

  if ($connected) {
    my $form = EnsEMBL::Web::Form->new('select_analysis', '/Website/AnalysisDescription', 'post');
    my @analyses = $core_object->find_all;
    my @sorted = sort {$a->logic_name cmp $b->logic_name} @analyses;
    my @values;

    foreach my $analysis (@sorted) {
      push @values, {'name' => $analysis->logic_name, 'value' => $analysis->id};
    }

    $form->add_element(
      'name' => 'analysis_id',
      'type' => 'DropDown',
      'label' => 'Analysis',
      'values' => \@values,
      'select' => 'select',
      'required' => 'yes',
    );
    $form->add_element(
      'name' => 'submit',
      'type' => 'Submit',
      'value' => 'Next',
    );

    $html .= $form->render;
  }
  else {
    $html .= $self->_error('DB Error', "Could not connect to $species core database");
  }
  return $html;
}

1;
