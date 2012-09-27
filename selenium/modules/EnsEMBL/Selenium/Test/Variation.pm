# $Id$
package EnsEMBL::Selenium::Test::Variation;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl variation test (FOR HUMAN ONLY).
#------------------------------------------------------------------------------
sub test_variation {
  my $self = shift;
  my $sel  = $self->sel;
  my $SD = $self->get_species_def;
  my $release_version = $SD->ENSEMBL_VERSION;
  my $sp_bio_name = $SD->get_config($self->species,'SPECIES_BIO_NAME');

  $self->open_species_homepage($self->species,undef, $sp_bio_name);
  
  if(lc($self->species) eq 'homo_sapiens') {
    my $variation_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'VARIATION_TEXT'};
    my $variation_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'VARIATION_PARAM'};
    my $species_db = $self->species_databases($SD);

    $sel->ensembl_click_links(["link=Example variant"],'20000');
    $sel->ensembl_is_text_present("Variation: $variation_text");
    
    $sel->ensembl_click_links(["link=Genes and regulation*", "link=Population genetics*", "link=Individual genotypes*","link=Genomic context"],'20000');
    
    #TODO Test the Show table link
    
    #Adding a track from the configuration panel
    print "  Test Configure page, adding a track \n";
    $sel->ensembl_click("link=Configure this page")
    and $sel->ensembl_wait_for_ajax_ok('10000')
    and $sel->ensembl_click("css=a.variation")  #don't know why link= wasn't working and css= works    
    and $sel->ensembl_wait_for_ajax_ok('10000','5000')
    and $sel->ensembl_click("//form[\@id='variation_context_configuration']/div[3]/div[1]/ul[1]/li[2]/img") #choosing the second track    
    and $sel->ensembl_click("modal_bg")
    and $sel->ensembl_wait_for_ajax_ok('15000', '5000')
    and $sel->ensembl_images_loaded;
    
    #Test ZMenu    
    $sel->ensembl_open_zmenu('Context','title^="Variation:"');
    $sel->pause(2000);
    $sel->ensembl_click("link=rs*properties")
    and $sel->ensembl_wait_for_ajax_ok('50000','2000')
    and $sel->go_back();    
    
    $sel->ensembl_wait_for_page_to_load;
    $sel->pause(3000);
        
    $sel->ensembl_click_links(["link=Linkage disequilibrium", "link=Phenotype Data*"],'10000');
    
    $sel->ensembl_click_links(["link=[View on Karyotype]"],'50000');
    $sel->go_back();

    $sel->ensembl_click_links(["link=Phylogenetic Context*"],'30000');
    $sel->select_ok("align", "label=6 primates EPO");
    $sel->ensembl_click("//input[\@value='Go']");
    
    $sel->ensembl_wait_for_page_to_load;
    
    print "  Test Configure page on External Data \n";
    $sel->ensembl_click("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->ensembl_click("link=Configure this page")
    and $sel->ensembl_wait_for_ajax_ok
    and $sel->ensembl_click("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->ensembl_click("modal_bg")
    and $sel->ensembl_wait_for_ajax_ok(10000,5000);
    
    my $url = $self->get_location();
    print "DAS ERROR at $url (click on configure page and choose the first das source) \n"  if $sel->ensembl_has_das_error;
  }
}
1;
