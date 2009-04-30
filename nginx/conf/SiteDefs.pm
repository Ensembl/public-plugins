package EnsEMBL::Nginx::SiteDefs;

use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PORT       = 8080;
  $SiteDefs::ENSEMBL_NGINX_PORT = 8000;
  $SiteDefs::ENSEMBL_PROXY_PORT = 80;

  $SiteDefs::ENSEMBL_NGINX_ROOT = $SiteDefs::ENSEMBL_SERVERROOT."/sanger-plugins/nginx";
}

1;