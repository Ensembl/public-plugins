package EnsEMBL::Web::Component::Tools::SpeciesSelector;

use strict;
use warnings;
no warnings 'uninitialized';


use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  return '';
}

1;

