package EnsEMBL::Web::Factory::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Tools', {}, $self->__data));
}

1;
