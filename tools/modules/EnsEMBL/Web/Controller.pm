package EnsEMBL::Web::Controller;

use strict;

use EnsEMBL::Web::Tools::MethodMaker (copy => {qw(OBJECT_PARAMS __OBJECT_PARAMS)});

sub OBJECT_PARAMS {
  return [ @{shift->__OBJECT_PARAMS}, [ 'Tools' => 'tk' ] ];
}

1;
