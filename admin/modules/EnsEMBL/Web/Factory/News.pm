package EnsEMBL::Web::Factory::News;

### NAME: EnsEMBL::Web::Factory::News
### Very simple factory to produce EnsEMBL::Admin::Data::Rose::News objects

### STATUS: Stable

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Admin::Data::Rose::News;
use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  my $news = EnsEMBL::Admin::Data::Rose::News->new($self->hub);
  $self->DataObjects($news);
}

1;
