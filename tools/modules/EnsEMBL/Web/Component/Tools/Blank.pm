package EnsEMBL::Web::Component::Tools::Blank;

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
  return 'In Development';
}

1; 
