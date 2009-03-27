package EnsEMBL::Web::Factory::Website;

use strict;

use EnsEMBL::Web::Proxy::Object;
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Factory);

sub createObjects { 
  my $self        = shift;

  ## Create a very lightweight object, as the data required for a website page is very variable
  $self->DataObjects( new EnsEMBL::Web::Proxy::Object('Website', {}, $self->__data)); 
}

1;
