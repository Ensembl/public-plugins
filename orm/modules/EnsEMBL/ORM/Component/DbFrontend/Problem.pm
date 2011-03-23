package EnsEMBL::ORM::Component::DbFrontend::Problem;

### Module to create generic data display for Interface and its associated modules

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  my $self = shift;

  return $self->dom->create_element('p', {'inner_HTML' => 'Sorry, there was a problem saving your data to the database. Please try again.'});
}

1;
