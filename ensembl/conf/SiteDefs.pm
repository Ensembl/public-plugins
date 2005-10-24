package EnsEMBL::Ensembl::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_PERL_SPECIES  = 'Homo_sapiens'; # Default species

## This hash is used to configure the species available in this
## copy of EnsEMBL - comment out any lines which are not relevant
## If you add a new species MAKE sure that one of the values of the
## array is the "SPECIES_CODE" defined in the species.ini file

#-------------------- mammals
  $SiteDefs::__species_aliases{ 'Bos_taurus'               } = [qw(bt cow moo)];
  $SiteDefs::__species_aliases{ 'Canis_familiaris'         } = [qw(cf dog)]; 
  $SiteDefs::__species_aliases{ 'Homo_sapiens'             } = [qw(hs human man default)]; 
  $SiteDefs::__species_aliases{ 'Monodelphis_domestica'    } = [qw(md monodelphis opossum)];
  $SiteDefs::__species_aliases{ 'Mus_musculus'             } = [qw(mm mouse mus)];
  $SiteDefs::__species_aliases{ 'Pan_troglodytes'          } = [qw(pt chimp)];
  $SiteDefs::__species_aliases{ 'Rattus_norvegicus'        } = [qw(rn rat)];
#-------------------- birds
  $SiteDefs::__species_aliases{ 'Gallus_gallus'            } = [qw(gg chicken)];
#-------------------- fish
  $SiteDefs::__species_aliases{ 'Danio_rerio'              } = [qw(dr zfish zebrafish)];
  $SiteDefs::__species_aliases{ 'Fugu_rubripes'            } = [qw(fr ffish fugu)];
  $SiteDefs::__species_aliases{ 'Tetraodon_nigroviridis'   } = [qw(tn tetraodon)];
#-------------------- amphibians
  $SiteDefs::__species_aliases{ 'Xenopus_tropicalis'       } = [qw(xt xenopus frog)];
#-------------------- flies
  $SiteDefs::__species_aliases{ 'Anopheles_gambiae'        } = [qw(ag mosquito mos anopheles)];
  $SiteDefs::__species_aliases{ 'Apis_mellifera'           } = [qw(am honeybee bee)];
  $SiteDefs::__species_aliases{ 'Drosophila_melanogaster'  } = [qw(dm fly)];
#-------------------- worms
# $SiteDefs::__species_aliases{ 'Caenorhabditis_briggsae'  } = [qw(cb briggsae)];
  $SiteDefs::__species_aliases{ 'Caenorhabditis_elegans'   } = [qw(ce worm elegans)];
  $SiteDefs::__species_aliases{ 'Ciona_intestinalis'       } = [qw(ci seqsquirt ciona)];
#-------------------- yeast
  $SiteDefs::__species_aliases{ 'Saccharomyces_cerevisiae' } = [qw(sc yeast saccharomyces )];
}

1;
