# $Id$

package EnsEMBL::Web::Component::Location::ViewTop;

use strict;

use previous qw(content);

use base qw(EnsEMBL::Web::Component::Location::Genoverse);

sub new_image {
  # The plugin system causes confusion as to what is inherited. Make sure the right function is called
  return EnsEMBL::Web::Component::Location::Genoverse::new_image(@_);
}

sub content      { return $_[0]->content_test;  }
sub content_main { return $_[0]->PREV::content; }

1;
