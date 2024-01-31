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
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Mus_musculus'; # Secondary species

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
                                  acanthochromis_polyacanthus
                                  accipiter_nisus
                                  ailuropoda_melanoleuca
                                  amazona_collaria
                                  amphilophus_citrinellus
                                  amphiprion_ocellaris
                                  amphiprion_percula
                                  anabas_testudineus
                                  anas_platyrhynchos
                                  anas_platyrhynchos_platyrhynchos
                                  anas_zonorhyncha
                                  anolis_carolinensis
                                  anser_brachyrhynchus
                                  anser_cygnoides
                                  aotus_nancymaae
                                  apteryx_haastii
                                  apteryx_owenii
                                  apteryx_rowi
                                  aquila_chrysaetos_chrysaetos
                                  astatotilapia_calliptera
                                  astyanax_mexicanus
                                  astyanax_mexicanus_pachon
                                  athene_cunicularia
                                  balaenoptera_musculus
                                  betta_splendens
                                  bison_bison_bison
                                  bos_grunniens
                                  bos_indicus_hybrid
                                  bos_mutus
                                  bos_taurus
                                  bos_taurus_hybrid
                                  bubo_bubo
                                  buteo_japonicus
                                  caenorhabditis_elegans
                                  cairina_moschata_domestica
                                  calidris_pugnax
                                  calidris_pygmaea
                                  callithrix_jacchus
                                  callorhinchus_milii
                                  camarhynchus_parvulus
                                  camelus_dromedarius
                                  canis_lupus_dingo
                                  canis_lupus_familiaris
                                  canis_lupus_familiarisbasenji
                                  canis_lupus_familiarisboxer
                                  canis_lupus_familiarisgreatdane
                                  canis_lupus_familiarisgsd
                                  capra_hircus
                                  capra_hircus_blackbengal
                                  carassius_auratus
                                  carlito_syrichta
                                  castor_canadensis
                                  catagonus_wagneri
                                  catharus_ustulatus
                                  cavia_aperea
                                  cavia_porcellus
                                  cebus_imitator
                                  cercocebus_atys
                                  cervus_hanglu_yarkandensis
                                  chelonoidis_abingdonii
                                  chelydra_serpentina
                                  chinchilla_lanigera
                                  chlorocebus_sabaeus
                                  choloepus_hoffmanni
                                  chrysolophus_pictus
                                  chrysemys_picta_bellii
                                  ciona_intestinalis
                                  ciona_savignyi
                                  clupea_harengus
                                  colobus_angolensis_palliatus
                                  corvus_moneduloides
                                  cottoperca_gobio
                                  coturnix_japonica
                                  cricetulus_griseus_chok1gshd
                                  cricetulus_griseus_crigri
                                  cricetulus_griseus_picr
                                  crocodylus_porosus
                                  cyanistes_caeruleus
                                  cyclopterus_lumpus
                                  cynoglossus_semilaevis
                                  cyprinodon_variegatus
                                  cyprinus_carpio_carpio
                                  cyprinus_carpio_germanmirror
                                  cyprinus_carpio_hebaored
                                  cyprinus_carpio_huanghe
                                  danio_rerio
                                  dasypus_novemcinctus
                                  delphinapterus_leucas
                                  denticeps_clupeoides
                                  dicentrarchus_labrax
                                  dipodomys_ordii
                                  dromaius_novaehollandiae
                                  drosophila_melanogaster
                                  echeneis_naucrates
                                  echinops_telfairi
                                  electrophorus_electricus
                                  eptatretus_burgeri
                                  equus_caballus
                                  equus_asinus
                                  erinaceus_europaeus
                                  erpetoichthys_calabaricus
                                  erythrura_gouldiae
                                  esox_lucius
                                  falco_tinnunculus
                                  felis_catus
                                  ficedula_albicollis
                                  fukomys_damarensis
                                  fundulus_heteroclitus
                                  gadus_morhua
                                  gadus_morhua_gca010882105v1
                                  gallus_gallus
                                  gallus_gallus_gca016700215v2
                                  gallus_gallus_gca000002315v5
                                  gambusia_affinis
                                  gasterosteus_aculeatus
                                  gasterosteus_aculeatus_gca006229185v1
                                  gasterosteus_aculeatus_gca006232265v1
                                  gasterosteus_aculeatus_gca006232285v1
                                  geospiza_fortis
                                  gopherus_agassizii
                                  gopherus_evgoodei
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
                                  laticauda_laticaudata
                                  latimeria_chalumnae
                                  lepidothrix_coronata
                                  lepisosteus_oculatus
                                  leptobrachium_leishanense
                                  lonchura_striata_domestica
                                  loxodonta_africana
                                  lynx_canadensis
                                  macaca_fascicularis
                                  macaca_mulatta
                                  macaca_nemestrina
                                  malurus_cyaneus_samueli
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
                                  monodon_monoceros
                                  monopterus_albus
                                  moschus_moschiferus
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
                                  myripristis_murdjan
                                  naja_naja
                                  nannospalax_galili
                                  neogobius_melanostomus
                                  neolamprologus_brichardi
                                  neovison_vison
                                  nomascus_leucogenys
                                  notamacropus_eugenii
                                  notechis_scutatus
                                  nothoprocta_perdicaria
                                  nothobranchius_furzeri
                                  numida_meleagris
                                  ochotona_princeps
                                  octodon_degus
                                  oncorhynchus_kisutch
                                  oncorhynchus_mykiss
                                  oncorhynchus_tshawytscha
                                  oreochromis_aureus
                                  oreochromis_niloticus
                                  ornithorhynchus_anatinus
                                  oryctolagus_cuniculus
                                  oryzias_javanicus
                                  oryzias_latipes
                                  oryzias_latipes_hni
                                  oryzias_latipes_hsok
                                  oryzias_melastigma
                                  oryzias_sinensis
                                  otolemur_garnettii
                                  otus_sunia
                                  ovis_aries
                                  ovis_aries_rambouillet
                                  pan_paniscus
                                  pan_troglodytes
                                  panthera_leo
                                  panthera_pardus
                                  panthera_tigris_altaica
                                  papio_anubis
                                  parambassis_ranga
                                  paramormyrops_kingsleyae 
                                  parus_major
                                  pavo_cristatus
                                  pelodiscus_sinensis
                                  pelusios_castaneus
                                  periophthalmus_magnuspinnatus
                                  peromyscus_maniculatus_bairdii
                                  petromyzon_marinus
                                  phascolarctos_cinereus
                                  phasianus_colchicus
                                  phocoena_sinus
                                  physeter_catodon
                                  piliocolobus_tephrosceles
                                  podarcis_muralis
                                  poecilia_formosa
                                  poecilia_latipinna
                                  poecilia_mexicana
                                  poecilia_reticulata
                                  pogona_vitticeps
                                  pongo_abelii
                                  pseudonaja_textilis
                                  procavia_capensis
                                  prolemur_simus
                                  propithecus_coquereli
                                  pteropus_vampyrus
                                  pundamilia_nyererei
                                  pygocentrus_nattereri
                                  rattus_norvegicus
                                  rattus_norvegicus_shrspbbbutx
                                  rattus_norvegicus_shrutx
                                  rattus_norvegicus_wkybbb
                                  rhinolophus_ferrumequinum
                                  rhinopithecus_bieti
                                  rhinopithecus_roxellana
                                  saccharomyces_cerevisiae
                                  saimiri_boliviensis_boliviensis
                                  salarias_fasciatus
                                  salmo_salar
                                  salmo_salar_gca021399835v1
                                  salmo_salar_gca923944775v1
                                  salmo_salar_gca931346935v2
                                  salmo_trutta
                                  salvator_merianae
                                  sander_lucioperca
                                  sarcophilus_harrisii
                                  sciurus_vulgaris
                                  scleropages_formosus
                                  scophthalmus_maximus
                                  serinus_canaria
                                  seriola_dumerili
                                  seriola_lalandi_dorsalis
                                  sinocyclocheilus_anshuiensis
                                  sinocyclocheilus_grahami
                                  sinocyclocheilus_rhinocerous
                                  sorex_araneus
                                  sparus_aurata
                                  spermophilus_dauricus
                                  sphaeramia_orbicularis
                                  sphenodon_punctatus
                                  stachyris_ruficeps
                                  stegastes_partitus
                                  strigops_habroptila
                                  strix_occidentalis_caurina
                                  struthio_camelus_australis
                                  suricata_suricatta
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
                                  terrapene_carolina_triunguis
                                  tetraodon_nigroviridis
                                  theropithecus_gelada
                                  tupaia_belangeri
                                  tursiops_truncatus
                                  urocitellus_parryii
                                  ursus_americanus
                                  ursus_thibetanus_thibetanus
                                  ursus_maritimus
                                  varanus_komodoensis
                                  vicugna_pacos
                                  vombatus_ursinus
                                  vulpes_vulpes 
                                  xenopus_tropicalis
                                  xiphophorus_couchianus
                                  xiphophorus_maculatus
                                  zalophus_californianus
                                  zosterops_lateralis_melanops
                                  zonotrichia_albicollis
                                )];
}

1;
