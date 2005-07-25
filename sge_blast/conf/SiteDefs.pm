use strict;

package EnsEMBL::SGE_BLAST::SiteDefs;
sub update_conf {
  $SiteDefs::ENSEMBL_SGE_SHARED_DIR         = '/usr/shared/tmp';
  $SiteDefs::ENSEMBL_SGE_RCP_CMD            = '/usr/bin/scp';
  $SiteDefs::ENSEMBL_SGE_ROOT               = '/opt/gridengine';
}

1;
