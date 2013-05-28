package EnsEMBL::Tools::SiteDefs;

### Adds the ORM db details for tickets db

use strict;

sub update_conf {

  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';
}

1;
