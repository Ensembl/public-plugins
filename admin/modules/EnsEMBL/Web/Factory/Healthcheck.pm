package EnsEMBL::Web::Factory::Healthcheck;

### NAME: EnsEMBL::Web::Factory::Healthcheck

### STATUS: Under Development

use strict;

use base qw(EnsEMBL::Web::Factory);
use EnsEMBL::Web::Object::Healthcheck;

sub createObjects {
  my $self = shift;

  $self->DataObjects(EnsEMBL::Web::Object::Healthcheck->new($self->hub));
}

1;