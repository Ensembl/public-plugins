package EnsEMBL::ORM::Component::DbFrontend::Problem;

### Module to create generic data display for Interface and its associated modules

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  my $self = shift;

  return $self->dom->create_element('div', {
    'class'      => [$self->object->content_css, $self->_JS_CLASS_RESPONSE_ELEMENT],
    'inner_HTML' => '<p>Sorry, a problem occurred while updating information to the database. Please try again.</p>'
  });
}

1;