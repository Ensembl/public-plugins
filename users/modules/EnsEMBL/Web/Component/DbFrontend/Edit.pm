package EnsEMBL::Web::Component::DbFrontend::Edit;

### NAME: EnsEMBL::Web::Component::DbFrontend::Edit
### Creates a form to edit a database record

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
  my $form = $self->create_input_form('Edit');
  return $form->render;
}

1;
