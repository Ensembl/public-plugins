package EnsEMBL::Web::Component::Website::NewsSpecies;

### Custom form for adding one or more species to a declaration of intentions

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::Release;

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
  my $id = $object->param('id');
  my $html;

  if ($id) {
    $html = '<h1>Add species</h1>';

    my $form = EnsEMBL::Web::Form->new('add_species', '/Website/LinkSpecies', 'post');

    ## Get all the species for this release
    my $release = EnsEMBL::Web::Data::Release->new($object->species_defs->ENSEMBL_VERSION);
    my @species = sort {$a->name cmp $b->name} $release->species;
    my $values = [];
    foreach my $sp (@species) {
      (my $name = $sp->name) =~ s/_/ /; 
      push @$values, {'name' => $name, 'value' => $sp->species_id};
    }

    $form->add_element(
      'name' => 'species_id',
      'type' => 'MultiSelect',
      'label' => 'Species',
      'values' => $values,
    );
    $form->add_element(
      'name' => 'news_item_id',
      'type' => 'Hidden',
      'value' => $id,
    );
    $form->add_element(
      'name' => 'submit',
      'type' => 'Submit',
      'value' => 'Save',
    );

    $html .= $form->render;
  }
  else {
    $html .= 'Sorry, could not find record ID for this declaration';
  }

  return $html;
}

1;
