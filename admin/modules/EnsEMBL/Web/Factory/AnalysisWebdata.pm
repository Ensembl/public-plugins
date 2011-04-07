package EnsEMBL::Web::Factory::AnalysisWebdata;

### NAME: EnsEMBL::Web::Factory::AnalysisWebdata
### Very simple factory to produce EnsEMBL::Web::Object::AnalysisWebdata objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('AnalysisWebdata', undef, $self->__data));
}

1;