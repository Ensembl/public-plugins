package EnsEMBL::Lucene::SiteDefs;

use strict;

sub update_conf {
 $SiteDefs::OBJECT_TO_SCRIPT->{'Lucene'} = 'Page';
}

1;
