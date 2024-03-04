# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
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

package EnsEMBL::Parasite::Vagrant::SiteDefs;
use strict;

# configs for a docker-based Ensembl instance

sub update_conf {
  $SiteDefs::ENSEMBL_PORT = 8032;

  $SiteDefs::ENSEMBL_SERVERNAME       = 'parasite.wormbase.org.local';

  # set a dummy hostname - without this, Ensembl will use the system hostname and get confused
  # because in a container the hostname is changing with each docker build step
  $SiteDefs::ENSEMBL_SERVER           = 'localhost';
  $SiteDefs::ENSEMBL_SERVER_SIGNATURE = "$SiteDefs::ENSEMBL_SERVER-$SiteDefs::ENSEMBL_SERVERROOT" =~ s/\W+/-/gr; #/


 ## IMPORTANT - do not use these root paths in code, use the 'DIR' version!
  $SiteDefs::ENSEMBL_TMP_ROOT               = '/ebi/nobackup';
  $SiteDefs::ENSEMBL_USERDATA_ROOT          = '/ebi/incoming';

  $SiteDefs::ENSEMBL_TMP_DIR                = defer { $SiteDefs::ENSEMBL_TMP_ROOT };
  $SiteDefs::ENSEMBL_USERDATA_DIR           = defer { $SiteDefs::ENSEMBL_USERDATA_ROOT };

  # path to linuxbrew work dir
  $SiteDefs::SHARED_SOFTWARE_PATH = '/home/linuxbrew';

  $SiteDefs::ENSEMBL_EXTERNAL_SEARCHABLE    = 0;

}
1;
