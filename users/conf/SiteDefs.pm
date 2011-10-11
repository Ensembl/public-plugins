package EnsEMBL::Users::SiteDefs;

### SiteDefs additions for Users plugin

use strict;

sub update_conf {

  $SiteDefs::OBJECT_TO_SCRIPT->{'Account'} => 'Modal';

  $SiteDefs::ENSEMBL_USERS_ENABLED = 1;

  $SiteDefs::ROSE_DB_DATABASES->{'user'} = {
    database  => $SiteDefs::ENSEMBL_USERDB_NAME,
    host      => $SiteDefs::ENSEMBL_USERDB_HOST,
    port      => $SiteDefs::ENSEMBL_USERDB_PORT,
    username  => $SiteDefs::ENSEMBL_USERDB_USER || $SiteDefs::DATABASE_WRITE_USER,
    password  => $SiteDefs::ENSEMBL_USERDB_PASS || $SiteDefs::DATABASE_WRITE_PASS,
  };
}

1;