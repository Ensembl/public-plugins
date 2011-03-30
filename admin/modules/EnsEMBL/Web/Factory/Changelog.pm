package EnsEMBL::Web::Factory::Changelog;

### NAME: EnsEMBL::Web::Factory::Changelog
### Very simple factory to produce EnsEMBL::Web::Object::Changelog objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('Changelog', undef, $self->__data));
}

1;