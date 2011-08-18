package EnsEMBL::Web::Factory::ExternalDb;

### NAME: EnsEMBL::Web::Factory::ExternalDb
### Very simple factory to produce EnsEMBL::Web::Object::ExternalDb objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('ExternalDb', undef, $self->__data));
}


1;