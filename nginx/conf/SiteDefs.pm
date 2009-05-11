package EnsEMBL::Nginx::SiteDefs;

use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_NGINX_PORT = $SiteDefs::ENSEMBL_PORT;
  $SiteDefs::ENSEMBL_PORT       = $SiteDefs::ENSEMBL_NGINX_PORT + 5000;

  $SiteDefs::ENSEMBL_NGINX_ROOT = $SiteDefs::ENSEMBL_SERVERROOT."/sanger-plugins/nginx";
}

1;
