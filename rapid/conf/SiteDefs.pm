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
  $SiteDefs::FIRST_RELEASE_VERSION    = 100; ## Don't update this!

  $SiteDefs::NO_REGULATION            = 1;
  $SiteDefs::NO_VARIATION             = 1;
  $SiteDefs::NO_COMPARA               = 1;
  $SiteDefs::ENSEMBL_MART_ENABLED     = 0;

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Camarhynchus_parvulus'; # Default species

  $SiteDefs::PRODUCTION_NAMES = [qw(
				anabas_testudineus
				anas_zonorhyncha
				archocentrus_centrarchus
				balaenoptera_musculus
				bubo_bubo
				buteo_japonicus
				cairina_moschata_domestica
				camarhynchus_parvulus
				canis_lupus_familiarisgermanshepherd
				capra_hircus_blackbengal
				capra_hircus_sanclemente
				catharus_ustulatus
				cervus_hanglu_yarkandensis
				clytia_hemisphaerica_gca902728285
				corvus_moneduloides
				cyclopterus_lumpus
				falco_tinnunculus
				gymnodraco_acuticeps
				leptobrachium_leishanense
				malurus_cyaneus_samueli
				marmota_flaviventris
				marmota_himalayana
				mastacembelus_armatus
				melopsittacus_undulatus
				monodon_monoceros
				naja_naja
				nothobranchius_furzeri
				odocoileus_hemionus_hemionus
				oncorhynchus_kisutch
				otus_sunia
				ovis_aries_rambouillet
				periophthalmus_magnuspinnatus
				phocoena_sinus
				phyllostomus_discolor
				pseudochaenichthys_georgianus
				rhizomys_pruinosus
				sander_lucioperca
				sarcophilus_harrisii
				sciurus_vulgaris
				strix_occidentalis_caurina
				syncerus_caffer
				taeniopygia_guttata
				thalassophryne_amazonica
				thamnophis_elegans
				tragelaphus_strepsiceros
				trichechus_manatus_latirostris
				triplophysa_tibetana
				verasper_variegatus
				vulpes_lagopus
				zalophus_californianus
				accipiter_gentilis
				acipenser_ruthenus
				amblyraja_radiata
				aptenodytes_patagonicus
				bubalus_bubalis
				chrysemys_picta
				eudyptes_chrysocome
				eudyptes_filholi
				eudyptes_moseleyi
				eudyptes_pachyrhynchus
				eudyptes_robustus
				eudyptes_sclateri
				gadus_morhua
				molothrus_ater
				neomonachus_schauinslandi
				notolabrus_celidotus
				oncorhynchus_nerka
				pantherophis_guttatus
				passer_domesticus
				pipra_filicauda
				poecile_atricapillus
				thunnus_orientalis
				trachinotus_ovatus
				trachypithecus_francoisi
				triplophysa_siluroides
				ursus_arctos_horribilis
				vicugna_pacos_huacaya
				zootoca_vivipara
			)];

  $SiteDefs::NEW_SPECIES = [qw(
				accipiter_gentilis
				acipenser_ruthenus
        actinia_equina_gca011057435
				amblyraja_radiata
				aptenodytes_patagonicus
				bubalus_bubalis
				chrysemys_picta
				eudyptes_chrysocome
				eudyptes_filholi
				eudyptes_moseleyi
				eudyptes_pachyrhynchus
				eudyptes_robustus
				eudyptes_sclateri
				gadus_morhua
				molothrus_ater
				neomonachus_schauinslandi
				notolabrus_celidotus
				oncorhynchus_nerka
				pantherophis_guttatus
				passer_domesticus
				pipra_filicauda
				poecile_atricapillus
				thunnus_orientalis
				trachinotus_ovatus
				trachypithecus_francoisi
				triplophysa_siluroides
				triplophysa_tibetana
				ursus_arctos_horribilis
				vicugna_pacos_huacaya
				zootoca_vivipara
  )];
}

1;
