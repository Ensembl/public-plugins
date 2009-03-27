package EnsEMBL::Web::Component::Website::SelectRelease;

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
  my $html = '<h1>Select a release</h1>';

  my @releases = EnsEMBL::Web::Data::Release->find_all;
  my @sorted = sort {$b->number <=> $a->number} @releases;

  my @values = ({'name' => '-- Select --', 'value' => ''});
  foreach my $release (@sorted) {
    push @values, {'name' => $release->number.' - '.$self->pretty_date($release->date), 'value' => $release->id};
  }

  my $form = EnsEMBL::Web::Form->new('select_dec', '/Website/News/SelectToEdit', 'post');

  $form->add_element(
    'name' => 'release_id',
    'type' => 'DropDown',
    'label' => 'Releases',
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
