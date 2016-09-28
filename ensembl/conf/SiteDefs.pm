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

## This hash is used to configure the species available in this
## copy of EnsEMBL - comment out any lines which are not relevant
## If you add a new species MAKE sure that one of the values of the
## array is the "SPECIES_CODE" defined in the species.ini file

#-------------------- mammals
  $SiteDefs::__species_aliases{ 'Ailuropoda_melanoleuca'            } = [qw(am amel panda)];   
  $SiteDefs::__species_aliases{ 'Bos_taurus'                        } = [qw(bt btau cow moo)];
  $SiteDefs::__species_aliases{ 'Callithrix_jacchus'                } = [qw(cj cjac marmoset)]; 
  $SiteDefs::__species_aliases{ 'Canis_familiaris'                  } = [qw(cf cfam dog)]; 
  $SiteDefs::__species_aliases{ 'Cavia_porcellus'                   } = [qw(cp cpor guineapig)];
  $SiteDefs::__species_aliases{ 'Chlorocebus_sabaeus'               } = [qw(csab chlsab csabaeus vervet monkey-AGM chlorocebus_sabaeus)];
  $SiteDefs::__species_aliases{ 'Choloepus_hoffmanni'               } = [qw(ch chof sloth)];
  $SiteDefs::__species_aliases{ 'Dasypus_novemcinctus'              } = [qw(dn dnov dasypus armadillo)];
  $SiteDefs::__species_aliases{ 'Dipodomys_ordii'                   } = [qw(do kangaroorat)];
  $SiteDefs::__species_aliases{ 'Echinops_telfairi'                 } = [qw(et etel echinops tenrec)];
  $SiteDefs::__species_aliases{ 'Equus_caballus'                    } = [qw(ec horse)];
  $SiteDefs::__species_aliases{ 'Erinaceus_europaeus'               } = [qw(ee eeur hedgehog)];
  $SiteDefs::__species_aliases{ 'Gorilla_gorilla'                   } = [qw(gg ggo ggor kong gorilla)]; 
  $SiteDefs::__species_aliases{ 'Felis_catus'                       } = [qw(fc fcat cat)];
  $SiteDefs::__species_aliases{ 'Homo_sapiens'                      } = [qw(hs hsap human man default)]; 
  $SiteDefs::__species_aliases{ 'Ictidomys_tridecemlineatus'        } = [qw(it itri squirrel ictidomys)];
  $SiteDefs::__species_aliases{ 'Latimeria_chalumnae'               } = [qw(lc ltch coelacanth living fossil)];
  $SiteDefs::__species_aliases{ 'Loxodonta_africana'                } = [qw(la lafr elephant africana loxodontai hathi nellie dumbo)];
  $SiteDefs::__species_aliases{ 'Oryctolagus_cuniculus'             } = [qw(oc ocun rabbit bugs bunny hutch harvey)];
  $SiteDefs::__species_aliases{ 'Macaca_mulatta'                    } = [qw(mmu mmul rhesus macaque macaca)];
  $SiteDefs::__species_aliases{ 'Macropus_eugenii'                  } = [qw(me meug wallaby)];
  $SiteDefs::__species_aliases{ 'Microcebus_murinus'                } = [qw(mmur lemur)];
  $SiteDefs::__species_aliases{ 'Monodelphis_domestica'             } = [qw(md mdom monodelphis opossum)];
  $SiteDefs::__species_aliases{ 'Mus_musculus'                      } = [qw(mm mmus mouse mus)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_129S1_SvImJ'          } = [qw(mus_musculus_129s1svimj mouse_129s1svimj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_A_J'                  } = [qw(mus_musculus_aj         mouse_aj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_AKR_J'                } = [qw(mus_musculus_akrj       mouse_akrj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_BALB_cJ'              } = [qw(mus_musculus_balbcj     mouse_balbcj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_C3H_HeJ'              } = [qw(mus_musculus_c3hhej     mouse_c3hhej)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_C57BL_6NJ'            } = [qw(mus_musculus_c57bl6nj   mouse_c57bl6nj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_CAST_EiJ'             } = [qw(mus_musculus_casteij    mouse_casteij)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_CBA_J'                } = [qw(mus_musculus_cbaj       mouse_cbaj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_DBA_2J'               } = [qw(mus_musculus_dba2j      mouse_dba2j)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_FVB_NJ'               } = [qw(mus_musculus_fvbnj      mouse_fvbnj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_LP_J'                 } = [qw(mus_musculus_lpj        mouse_lpj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_NOD_ShiLtJ'           } = [qw(mus_musculus_nodshiltj  mouse_nodshiltj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_NZO_HlLtJ'            } = [qw(mus_musculus_nzohlltj   mouse_nzohlltj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_PWK_PhJ'              } = [qw(mus_musculus_pwkphj     mouse_pwkphj)];
  $SiteDefs::__species_aliases{ 'Mus_musculus_WSB_EiJ'              } = [qw(mus_musculus_wsbeij     mouse_wsbeij)];
  $SiteDefs::__species_aliases{ 'Mus_spretus_SPRET_EiJ'             } = [qw(mus_spretus             mouse_spreteij)];
  $SiteDefs::__species_aliases{ 'Mustela_putorius_furo'             } = [qw(mp mput mustela ferret)];
  $SiteDefs::__species_aliases{ 'Myotis_lucifugus'                  } = [qw(ml mluc microbat myotis)];
  $SiteDefs::__species_aliases{ 'Nomascus_leucogenys'               } = [qw(nl nleu gibbon nomascus)];
  $SiteDefs::__species_aliases{ 'Ochotona_princeps'                 } = [qw(op pika pikachu)];
  $SiteDefs::__species_aliases{ 'Ornithorhynchus_anatinus'          } = [qw(oa oana platypus)];
  $SiteDefs::__species_aliases{ 'Otolemur_garnettii'                } = [qw(og ogar bushbaby otolemur)];
  $SiteDefs::__species_aliases{ 'Ovis_aries'                        } = [qw(oa oar sheep ovis)];
  $SiteDefs::__species_aliases{ 'Pan_troglodytes'                   } = [qw(pt ptro chimp)];
  $SiteDefs::__species_aliases{ 'Papio_anubis'                      } = [qw(pa panu baboon panubis)];
  $SiteDefs::__species_aliases{ 'Pongo_abelii'                      } = [qw(pp Pongo_pygmaeus orang orangutan librarian ook)];
  $SiteDefs::__species_aliases{ 'Procavia_capensis'                 } = [qw(pc hyrax dassy dassie pimbi)];
  $SiteDefs::__species_aliases{ 'Pteropus_vampyrus'                 } = [qw(pv megabat flyingfox)];
  $SiteDefs::__species_aliases{ 'Rattus_norvegicus'                 } = [qw(rn rnor rat)];
  $SiteDefs::__species_aliases{ 'Sarcophilus_harrisii'              } = [qw(sh devil tasmanian devil)];
  $SiteDefs::__species_aliases{ 'Sorex_araneus'                     } = [qw(sa)];
  $SiteDefs::__species_aliases{ 'Sus_scrofa'                        } = [qw(ss sscr pig sus oink porky)];
  $SiteDefs::__species_aliases{ 'Tarsius_syrichta'                  } = [qw(ts tarsier gremlin)];
  $SiteDefs::__species_aliases{ 'Tupaia_belangeri'                  } = [qw(tb tbel treeshrew shrew)];
  $SiteDefs::__species_aliases{ 'Tursiops_truncatus'                } = [qw(tt dolphin flipper)];
  $SiteDefs::__species_aliases{ 'Vicugna_pacos'                     } = [qw(lp alpaca)];
#-------------------- birds
  $SiteDefs::__species_aliases{ 'Anas_platyrhynchos'                } = [qw(ap apla duck mallard anas platyrhynchos)];
  $SiteDefs::__species_aliases{ 'Ficedula_albicollis'               } = [qw(fa falb flycatcher ficalb falbicollis)];
  $SiteDefs::__species_aliases{ 'Gallus_gallus'                     } = [qw(ggal chicken)];
  $SiteDefs::__species_aliases{ 'Meleagris_gallopavo'               } = [qw(mg mgal turkey meleagris)];
  $SiteDefs::__species_aliases{ 'Taeniopygia_guttata'               } = [qw(tg taegut taeniopygia zebrafinch)];
#-------------------- fish
  $SiteDefs::__species_aliases{ 'Astyanax_mexicanus'                } = [qw(am amex cave fish)];
  $SiteDefs::__species_aliases{ 'Danio_rerio'                       } = [qw(dr drer zfish zebrafish)];
  $SiteDefs::__species_aliases{ 'Gasterosteus_aculeatus'            } = [qw(ga gacu stickleback gasterosteus)];
  $SiteDefs::__species_aliases{ 'Lepisosteus_oculatus'              } = [qw(lo locu spotted gar)];
  $SiteDefs::__species_aliases{ 'Poecilia_formosa'                  } = [qw(pf pfor amazon molly)];
  $SiteDefs::__species_aliases{ 'Oreochromis_niloticus'             } = [qw(on onil nile tilapia)];
  $SiteDefs::__species_aliases{ 'Oryzias_latipes'                   } = [qw(ol olat medaka)];
  $SiteDefs::__species_aliases{ 'Takifugu_rubripes'                 } = [qw(fr trub ffish fugu takifugu f_rubripes fugu_rubripes)];
  $SiteDefs::__species_aliases{ 'Tetraodon_nigroviridis'            } = [qw(tn tnig tetraodon)];
  $SiteDefs::__species_aliases{ 'Gadus_morhua'                      } = [qw(gm gmor gadus cod)];
  $SiteDefs::__species_aliases{ 'Xiphophorus_maculatus'             } = [qw(xm xmac xipho platyfish)];
#-------------------- amphibians
  $SiteDefs::__species_aliases{ 'Pelodiscus_sinensis'               } = [qw(ps chinese softshell turtle)];
  $SiteDefs::__species_aliases{ 'Xenopus_tropicalis'                } = [qw(xt xtro xenopus frog)];
#-------------------- reptiles
  $SiteDefs::__species_aliases{ 'Anolis_carolinensis'               } = [qw(ac anolis anole lizard)];
#-------------------- flies
# $SiteDefs::__species_aliases{ 'Aedes_aegypti'                     } = [qw(aa aaeg aedes )];
# $SiteDefs::__species_aliases{ 'Anopheles_gambiae'                 } = [qw(ag agam mosquito mos anopheles)];
# $SiteDefs::__species_aliases{ 'Apis_mellifera'                    } = [qw(am amel honeybee bee)];
  $SiteDefs::__species_aliases{ 'Drosophila_melanogaster'           } = [qw(dm dmel fly)];
#-------------------- worms
# $SiteDefs::__species_aliases{ 'Caenorhabditis_briggsae'           } = [qw(cb cbri briggsae)];
  $SiteDefs::__species_aliases{ 'Caenorhabditis_elegans'            } = [qw(ce cele worm elegans)];
  $SiteDefs::__species_aliases{ 'Ciona_intestinalis'                } = [qw(ci cint seasquirti cionai)];
  $SiteDefs::__species_aliases{ 'Ciona_savignyi'                    } = [qw(cs csav seasquirts cionas)];
  $SiteDefs::__species_aliases{ 'Petromyzon_marinus'                } = [qw(pm lamprey sealamprey )];
#-------------------- yeast
  $SiteDefs::__species_aliases{ 'Saccharomyces_cerevisiae'          } = [qw(sc scer yeast saccharomyces )];
}

1;
