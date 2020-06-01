=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

use strict;

package EnsEMBL::RapidRelease::SiteDefs;

sub update_conf {
  $SiteDefs::ENSEMBL_VERSION          = 100;
  $SiteDefs::ENSEMBL_SUBTYPE          = 'Rapid Release';

  $SiteDefs::NO_REGULATION            = 1;
  $SiteDefs::NO_VARIATION             = 1;
  $SiteDefs::NO_COMPARA               = 1;
  $SiteDefs::ENSEMBL_MART_ENABLED     = 0;

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Falco_tinnunculus'; # Default species

  $SiteDefs::PRODUCTION_NAMES = [qw(
                                    anas_zonorhyncha
                                    balaenoptera_musculus
                                    bubo_bubo
                                    buteo_japonicus
                                    cairina_moschata_domestica
                                    camarhynchus_parvulus
                                    capra_hircus_blackbengal
                                    catharus_ustulatus
                                    clytia_hemisphaerica_gca902728285
                                    corvus_moneduloides
                                    cyclopterus_lumpus
                                    falco_tinnunculus
                                    leptobrachium_leishanense
                                    malurus_cyaneus_samueli
                                    monodon_monoceros
                                    naja_naja
                                    nothobranchius_furzeri
                                    oncorhynchus_kisutch
                                    otus_sunia
                                    ovis_aries_rambouillet
                                    phocoena_sinus
                                    sander_lucioperca
                                    sciurus_vulgaris
                                    strix_occidentalis_caurina
                                    zalophus_californianus
                                  )];
}

1;
