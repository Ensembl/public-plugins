package EnsEMBL::Web::Controller;

use strict;
use warnings;

use previous qw(OBJECT_PARAMS);

sub OBJECT_PARAMS {
  return [ @{shift->PREV::OBJECT_PARAMS}, [ 'Tools' => 'tl' ] ];
}

1;
