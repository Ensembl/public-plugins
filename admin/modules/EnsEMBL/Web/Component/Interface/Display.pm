package EnsEMBL::Web::Component::Interface::Display;

## Overrides the standard 'Display' Component, and forces the interface to use
## the normal component from the core code

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Interface);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  my $self = shift;

  my $module = 'EnsEMBL::Web::Component::'.$ENV{'ENSEMBL_TYPE'}.'::'.$ENV{'ENSEMBL_ACTION'};
  if ($self->dynamic_use($module)) {
    my $component = $module->new($self->object);
    if ($component) {
      return $component->content;
    }
  }
}

1;
