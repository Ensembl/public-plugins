package EnsEMBL::Selenium::Test::GenomeStatistics;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
#------------------------------------------------------------------------------
# Ensembl Genome Statistics test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_genome_statistics {
  my $self = shift;
  my $sel  = $self->sel;
  my $SD = $self->get_species_def;
  my $release_version = $SD->ENSEMBL_VERSION;

  $self->open_species_homepage($self->species);
  
  $sel->ensembl_click_links(["//a[contains(\@href,'/Info/StatsTable')]"]); #Assembly and Genebuild page
  $sel->ensembl_is_text_present("Assembly:");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop40')]"]); #Top 40 InterPro hits
  $sel->ensembl_is_text_present("InterPro name");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop500')]"]); #Top 500 InterPro hits
  $sel->ensembl_is_text_present("InterPro name");

  $sel->ensembl_click_links(["//a[contains(\@href,'Info/WhatsNew')]"]);
  $sel->ensembl_is_text_present("What's New in Release $release_version");
}
1;