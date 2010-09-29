use strict;

package EnsEMBL::Admin::SiteDefs;

sub update_conf {
  $SiteDefs::ENSEMBL_WEBADMIN_ID     = 0;


  ## ALLOWABLE DATA OBJECTS
  $SiteDefs::OBJECT_TO_SCRIPT = {
    Config      => 'Config',
    Component   => 'Component',
    ZMenu       => 'ZMenu',

    Search      => 'Page',
    Changelog   => 'Page',
    Healthcheck => 'Page',
    News        => 'Page',

    Account     => 'Modal',
    UserData    => 'Modal',
    Help        => 'Modal',
  };

  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED = 0;
  $SiteDefs::ENSEMBL_MEMCACHED = {};

}

1;
