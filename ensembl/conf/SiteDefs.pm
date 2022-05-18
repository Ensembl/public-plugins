=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Ensembl::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Saccharomyces_cerevisiae'; # 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Saccharomyces_cerevisiae'; #'Mus_musculus'; # Secondary species

  $SiteDefs::ENSEMBL_PUBLIC_DB          = 'ensembldb.ensembl.org';

  $SiteDefs::SPECIES_IMAGE_DIR          = defer { $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/ensembl/'.$SiteDefs::DEFAULT_SPECIES_IMG_DIR };
  
  $SiteDefs::ARCHIVE_BASE_DOMAIN        = 'archive.ensembl.org';
  $SiteDefs::ENSEMBL_REST_URL           = 'https://rest.ensembl.org';  # URL for the REST API
  $SiteDefs::ENSEMBL_REST_DOC_URL       = 'https://github.com/Ensembl/ensembl-rest/wiki';

  $SiteDefs::GXA                        = 1; #enabling gene expression atlas

  ## Flags used by docs homepage
  $SiteDefs::HAS_TUTORIALS              = 1;
  $SiteDefs::HAS_ANNOTATION             = 1;
  $SiteDefs::HAS_VIRTUAL_MACHINE        = 1;

  $SiteDefs::ENSEMBL_TAXONOMY_DIVISION_FILE  = $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/ensembl/conf/taxon_tree.json';

## This array is used to configure the species available in this
## instance of EnsEMBL - the names should correspond to the 
## production name of each species' database

  $SiteDefs::PRODUCTION_NAMES = [qw(
                                  saccharomyces_cerevisiae
                                )];
}

1;
