package EnsEMBL::Web::Factory::AnalysisDesc;

### NAME: EnsEMBL::Web::Factory::AnalysisDesc
### Very simple factory to produce EnsEMBL::Web::Object::AnalysisDesc objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('AnalysisDesc', undef, $self->__data));
}


1;