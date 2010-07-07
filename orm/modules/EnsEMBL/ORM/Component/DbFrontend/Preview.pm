package EnsEMBL::ORM::Component::DbFrontend::Preview;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Preview
### Creates a page displaying a non-editable view of a record

### STATUS: Under development
### Note: This module should not be modified! 
### To customise an individual form, see (or create) the appropriate 
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
  my $form = $self->create_preview_form;
  return $form->render;
}

1;
