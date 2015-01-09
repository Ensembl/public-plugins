=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
  my $variation_db = $self->database('variation', $self->species);
  
  
  if($variation_db) {
    my $variation_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'VARIATION_TEXT'};
    my $variation_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'VARIATION_PARAM'};
    
    if(!$variation_text) {
     print "   ERROR:: SAMPLE VARIATION PARAM MISSING IN INI FILES!!! \n"; 
     next;
    }
    my $species_db = $self->species_databases($SD);

    $sel->ensembl_click_links(["link=Example variant"],'20000');
    $sel->ensembl_is_text_present("Variation: $variation_text");
    
    $sel->ensembl_click_links(["link=Genes and regulation*", "link=Population genetics*", "link=Individual genotypes*","link=Genomic context"]);
    
    #TODO Test the Show table link
    
    #Adding a track from the configuration panel, testing zmenu and other human specific link
    if(lc($self->species) eq 'homo_sapiens') {
      print "  Test Configure page, adding a track \n";
      $sel->ensembl_click("link=Configure this page")
      and $sel->ensembl_wait_for_ajax_ok('10000','5000')
      and $sel->ensembl_click("css=a.variation")  #don't know why link= wasn't working and css= works    
      and $sel->ensembl_wait_for_ajax_ok('10000','9000')
      and $sel->ensembl_click("//form[\@id='variation_context_configuration']/div[3]/div/div/ul/li[2]/div[2]") #choosing the second track    
      and $sel->ensembl_click("modal_bg")
      and $sel->ensembl_wait_for_ajax_ok('50000', '50000')
      and $sel->ensembl_images_loaded;
        
      #Test ZMenu    
      $sel->ensembl_open_zmenu('Context','title^="Variation:"');
      $sel->pause(8000);
      $sel->ensembl_click("link=more about*")
      and $sel->ensembl_wait_for_ajax_ok('50000','5000')
      and $sel->go_back();    
    
      $sel->ensembl_wait_for_page_to_load;
      $sel->pause(3000);
    
      $sel->ensembl_click_links(["link=Linkage disequilibrium", "link=Phenotype Data*"],'10000');
      
      $sel->ensembl_click_links(["link=View on Karyotype"],'50000');
      $sel->go_back();
    }

    $sel->ensembl_click_links(["link=Phylogenetic Context*"],'30000');
    
    $sel->select_ok("align", "label=8 primates EPO")
    and $sel->ensembl_click("link=Go") if(lc($self->species) eq 'homo_sapiens');
    
    print "  Test Configure page on External Data \n";
    $sel->ensembl_click("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->ensembl_click("link=Configure this page")
    and $sel->ensembl_wait_for_ajax_ok(undef,'5000')
    and $sel->ensembl_click("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->ensembl_click("modal_bg")
    and $sel->ensembl_wait_for_ajax_ok(10000,8000);
    
    my $url = $self->get_location();
    print "DAS ERROR at $url (click on configure page and choose the first das source) \n"  if $sel->ensembl_has_das_error;
  } else {
    print "   No variation for this species! \n"; 
  }
}
1;
