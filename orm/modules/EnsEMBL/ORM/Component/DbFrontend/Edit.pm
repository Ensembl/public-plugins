package EnsEMBL::ORM::Component::DbFrontend::Edit;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Edit
### Creates a form to edit a database record

### STATUS: Under development
### Note: This module should not be modified! 
### To customise an individual form, see the appropriate 
### EnsEMBL::ORM::DbFrontend module 

### DESCRIPTION:

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  my $self = shift;
  ## Single record form
  my $form = $self->create_input_form('Edit', $self->model->object->data_objects->[0]);
  return $form->render;
}

1;
