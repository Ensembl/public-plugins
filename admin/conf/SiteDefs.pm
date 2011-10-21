package EnsEMBL::Admin::SiteDefs;

### SiteDefs for the Admin site
### If you are using this plugin, change the required constants from this file (along with the ones in EnsEMBL::Web:SiteDefs) by overriding them in your plugin presiding over this plugin

use strict;

sub update_conf {

  ## Allowable data objects
  $SiteDefs::OBJECT_TO_SCRIPT = {
    Config          => 'Config',
    Component       => 'Component',
    ZMenu           => 'ZMenu',

    Search          => 'Page',

    Healthcheck     => 'Page',

    UserDirectory   => 'Page',

    AnalysisDesc    => 'Modal',
    Biotype         => 'Modal',
    Changelog       => 'Modal',
    Metakey         => 'Modal',
    Production      => 'Modal',
    Species         => 'Modal',
    Webdata         => 'Modal',
    AttribType      => 'Modal',
    ExternalDb      => 'Modal',

    HelpRecord      => 'Modal', #old help stuff

    Account         => 'Modal',
    UserData        => 'Modal',
    Help            => 'Modal',
  };

  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED   = 0;
  $SiteDefs::ENSEMBL_MEMCACHED      = {};

  ## Databases used in Rose::Db::Object derived objects
  $SiteDefs::ROSE_DB_DATABASES->{'healthcheck'} = 'DATABASE_HEALTHCHECK';
  $SiteDefs::ROSE_DB_DATABASES->{'website'}     = 'DATABASE_WEBSITE';
  $SiteDefs::ROSE_DB_DATABASES->{'production'}  = 'DATABASE_PRODUCTION';

  ## ID of the admin group (user group that can access the admin website)
  $SiteDefs::ENSEMBL_WEBADMIN_ID = 0;
  
  ## First release from which healthcheck started
  $SiteDefs::ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE = 0;
  
  ## List of database servers hosting species tables (used in healthcheck pages to display list of all databases)
  $SiteDefs::ENSEMBL_WEBADMIN_DB_SERVERS = [{
    host => 'myserver',
    port => '3306',
    user => 'myuser',
    pass => 'mypassword'
  }];
}

1;