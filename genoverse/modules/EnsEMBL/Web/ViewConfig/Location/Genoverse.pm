# $Id$

package EnsEMBL::Web::ViewConfig::Location::Genoverse;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('scrollable', 'nodas');
  $self->title = 'Scrollable Region';
}

1;
