package EnsEMBL::Web::Factory::Changelog;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::ORM::Data::Rose::Changelog;
use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  my $changelog = EnsEMBL::ORM::Data::Rose::Changelog->new($self->hub);
  $self->DataObjects($changelog);
}

1;
