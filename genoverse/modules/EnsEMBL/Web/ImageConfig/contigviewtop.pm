# $Id$

package EnsEMBL::Web::ImageConfig::contigviewtop;

use strict;

use base qw(EnsEMBL::Web::ImageConfig::Genoverse);

sub modify {
  my $self = shift;
  
  $self->init_genoverse;
  $self->set_parameter('zoom', 'no');
}

sub reset { EnsEMBL::Web::ImageConfig::Genoverse::reset(@_); }

1;
