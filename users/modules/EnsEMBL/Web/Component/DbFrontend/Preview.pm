package EnsEMBL::Web::Component::DbFrontend::Preview;

### NAME: EnsEMBL::Web::Component::DbFrontend::Preview
### Creates a page displaying a preview of an edited record prior to saving

### STATUS: Under development
### Note: This module should not be modified! 
### To customise an individual form, see (or create) the appropriate 
### EnsEMBL::Web::FrontendConfig module

### DESCRIPTION:

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::DbFrontend);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  my $self = shift;
  my $form = $self->create_preview_form;;
  return $form->render;
}

1;
