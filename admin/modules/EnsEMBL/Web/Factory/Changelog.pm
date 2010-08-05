package EnsEMBL::Web::Factory::Changelog;

### NAME: EnsEMBL::Web::Factory::Changelog
### Very simple factory to produce EnsEMBL::Admin::Data::Rose::Changelog objects

### STATUS: Stable

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Admin::Data::Rose::Changelog;
use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  my $changelog = EnsEMBL::Admin::Data::Rose::Changelog->new($self->hub);
  $self->DataObjects($changelog);
}

1;
