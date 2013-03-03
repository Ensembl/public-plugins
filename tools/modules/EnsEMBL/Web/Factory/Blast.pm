package EnsEMBL::Web::Factory::Blast;

use strict;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {   
  my $self = shift;    

  ## Create a very lightweight object, as the data required for a blast page is very variable
  $self->DataObjects($self->new_object('Blast', {
  }, $self->__data));
}

1;

