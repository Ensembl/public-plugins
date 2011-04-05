package EnsEMBL::ORM::SiteDefs;

### This module adds a new variable ROSE_DB_DATABASES, a hashref, to site defs
### View DbConnection.pm for more info

use strict;

sub update_conf {

  $SiteDefs::ROSE_DB_DATABASES = {};
}

1;