package EnsEMBL::Web::Factory::Production;

### NAME: EnsEMBL::Web::Factory::Production

### STATUS: Stable

use strict;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  
  $self->DataObjects($self->new_object('Production', undef, $self->__data));
}

1;