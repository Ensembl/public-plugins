package EnsEMBL::Web::Factory::News;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::ORM::Data::Rose::News;
use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  my $news = EnsEMBL::ORM::Data::Rose::News->new($self->hub);
  $self->DataObjects($news);
}

1;
