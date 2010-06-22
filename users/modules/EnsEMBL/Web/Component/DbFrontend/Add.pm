package EnsEMBL::Web::Component::DbFrontend::Add;

### NAME: EnsEMBL::Web::Component::DbFrontend::Add
### Creates a form to add a new record to the database

### STATUS: Under development
### Note: This module should not be modified! 
### To customise an individual form, see the appropriate 
### EnsEMBL::Web::DbFrontend module 

### DESCRIPTION:

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Component::DbFrontend);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  my $self = shift;
  my $form = $self->create_input_form('Add');
  return $form->render;
}

1;
