package EnsEMBL::Ensembl::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Mus_musculus'; # Secondary species

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
  $SiteDefs::__species_aliases{ 'Choloepus_hoffmanni'               } = [qw(ch chof sloth)];
  $SiteDefs::__species_aliases{ 'Dasypus_novemcinctus'              } = [qw(dn dnov dasypus armadillo)];
  $SiteDefs::__species_aliases{ 'Dipodomys_ordii'                   } = [qw(do kangaroorat)];
  $SiteDefs::__species_aliases{ 'Echinops_telfairi'                 } = [qw(et etel echinops tenrec)];
  $SiteDefs::__species_aliases{ 'Equus_caballus'                    } = [qw(ec horse)];
  $SiteDefs::__species_aliases{ 'Erinaceus_europaeus'               } = [qw(ee eeur hedgehog)];
  $SiteDefs::__species_aliases{ 'Gorilla_gorilla'                   } = [qw(ggo kong gorilla)]; 
  $SiteDefs::__species_aliases{ 'Felis_catus'                       } = [qw(fc fcat cat)];
  $SiteDefs::__species_aliases{ 'Gorilla_gorilla'                   } = [qw(gg ggor gorilla kong)]; 
  $SiteDefs::__species_aliases{ 'Homo_sapiens'                      } = [qw(hs hsap human man default)]; 
  $SiteDefs::__species_aliases{ 'Latimeria_chalumnae'               } = [qw(lc ltch coelacanth living fossil)];
  $SiteDefs::__species_aliases{ 'Loxodonta_africana'                } = [qw(la lafr elephant africana loxodontai hathi nellie dumbo)];
  $SiteDefs::__species_aliases{ 'Oryctolagus_cuniculus'             } = [qw(oc ocun rabbit bugs bunny hutch harvey)];
  $SiteDefs::__species_aliases{ 'Macaca_mulatta'                    } = [qw(mmu mmul rhesus macaque macaca)];
  $SiteDefs::__species_aliases{ 'Macropus_eugenii'                  } = [qw(me meug wallaby)];
  $SiteDefs::__species_aliases{ 'Microcebus_murinus'                } = [qw(mmur lemur)];
  $SiteDefs::__species_aliases{ 'Monodelphis_domestica'             } = [qw(md mdom monodelphis opossum)];
  $SiteDefs::__species_aliases{ 'Mus_musculus'                      } = [qw(mm mmus mouse mus)];
  $SiteDefs::__species_aliases{ 'Myotis_lucifugus'                  } = [qw(ml mluc microbat myotis)];
  $SiteDefs::__species_aliases{ 'Nomascus_leucogenys'               } = [qw(nl nleu gibbon nomascus)];
  $SiteDefs::__species_aliases{ 'Ochotona_princeps'                 } = [qw(op pika pikachu)];
  $SiteDefs::__species_aliases{ 'Ornithorhynchus_anatinus'          } = [qw(oa oana platypus)];
  $SiteDefs::__species_aliases{ 'Otolemur_garnettii'                } = [qw(og ogar bushbaby otolemur)];
  $SiteDefs::__species_aliases{ 'Pan_troglodytes'                   } = [qw(pt ptro chimp)];
  $SiteDefs::__species_aliases{ 'Pongo_abelii'                      } = [qw(pp Pongo_pygmaeus orang orangutan librarian ook)];
  $SiteDefs::__species_aliases{ 'Procavia_capensis'                 } = [qw(pc hyrax dassy dassie pimbi)];
  $SiteDefs::__species_aliases{ 'Pteropus_vampyrus'                 } = [qw(pv megabat flyingfox)];
  $SiteDefs::__species_aliases{ 'Rattus_norvegicus'                 } = [qw(rn rnor rat)];
  $SiteDefs::__species_aliases{ 'Sarcophilus_harrisii'              } = [qw(sh devil tasmanian devil)];
  $SiteDefs::__species_aliases{ 'Sorex_araneus'                     } = [qw(sa shrew)];
  $SiteDefs::__species_aliases{ 'Spermophilus_tridecemlineatus'     } = [qw(st stri squirrel spermophilus)];
  $SiteDefs::__species_aliases{ 'Sus_scrofa'                        } = [qw(ss sscr pig sus oink porky)];
  $SiteDefs::__species_aliases{ 'Tarsius_syrichta'                  } = [qw(ts tarsier gremlin)];
  $SiteDefs::__species_aliases{ 'Tupaia_belangeri'                  } = [qw(tb tbel treeshrew shrew)];
  $SiteDefs::__species_aliases{ 'Tursiops_truncatus'                } = [qw(tt dolphin flipper)];
  $SiteDefs::__species_aliases{ 'Vicugna_pacos'                     } = [qw(lp alpaca)];
#-------------------- birds
  $SiteDefs::__species_aliases{ 'Gallus_gallus'                     } = [qw(gg ggal chicken)];
  $SiteDefs::__species_aliases{ 'Meleagris_gallopavo'               } = [qw(mg mgal turkey meleagris)];
  $SiteDefs::__species_aliases{ 'Taeniopygia_guttata'               } = [qw(tg taegut taeniopygia zebrafinch)];
#-------------------- fish
  $SiteDefs::__species_aliases{ 'Danio_rerio'                       } = [qw(dr drer zfish zebrafish)];
  $SiteDefs::__species_aliases{ 'Gasterosteus_aculeatus'            } = [qw(ga gacu stickleback gasterosteus)];
  $SiteDefs::__species_aliases{ 'Oryzias_latipes'                   } = [qw(ol olat medaka)];
  $SiteDefs::__species_aliases{ 'Takifugu_rubripes'                 } = [qw(fr trub ffish fugu takifugu f_rubripes fugu_rubripes)];
  $SiteDefs::__species_aliases{ 'Tetraodon_nigroviridis'            } = [qw(tn tnig tetraodon)];
  $SiteDefs::__species_aliases{ 'Gadus_morhua'                      } = [qw(gm gmor gadus cod)];
#-------------------- amphibians
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
  $SiteDefs::__species_aliases{ 'Petromyzon_marinus'                } = [qw(pm lamprey sea lamprey )];
#-------------------- yeast
  $SiteDefs::__species_aliases{ 'Saccharomyces_cerevisiae'          } = [qw(sc scer yeast saccharomyces )];
}

1;
