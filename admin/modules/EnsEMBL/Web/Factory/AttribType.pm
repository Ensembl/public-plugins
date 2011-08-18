package EnsEMBL::Web::Factory::AttribType;

### NAME: EnsEMBL::Web::Factory::AttribType
### Very simple factory to produce EnsEMBL::Web::Object::AttribType objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('AttribType', undef, $self->__data));
}


1;