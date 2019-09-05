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
                                  acanthochromis_polyacanthus
                                  amphilophus_citrinellus
                                  amphiprion_ocellaris
                                  amphiprion_percula
                                  anabas_testudineus
                                  anas_platyrhynchos_platyrhynchos
                                  anolis_carolinensis
                                  anser_brachyrhynchus
                                  aotus_nancymaae
                                  apteryx_haastii
                                  apteryx_owenii
                                  apteryx_rowi
                                  astatotilapia_calliptera
                                  astyanax_mexicanus
                                  astyanax_mexicanus_pachon
                                  betta_splendens
                                  bison_bison_bison
                                  bos_indicus_hybrid
                                  bos_mutus
                                  bos_taurus
                                  bos_taurus_hybrid
                                  caenorhabditis_elegans
                                  calidris_pugnax
                                  calidris_pygmaea
                                  callithrix_jacchus
                                  callorhinchus_milii
				                          canis_familiaris
				                          canis_lupus_dingo
                                  capra_hircus
                                  carlito_syrichta
                                  castor_canadensis
                                  cavia_aperea
                                  cavia_porcellus
                                  cebus_capucinus
                                  cercocebus_atys
                                  chelonoidis_abingdonii
                                  chinchilla_lanigera
                                  chlorocebus_sabaeus
                                  choloepus_hoffmanni
                                  chrysemys_picta_bellii
                                  ciona_intestinalis
                                  ciona_savignyi
                                  clupea_harengus
                                  colobus_angolensis_palliatus
                                  cottoperca_gobio
                                  coturnix_japonica
                                  cricetulus_griseus_chok1gshd
                                  cricetulus_griseus_crigri
                                  cricetulus_griseus_picr
                                  crocodylus_porosus
                                  cyanistes_caeruleus
                                  cynoglossus_semilaevis
                                  cyprinodon_variegatus
                                  danio_rerio
                                  dasypus_novemcinctus
                                  denticeps_clupeoides
                                  dipodomys_ordii
                                  dromaius_novaehollandiae
                                  drosophila_melanogaster
                                  echinops_telfairi
                                  electrophorus_electricus
                                  eptatretus_burgeri
                                  equus_caballus
                                  equus_asinus_asinus
                                  erinaceus_europaeus
                                  erpetoichthys_calabaricus
                                  esox_lucius
                                  felis_catus
                                  ficedula_albicollis
                                  fukomys_damarensis
                                  fundulus_heteroclitus
                                  gadus_morhua
                                  gallus_gallus
                                  gambusia_affinis
                                  gasterosteus_aculeatus
                                  gopherus_agassizii
                                  gorilla_gorilla
                                  gouania_willdenowi
                                  haplochromis_burtoni
                                  heterocephalus_glaber_female
                                  heterocephalus_glaber_male
                                  hippocampus_comes
                                  homo_sapiens
                                  hucho_hucho
                                  ictalurus_punctatus
                                  ictidomys_tridecemlineatus
                                  jaculus_jaculus
                                  junco_hyemalis
                                  kryptolebias_marmoratus
                                  labrus_bergylta
                                  larimichthys_crocea
                                  lates_calcarifer
                                  latimeria_chalumnae
                                  lepidothrix_coronata
                                  lepisosteus_oculatus
                                  lonchura_striata_domestica
                                  loxodonta_africana
                                  macaca_fascicularis
                                  macaca_mulatta
                                  macaca_nemestrina
                                  manacus_vitellinus
                                  mandrillus_leucophaeus
                                  marmota_marmota_marmota
                                  mastacembelus_armatus
                                  maylandia_zebra
                                  meleagris_gallopavo
                                  melopsittacus_undulatus
                                  meriones_unguiculatus
                                  mesocricetus_auratus
                                  microcebus_murinus
                                  microtus_ochrogaster
                                  mola_mola
                                  monodelphis_domestica
                                  monopterus_albus
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
                                  mus_spicilegus
                                  mus_spretus
                                  mustela_putorius_furo
                                  myotis_lucifugus
                                  nannospalax_galili
                                  neolamprologus_brichardi
                                  neovison_vison
                                  nomascus_leucogenys
                                  notamacropus_eugenii
                                  notechis_scutatus
                                  nothoprocta_perdicaria
                                  numida_meleagris
                                  ochotona_princeps
                                  octodon_degus
                                  oreochromis_niloticus
                                  ornithorhynchus_anatinus
                                  oryctolagus_cuniculus
                                  oryzias_latipes
                                  oryzias_latipes_hni
                                  oryzias_latipes_hsok
                                  oryzias_melastigma
                                  otolemur_garnettii
                                  ovis_aries
                                  pan_paniscus
                                  pan_troglodytes
                                  panthera_pardus
                                  panthera_tigris_altaica
                                  papio_anubis
                                  parambassis_ranga
                                  paramormyrops_kingsleyae 
                                  parus_major
                                  pelodiscus_sinensis
                                  periophthalmus_magnuspinnatus
                                  peromyscus_maniculatus_bairdii
                                  petromyzon_marinus
                                  phascolarctos_cinereus
                                  piliocolobus_tephrosceles
                                  poecilia_formosa
                                  poecilia_latipinna
                                  poecilia_mexicana
                                  poecilia_reticulata
                                  pogona_vitticeps
                                  pongo_abelii
                                  procavia_capensis
                                  prolemur_simus
                                  propithecus_coquereli
                                  pteropus_vampyrus
                                  pundamilia_nyererei
                                  pygocentrus_nattereri
                                  rattus_norvegicus
                                  rhinopithecus_bieti
                                  rhinopithecus_roxellana
                                  saccharomyces_cerevisiae
                                  saimiri_boliviensis_boliviensis
                                  salvator_merianae
                                  sarcophilus_harrisii
                                  scleropages_formosus
                                  scophthalmus_maximus
                                  serinus_canaria
                                  seriola_dumerili
                                  seriola_lalandi_dorsalis
                                  sorex_araneus
                                  sphenodon_punctatus
                                  spermophilus_dauricus
                                  stegastes_partitus
                                  sus_scrofa
                                  sus_scrofa_bamei
                                  sus_scrofa_berkshire
                                  sus_scrofa_hampshire
                                  sus_scrofa_jinhua
                                  sus_scrofa_landrace
                                  sus_scrofa_largewhite
                                  sus_scrofa_meishan
                                  sus_scrofa_pietrain
                                  sus_scrofa_rongchang
                                  sus_scrofa_tibetan
                                  sus_scrofa_wuzhishan
                                  sus_scrofa_usmarc
                                  taeniopygia_guttata
                                  takifugu_rubripes
                                  tetraodon_nigroviridis
                                  theropithecus_gelada
                                  tupaia_belangeri
                                  tursiops_truncatus
                                  urocitellus_parryii
                                  ursus_americanus
                                  ursus_maritimus
                                  vicugna_pacos
                                  vombatus_ursinus
                                  vulpes_vulpes 
                                  xenopus_tropicalis
                                  xiphophorus_couchianus
                                  xiphophorus_maculatus
                                  zonotrichia_albicollis
                                )];
}

1;
