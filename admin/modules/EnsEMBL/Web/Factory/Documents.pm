package EnsEMBL::Web::Factory::Documents;

### NAME: EnsEMBL::Web::Factory::Documents
### Very simple factory to produce EnsEMBL::Web::Object::Documents objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Documents', undef, $self->__data));
}

1;