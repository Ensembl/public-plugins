# $Id$

package EnsEMBL::Web::Component::Location::ViewTop;

use strict;

use EnsEMBL::Web::Tools::MethodMaker(copy => [ 'content', 'content_main' ]);

use base qw(EnsEMBL::Web::Component::Location::Genoverse);

sub new_image {
  # The plugin system causes confusion as to what is inherited. Make sure the right function is called
  return EnsEMBL::Web::Component::Location::Genoverse::new_image(@_);
}

sub content { return $_[0]->content_test; }

1;

