package EnsEMBL::Web::Factory::Metakey;

### NAME: EnsEMBL::Web::Factory::Metakey
### Very simple factory to produce EnsEMBL::Web::Object::Metakey objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Metakey', undef, $self->__data));
}

1;