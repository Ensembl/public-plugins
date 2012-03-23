package EnsEMBL::Users::SiteDefs;

### SiteDefs additions for Users plugin

use strict;

sub update_conf {

  $SiteDefs::OBJECT_TO_SCRIPT->{'Account'} = 'Modal';

  $SiteDefs::ENSEMBL_USERS_ENABLED         = 1;

  $SiteDefs::ENSEMBL_USERDB_NAME           = 'hr5_test_users_db';

  $SiteDefs::ROSE_DB_DATABASES->{'user'}   = {
    database  => $SiteDefs::ENSEMBL_USERDB_NAME,
    host      => $SiteDefs::ENSEMBL_USERDB_HOST,
    port      => $SiteDefs::ENSEMBL_USERDB_PORT,
    username  => $SiteDefs::ENSEMBL_USERDB_USER || $SiteDefs::DATABASE_WRITE_USER,
    password  => $SiteDefs::ENSEMBL_USERDB_PASS || $SiteDefs::DATABASE_WRITE_PASS,
  };

  ## * List of openid login providers *
  ## Save the provider's endpoint url as value to a key which tells about the provider
  ## If endpoint url needs user name, leave "[USERNAME]" in as a placeholder
  ## These gets listed as "login via" options on login page in the same order as here
  ## Save corresponding icons in htdocs/i folder (eg. openid_google.png for Google, openid_myopenid.png for MyOpenID)
  $SiteDefs::OPENID_PROVIDERS = [
    'Google'    => 'http://www.google.com/accounts/o8/id',
    'Yahoo'     => 'https://me.yahoo.com/',
    'MyOpenID'  => 'https://myopenid.com/',
#    'AOL'       => 'http://openid.aol.com/[USERNAME]'
  ];
  ## The following OpenID providers are trusted to provide genuine email address of the user
  $SiteDefs::TRUSTED_OPENID_PROVIDERS = [
    qr/google/i, # TODO
    qr/yahoo/i,  # TODO
  ];
}

1;
