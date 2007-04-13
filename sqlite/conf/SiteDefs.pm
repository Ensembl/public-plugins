package EnsEMBL::SQLite::SiteDefs;
use strict;
sub update_conf {
## Switch user db to sqlite
  $SiteDefs::ENSEMBL_USERDB_TYPE  = 'sqlite';
  $SiteDefs::ENSEMBL_USERDB_NAME  = $SiteDefs::ENSEMBL_SERVERROOT.'/ensembl_web_user_db.sqlite';
  $SiteDefs::ENSEMBL_USERDB_HOST  = 'fred';
## Turn of user logins
  $SiteDefs::ENSEMBL_LOGINS       = 0;
}

1;
