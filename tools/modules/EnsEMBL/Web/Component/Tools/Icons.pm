package EnsEMBL::Web::Component::Tools::Icons;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable(0);
}

sub content {
  my $self  = shift;
  my $hub   = $self->hub;

  return sprintf '<p><a href="%s">BLAST/BLAT Search</a></p><p><a href="%s">VEP</a></p>', $hub->url({'action' => 'Blast'}), $hub->url({'action' => 'VEP'});
  
}

1;
