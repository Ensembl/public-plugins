package EnsEMBL::Web::Object::Website;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Object);

sub caption       { return undef; }
sub short_caption { return ''; }
sub counts        { return undef; }

#-----------------------------------------------------------------------------

1;
