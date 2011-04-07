package EnsEMBL::Web::Factory::Species;

### NAME: EnsEMBL::Web::Factory::Species
### Very simple factory to produce EnsEMBL::Web::Object::Species objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Species', undef, $self->__data));
}

1;