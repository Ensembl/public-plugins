=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Nginx::SiteDefs;

use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_NGINX_PORT = defer {
    my $out = $SiteDefs::ENSEMBL_PORT;
    $SiteDefs::ENSEMBL_PORT += 5000;
    return $out;
  };  

  $SiteDefs::ENSEMBL_NGINX_USER   = '';                                                                                 # Set it to 'nginx_user nginx_user_group;' if running NGINX on port 80
  $SiteDefs::ENSEMBL_NGINX_ROOT   = $SiteDefs::ENSEMBL_SERVERROOT."/public-plugins/nginx";                              # path to NGINX plugin
  $SiteDefs::ENSEMBL_NGINX_RUNDIR = defer { $SiteDefs::ENSEMBL_TMP_DIR."/nginx/".$SiteDefs::ENSEMBL_SERVER_SIGNATURE }; # path to store all run time config/log files
  $SiteDefs::ENSEMBL_NGINX_EXE    = required '/path/to/nginx';                                                          # path to the executable NGINX file
}

1;
