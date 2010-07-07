package EnsEMBL::ORM::Component::DbFrontend::Add;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Add
### Creates a form to add a new record to the database

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
  my $form = $self->create_input_form('Add', $self->model->object->data_objects->[0]);
  return $form->render;
}

1;
