package EnsEMBL::Web::Factory::SpeciesAlias;

### NAME: EnsEMBL::Web::Factory::SpeciesAlias
### Very simple factory to produce EnsEMBL::Web::Object::SpeciesAlias objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('SpeciesAlias', undef, $self->__data));
}

1;