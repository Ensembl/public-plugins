package EnsEMBL::Web::Hub;

use strict;

sub core_params { return $_[0]->param('release') ? { 'release' => $_[0]->param('release') } : {}; }

1;