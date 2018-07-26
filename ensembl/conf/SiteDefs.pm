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

package EnsEMBL::Ensembl::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Mus_musculus'; # Secondary species

  $SiteDefs::ARCHIVE_BASE_DOMAIN        = 'archive.ensembl.org';
  $SiteDefs::ENSEMBL_REST_URL           = 'https://rest.ensembl.org';  # URL for the REST API
  $SiteDefs::ENSEMBL_REST_DOC_URL       = 'https://github.com/Ensembl/ensembl-rest/wiki';

  $SiteDefs::GXA                        = 1; #enabling gene expression atlas

## This array is used to configure the species available in this
## instance of EnsEMBL - the names should correspond to the 
## production name of each species' database

  $SiteDefs::PRODUCTION_NAMES = [qw(
                                  ailuropoda_melanoleuca
                                  anas_platyrhynchos
                                  anolis_carolinensis
                                  aotus_nancymaae
                                  astyanax_mexicanus
                                  bos_taurus
                                  caenorhabditis_elegans
                                  callithrix_jacchus
				                          canis_familiaris
                                  capra_hircus
                                  carlito_syrichta
                                  cavia_aperea
                                  cavia_porcellus
                                  cebus_capucinus
                                  cercocebus_atys
                                  chinchilla_lanigera
                                  chlorocebus_sabaeus
                                  choloepus_hoffmanni
                                  ciona_intestinalis
                                  ciona_savignyi
                                  colobus_angolensis_palliatus
                                  cricetulus_griseus_chok1gshd
                                  cricetulus_griseus_crigri
                                  danio_rerio
                                  dasypus_novemcinctus
                                  dipodomys_ordii
                                  drosophila_melanogaster
                                  echinops_telfairi
                                  eptatretus_burgeri
                                  equus_caballus
                                  erinaceus_europaeus
                                  felis_catus
                                  ficedula_albicollis
                                  fukomys_damarensis
                                  gadus_morhua
                                  gallus_gallus
                                  gasterosteus_aculeatus
                                  gorilla_gorilla
                                  heterocephalus_glaber_female
                                  heterocephalus_glaber_male
                                  homo_sapiens
                                  ictidomys_tridecemlineatus
                                  jaculus_jaculus
                                  latimeria_chalumnae
                                  lepisosteus_oculatus
                                  loxodonta_africana
                                  macaca_fascicularis
                                  macaca_mulatta
                                  macaca_nemestrina
                                  mandrillus_leucophaeus
                                  meleagris_gallopavo
                                  mesocricetus_auratus
                                  microcebus_murinus
                                  microtus_ochrogaster
                                  monodelphis_domestica
                                  mus_caroli
                                  mus_pahari
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
                                  nannospalax_galili
                                  nomascus_leucogenys
                                  notamacropus_eugenii
                                  ochotona_princeps
                                  octodon_degus
                                  oreochromis_niloticus
                                  ornithorhynchus_anatinus
                                  oryctolagus_cuniculus
                                  oryzias_latipes
                                  otolemur_garnettii
                                  ovis_aries
                                  pan_paniscus
                                  pan_troglodytes
                                  papio_anubis
                                  pelodiscus_sinensis
                                  peromyscus_maniculatus_bairdii
                                  petromyzon_marinus
                                  panthera_pardus
                                  panthera_tigris_altaica
                                  poecilia_formosa
                                  pongo_abelii
                                  procavia_capensis
                                  propithecus_coquereli
                                  pteropus_vampyrus
                                  rattus_norvegicus
                                  rhinopithecus_bieti
                                  rhinopithecus_roxellana
                                  saccharomyces_cerevisiae
                                  saimiri_boliviensis_boliviensis
                                  sarcophilus_harrisii
                                  sorex_araneus
                                  sus_scrofa
                                  taeniopygia_guttata
                                  takifugu_rubripes
                                  tetraodon_nigroviridis
                                  tupaia_belangeri
                                  tursiops_truncatus
                                  vicugna_pacos
                                  xenopus_tropicalis
                                  xiphophorus_maculatus

                                  acanthochromis_polyacanthus
                                  amphilophus_citrinellus
                                  amphiprion_ocellaris
                                  amphiprion_percula
                                  anabas_testudineus
                                  astatotilapia_calliptera
                                  cynoglossus_semilaevis
                                  cyprinodon_variegatus
                                  esox_lucius
                                  fundulus_heteroclitus
                                  gambusia_affinis
                                  haplochromis_burtoni
                                  hippocampus_comes
                                  ictalurus_punctatus
                                  kryptolebias_marmoratus
                                  labrus_bergylta
                                  mastacembelus_armatus
                                  maylandia_zebra
                                  mola_mola
                                  monopterus_albus
                                  neolamprologus_brichardi
                                  oryzias_latipes_hni
                                  oryzias_latipes_hsok
                                  oryzias_melastigma
                                  paramormyrops_kingsleyae 
                                  periophthalmus_magnuspinnatus
                                  poecilia_latipinna
                                  poecilia_mexicana
                                  poecilia_reticulata
                                  pundamilia_nyererei
                                  pygocentrus_nattereri
                                  scleropages_formosus
                                  scophthalmus_maximus
                                  seriola_dumerili
                                  seriola_lalandi_dorsalis
                                  stegastes_partitus
                                  xiphophorus_couchianus

                                )];
}

1;
