package EnsEMBL::ORM::Component::DbFrontend::SelectToEdit;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'Select a Record';
}

sub content {
  my $self = shift;

  my $form = $self->create_selection_form('Edit');

  return $form->render;
}

1;
