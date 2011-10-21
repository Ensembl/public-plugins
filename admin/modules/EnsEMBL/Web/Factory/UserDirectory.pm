package EnsEMBL::Web::Factory::UserDirectory;

### NAME: EnsEMBL::Web::Factory::UserDirectory

### STATUS: Stable

use strict;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  
  $self->DataObjects($self->new_object('UserDirectory', undef, $self->__data));
}

1;