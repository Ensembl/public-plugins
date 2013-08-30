# $Id$
package EnsEMBL::Selenium::Test::Regulation;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl regulation test (FOR MOUSE ONLY).
#------------------------------------------------------------------------------
sub test_regulation {
  my $self = shift;
  my $sel  = $self->sel;
  my $SD = $self->get_species_def;
  my $sp_bio_name = $SD->get_config($self->species,'SPECIES_BIO_NAME');  
  my $release_version = $SD->ENSEMBL_VERSION;

  $self->open_species_homepage($self->species,undef, $sp_bio_name);
  
  if(lc($self->species) eq 'mus_musculus') {
    my $regulation_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'REGULATION_TEXT'};
    my $regulation_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'REGULATION_PARAM'};
    my $species_db = $self->species_databases($SD);

    $sel->ensembl_click_links(["link=Example regulatory feature"],"10000");
    $sel->ensembl_is_text_present("Regulatory Feature: $regulation_param");
    
    $sel->ensembl_click_links(["link=Summary"]);
        
    #Test ZMenu
    print "  Test ZMenu on Regulation Details by cell line \n";
    $sel->ensembl_open_zmenu('FeatureDetails', 'title^="Regulatory Feature:"', 'Reg Feats');
    $sel->pause(2000);
    $sel->ensembl_click("link=ENSMUSR*")
    and $sel->ensembl_wait_for_ajax_ok('50000','2000');
    
    #Adding a track from the configuration panel
    print "  Test Configure page, adding a track \n";

    # can't use the generic function to turn on track because there is only one track renderer on one click
    $sel->ensembl_click("link=Configure this page")
    and $sel->ensembl_wait_for_ajax_ok('50000','5000')
    and $sel->ensembl_click("link=Repeat regions")
    and $sel->ensembl_wait_for_ajax_ok('20000')    
    and $sel->ensembl_click("//form[\@id='regulation_featuresbycellline_configuration']/div[7]/div/ul/li")
    and $sel->ensembl_is_text_present("Repeat regions(1/*")
    and $sel->ensembl_click("modal_bg")
    and $sel->ensembl_wait_for_ajax_ok('50000', 5000)
    and $sel->ensembl_images_loaded;
    
    $sel->ensembl_click_links(["link=Feature Context", "link=Evidence"]);
  }
}
1;
