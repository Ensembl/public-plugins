package EnsEMBL::ORM::Component::DbFrontend::Problem;

### Module to create generic data display for Interface and its associated modules

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  my $self  = shift;
  my $error = $self->hub->param('error');
     $error = $error ? "Error: $error" : 'Please try again.';

  return $self->dom->create_element('div', {
    'class'      => [$self->object->content_css, $self->_JS_CLASS_RESPONSE_ELEMENT],
    'inner_HTML' => qq(<p class="dbf-error">Sorry, an error occurred while updating information to the database.<br />$error</p>)
  });
}

1;