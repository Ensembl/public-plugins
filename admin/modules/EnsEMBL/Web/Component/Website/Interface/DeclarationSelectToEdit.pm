package EnsEMBL::Web::Component::Website::Interface::DeclarationSelectToEdit;

### Module to display all declarations in full

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::NewsItem;

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
  my $html = '<h1>Declarations</h1>';

  my @declarations = EnsEMBL::Web::Data::NewsItem->search('release_id' => $object->species_defs->ENSEMBL_VERSION);
  my @sorted = sort {
                $a->team cmp $b->team || $a->created_at cmp $b->created_at
              } @declarations;

  my @values = ({'name' => '-- Select --', 'value' => ''});
  foreach my $dec (@sorted) {
    next unless $dec->declaration;
    push @values, {'name' => $dec->team.' - '.substr($dec->declaration, 0, 50), 'value' => $dec->id};
  }

  my $form = EnsEMBL::Web::Form->new('select_dec', '/Website/Declaration/Edit', 'post');

  $form->add_element(
    'name' => 'id',
    'type' => 'DropDown',
    'label' => 'Declarations',
    'select' => 'select',
    'values' => \@values,
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
