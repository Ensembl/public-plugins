package EnsEMBL::Web::Factory::Biotype;

### NAME: EnsEMBL::Web::Factory::Biotype
### Very simple factory to produce EnsEMBL::Web::Object::Biotype objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Biotype', undef, $self->__data));
}

1;