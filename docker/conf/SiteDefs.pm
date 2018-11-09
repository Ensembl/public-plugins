# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package EnsEMBL::Docker::SiteDefs;
use strict;

# configs for a docker-based Ensembl instance

sub update_conf {

  # the internal port to bind to
  $SiteDefs::ENSEMBL_PORT = 8080;
  # get the server name from the environment (this should match the domain name, e.g. www.ensembl.org)
  $SiteDefs::ENSEMBL_SERVERNAME = $ENV{ENSEMBL_SERVERNAME} if $ENV{ENSEMBL_SERVERNAME};

  # set a dummy hostname - without this, Ensembl will use the system hostname and get confused
  # because in a container the hostname is changing with each docker build step
  $SiteDefs::ENSEMBL_SERVER           = 'dockerhost';
  $SiteDefs::ENSEMBL_SERVER_SIGNATURE = "$SiteDefs::ENSEMBL_SERVER-$SiteDefs::ENSEMBL_SERVERROOT" =~ s/\W+/-/gr; #/


 ## IMPORTANT - do not use these root paths in code, use the 'DIR' version!
  $SiteDefs::ENSEMBL_TMP_ROOT               = '/ebi/nobackup';
  $SiteDefs::ENSEMBL_USERDATA_ROOT          = '/ebi/incoming';

  $SiteDefs::ENSEMBL_TMP_DIR                = defer { $SiteDefs::ENSEMBL_TMP_ROOT };
  $SiteDefs::ENSEMBL_USERDATA_DIR           = defer { $SiteDefs::ENSEMBL_USERDATA_ROOT };

  # path to linuxbrew work dir
  $SiteDefs::SHARED_SOFTWARE_PATH = '/home/linuxbrew';

  $SiteDefs::ENSEMBL_EXTERNAL_SEARCHABLE    = 0;

  # limit the demo to human and mouse
  $SiteDefs::PRODUCTION_NAMES = [qw(
    homo_sapiens
    mus_musculus
  )];
}

1;
