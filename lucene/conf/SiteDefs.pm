use strict;

package EnsEMBL::Lucene::SiteDefs;
sub update_conf {
  @SiteDefs::ENSEMBL_LUCENE_OMITSPECIESFILTER = 
    qw(ensembl_docs ensembl_faq ensembl_glossary ensembl_help);
}

1;
