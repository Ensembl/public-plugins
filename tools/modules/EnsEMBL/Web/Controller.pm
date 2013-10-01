package EnsEMBL::Web::Controller;

use strict;

use EnsEMBL::Web::Tools::MethodMaker (copy => {qw(OBJECT_PARAMS _TOOLS_OBJECT_PARAMS)});

sub OBJECT_PARAMS {
  return [ @{shift->_TOOLS_OBJECT_PARAMS}, [ 'Tools' => 'tl' ] ];
}

1;
