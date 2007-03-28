package EnsEMBL::Ensembl::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Homo_sapiens'; # Default species
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Mus_musculus'; # Secondardy species

## This hash is used to configure the species available in this
## copy of EnsEMBL - comment out any lines which are not relevant
## If you add a new species MAKE sure that one of the values of the
## array is the "SPECIES_CODE" defined in the species.ini file

#-------------------- mammals
  $SiteDefs::__species_aliases{ 'Bos_taurus'               } = [qw(bt btau cow moo)];
  $SiteDefs::__species_aliases{ 'Canis_familiaris'         } = [qw(cf cfam dog)]; 
  $SiteDefs::__species_aliases{ 'Dasypus_novemcinctus'     } = [qw(dn dnov dasypus armadillo)];
  $SiteDefs::__species_aliases{ 'Echinops_telfairi'        } = [qw(et etel echinops tenrec)];
  $SiteDefs::__species_aliases{ 'Felis_catus'              } = [qw(fc fcat cat)];
  $SiteDefs::__species_aliases{ 'Tupaia_belangeri'         } = [qw(tb tbel treeshrew shrew)];
  $SiteDefs::__species_aliases{ 'Erinaceus_europaeus'      } = [qw(ee eeur hedgehog)];
  $SiteDefs::__species_aliases{ 'Cavia_porcellus'          } = [qw(cp cpor guineapig)];
  $SiteDefs::__species_aliases{ 'Homo_sapiens'             } = [qw(hs hsap human man default)]; 
  $SiteDefs::__species_aliases{ 'Loxodonta_africana'       } = [qw(la lafr elephant africana loxodontai hathi nellie dumbo)];
  $SiteDefs::__species_aliases{ 'Oryctolagus_cuniculus'    } = [qw(oc ocun rabbit bugs bunny hutch harvey)];
  $SiteDefs::__species_aliases{ 'Macaca_mulatta'           } = [qw(mmu mmul rhesus macaque macaca)];
  $SiteDefs::__species_aliases{ 'Monodelphis_domestica'    } = [qw(md mdom monodelphis opossum)];
  $SiteDefs::__species_aliases{ 'Mus_musculus'             } = [qw(mm mmus mouse mus)];
  $SiteDefs::__species_aliases{ 'Myotis_lucifugus'               } = [qw(ml mluc microbat myotis)];
  $SiteDefs::__species_aliases{ 'Otolemur_garnettii'             } = [qw(og ogar bushbaby otolemur)];
  $SiteDefs::__species_aliases{ 'Pan_troglodytes'          } = [qw(pt ptro chimp)];
  $SiteDefs::__species_aliases{ 'Rattus_norvegicus'        } = [qw(rn rnor rat)];
  $SiteDefs::__species_aliases{ 'Spermophilus_tridecemlineatus'  } = [qw(st stri squirrel spermophilus)];
  $SiteDefs::__species_aliases{ 'Ornithorhynchus_anatinus' } = [qw(oa oana platypus)];
#-------------------- birds
  $SiteDefs::__species_aliases{ 'Gallus_gallus'            } = [qw(gg ggal chicken)];
#-------------------- fish
  $SiteDefs::__species_aliases{ 'Danio_rerio'              } = [qw(dr drer zfish zebrafish)];
  $SiteDefs::__species_aliases{ 'Gasterosteus_aculeatus'   } = [qw(ga gacu stickleback gasterosteus)];
  $SiteDefs::__species_aliases{ 'Takifugu_rubripes'        } = [qw(fr trub ffish fugu takifugu f_rubripes fugu_rubripes)];
  $SiteDefs::__species_aliases{ 'Oryzias_latipes'          } = [qw(ol olat medaka)];
  $SiteDefs::__species_aliases{ 'Tetraodon_nigroviridis'   } = [qw(tn tnig tetraodon)];
#-------------------- amphibians
  $SiteDefs::__species_aliases{ 'Xenopus_tropicalis'       } = [qw(xt xtro xenopus frog)];
#-------------------- flies
  $SiteDefs::__species_aliases{ 'Aedes_aegypti'            } = [qw(aa aaeg aedes )];
  $SiteDefs::__species_aliases{ 'Anopheles_gambiae'        } = [qw(ag agam mosquito mos anopheles)];
# $SiteDefs::__species_aliases{ 'Apis_mellifera'           } = [qw(am amel honeybee bee)];
  $SiteDefs::__species_aliases{ 'Drosophila_melanogaster'  } = [qw(dm dmel fly)];
#-------------------- worms
# $SiteDefs::__species_aliases{ 'Caenorhabditis_briggsae'  } = [qw(cb cbri briggsae)];
  $SiteDefs::__species_aliases{ 'Caenorhabditis_elegans'   } = [qw(ce cele worm elegans)];
  $SiteDefs::__species_aliases{ 'Ciona_intestinalis'       } = [qw(ci cint seasquirti cionai)];
  $SiteDefs::__species_aliases{ 'Ciona_savignyi'           } = [qw(cs csav seasquirts cionas)];
#-------------------- yeast
  $SiteDefs::__species_aliases{ 'Saccharomyces_cerevisiae' } = [qw(sc scer yeast saccharomyces )];
}

1;
