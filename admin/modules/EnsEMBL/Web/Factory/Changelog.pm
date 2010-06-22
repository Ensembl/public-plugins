package EnsEMBL::Web::Factory::Changelog;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Data::Rose::Changelog;
use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  my $changelog = EnsEMBL::Web::Data::Rose::Changelog->new($self->hub);
  $self->DataObjects($changelog);
}

1;
