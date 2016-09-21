=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Mus_musculus'; # Secondary species

  $SiteDefs::ENSEMBL_REST_URL           = 'http://rest.ensembl.org';  # URL for the REST API
  $SiteDefs::ENSEMBL_REST_DOC_URL       = 'https://github.com/Ensembl/ensembl-rest/wiki';

  $SiteDefs::GXA                        = 1; #enabling gene expression atlas

## This array is used to configure the species available in this
## instance of EnsEMBL - the names should correspond to the 
## production name of each species' database

  $SiteDefs::PRODUCTION_NAMES = [qw(
                                  felis_catus                                        
                                  homo_sapiens
                                  mus_musculus
                                )];
=pod
  $SiteDefs::PRODUCTION_NAMES = [qw(
                                  ailuropoda_melanoleuca
                                  anas_platyrhynchos
                                  anolis_carolinensis
                                  astyanax_mexicanus
                                  bos_taurus
                                  caenorhabditis_elegans
                                  callithrix_jacchus
                                  cavia_porcellus
                                  chlorocebus_sabaeus
                                  choloepus_hoffmanni
                                  ciona_intestinalis
                                  ciona_savignyi
                                  danio_rerio
                                  dasypus_novemcinctus
                                  dipodomys_ordii
                                  drosophila_melanogaster
                                  echinops_telfairi
                                  equus_caballus
                                  erinaceus_europaeus
                                  felis_catus                                        
                                  ficedula_albicollis
                                  gadus_morhua
                                  gallus_gallus
                                  gasterosteus_aculeatus
                                  gorilla_gorilla
                                  homo_sapiens
                                  ictidomys_tridecemlineatus
                                  latimeria_chalumnae
                                  lepisosteus_oculatus
                                  loxodonta_africana
                                  macaca_mulatta
                                  macropus_eugenii
                                  meleagris_gallopavo
                                  microcebus_murinus
                                  monodelphis_domestica
                                  mus_musculus
                                  mus_musculus_129s1svimj
                                  mus_musculus_aj
                                  mus_musculus_akrj
                                  mus_musculus_balbcj
                                  mus_musculus_c3hhej
                                  mus_musculus_c57bl6nj
                                  mus_musculus_casteij
                                  mus_musculus_cbaj
                                  mus_musculus_dba2j
                                  mus_musculus_fvbnj
                                  mus_musculus_lpj
                                  mus_musculus_nodshiltj
                                  mus_musculus_nzohlltj
                                  mus_musculus_pwkphj
                                  mus_musculus_wsbeij
                                  mus_spretus
                                  mustela_putorius_furo
                                  myotis_lucifugus
                                  nomascus_leucogenys
                                  ochotona_princeps
                                  oreochromis_niloticus
                                  ornithorhynchus_anatinus
                                  oryctolagus_cuniculus
                                  oryzias_latipes
                                  otolemur_garnettii
                                  ovis_aries
                                  pan_troglodytes
                                  papio_anubis
                                  pelodiscus_sinensis
                                  petromyzon_marinus
                                  poecilia_formosa
                                  pongo_abelii
                                  procavia_capensis
                                  pteropus_vampyrus
                                  rattus_norvegicus
                                  saccharomyces_cerevisiae
                                  sarcophilus_harrisii
                                  sorex_araneus
                                  sus_scrofa
                                  taeniopygia_guttata
                                  takifugu_rubripes
                                  tarsius_syrichta
                                  tetraodon_nigroviridis
                                  tupaia_belangeri
                                  tursiops_truncatus
                                  vicugna_pacos
                                  xenopus_tropicalis
                                  xiphophorus_maculatus
                                )];

=cut

}

1;
