package EnsEMBL::Web::Component::Website::Interface::NewsSelectToEdit;

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
  my $html = '<h1>News Stories</h1>';
  my $release_id = $object->param('release_id') || $object->species_defs->ENSEMBL_VERSION;

  my @stories = EnsEMBL::Web::Data::NewsItem->search('release_id' => $release_id);
  my @sorted = sort {
                $a->team cmp $b->team || $a->title cmp $b->title
              } @stories;

  my @values = ({'name' => '-- Select --', 'value' => ''});
  foreach my $story (@sorted) {
    next unless $story->title || $story->declaration;
    my $text = $story->title ? $story->title : substr($story->declaration, 0, 50);
    push @values, {'name' => $story->team." - text", 'value' => $story->id};
  }

  my $form = EnsEMBL::Web::Form->new('select_news', '/Website/News/Edit', 'post');

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
