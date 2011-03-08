package EnsEMBL::Web::Factory::Healthcheck;

### NAME: EnsEMBL::Web::Factory::Healthcheck

### STATUS: Stable

use strict;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  
  $self->DataObjects($self->new_object('Healthcheck', undef, $self->__data));
}

1;