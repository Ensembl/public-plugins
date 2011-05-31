package EnsEMBL::Admin::SiteDefs;

use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_WEBADMIN_ID = 0;
  $SiteDefs::ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE = 42;
  $SiteDefs::ENSEMBL_WEBADMIN_DB_SERVERS = [
    {
      host => 'ens-staging1',
      port => '3306',
      user => 'ensro',
    },
    {
      host => 'ens-staging2',
      port => '3306',
      user => 'ensro',
    }
  ];

  ## ALLOWABLE DATA OBJECTS
  $SiteDefs::OBJECT_TO_SCRIPT = {
    Config          => 'Config',
    Component       => 'Component',
    ZMenu           => 'ZMenu',

    Search          => 'Page',
    Changelog       => 'Modal',
    Healthcheck     => 'Page',
    Species         => 'Modal',
    Biotype         => 'Modal',
    Metakey         => 'Modal',
    Webdata         => 'Modal',
    AnalysisWebdata => 'Modal',
    Production      => 'Modal',
                    
    Account         => 'Modal',
    UserData        => 'Modal',
    Help            => 'Modal',
  };

  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED = 0;
  $SiteDefs::ENSEMBL_MEMCACHED = {};

  $SiteDefs::ROSE_DB_DATABASES->{'healthcheck'} = 'DATABASE_HEALTHCHECK';
  $SiteDefs::ROSE_DB_DATABASES->{'website'}     = 'DATABASE_WEBSITE';
  $SiteDefs::ROSE_DB_DATABASES->{'production'}  = 'DATABASE_PRODUCTION';

}

1;
