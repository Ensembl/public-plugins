package EnsEMBL::Web::Factory::HelpRecord;

### NAME: EnsEMBL::Web::Factory::HelpRecord
### Very simple factory to produce EnsEMBL::Web::Object::HelpRecord objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('HelpRecord', undef, $self->__data));
}

1;