use strict;

package EnsEMBL::Admin::SiteDefs;

sub update_conf {
  $SiteDefs::ENSEMBL_WEBADMIN_ID     = 0;


  ## ALLOWABLE DATA OBJECTS
  $SiteDefs::OBJECT_TO_SCRIPT = {
    Config      => 'config',
    Component   => 'component',
    Zmenu       => 'zmenu',

    Search      => 'action',
    Changelog   => 'action',
    Healthcheck => 'action',
    News        => 'action',

    Account     => 'modal',
    UserData    => 'modal',
    Help        => 'modal',
  };

  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED = 0;
  $SiteDefs::ENSEMBL_MEMCACHED = {};
};


}

1;
