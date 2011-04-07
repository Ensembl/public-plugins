package EnsEMBL::Web::Factory::Webdata;

### NAME: EnsEMBL::Web::Factory::Webdata
### Very simple factory to produce EnsEMBL::Web::Object::Webdata objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Webdata', undef, $self->__data));
}

1;