package EnsEMBL::Web::Factory::HelpLink;

### NAME: EnsEMBL::Web::Factory::HelpLink
### Very simple factory to produce EnsEMBL::Web::Object::HelpLink objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('HelpLink', undef, $self->__data));
}

1;