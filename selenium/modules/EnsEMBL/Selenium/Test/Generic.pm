=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Selenium::Test::Generic;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);

#------------------------------------------------------------------------------
# Ensembl generic test
#------------------------------------------------------------------------------
sub test_homepage {
  my ($self, $links) = @_;
  my $sel          = $self->sel;
  my $SD           = $self->get_species_def;   
  my $this_release = $SD->ENSEMBL_VERSION;
  my $location     = $self->get_location();  

  $sel->open_ok("/"); 

  $sel->ensembl_wait_for_page_to_load
  and $sel->ensembl_is_text_present("Ensembl release $this_release")
  and $sel->ensembl_is_text_present("What's New in Release $this_release")
  and $sel->ensembl_is_text_present('Did you know')
  and $sel->ensembl_click_links(["link=View full list of all Ensembl species"]);
 
  $sel->go_back();
  $sel->ensembl_wait_for_page_to_load;
  $sel->ensembl_click_links(["link=acknowledgements page"]); 

  $sel->go_back()
  and $sel->ensembl_wait_for_page_to_load;  
  
  $sel->ensembl_click_links(["link=About Ensembl"]); 
  
  $sel->go_back()
  and $sel->ensembl_wait_for_page_to_load;
  
  $sel->ensembl_click_links(["link=Privacy Policy"]);
}

sub test_species_list {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $SD = $self->get_species_def;
 my $release_version = $SD->ENSEMBL_VERSION;
 my @valid_species = $SD->valid_species;
 my $url = $self->url;

 $sel->open_ok("/info/about/species.html");

 foreach my $species (@valid_species) {   
   my $common_name   = $SD->get_config($species, 'SPECIES_COMMON_NAME');
   my $sc_name       = $SD->get_config($species, 'SPECIES_SCIENTIFIC_NAME');
   
   $common_name   =~ s/([A-Z])([a-z]+)\s+([a-z]+)/$1. $3/ if($common_name eq $sc_name);
   $sel->ensembl_click_links(["link=$common_name"],'10000');

   #my $species_image = qq{pic_$species};
   #$species_image = qq{pic_Pongo_pygmaeus} if($species eq 'Pongo_abelii'); #hack for Pongo as it is the only species which did not follow the species image naming rule.

   #CHECK FOR SPECIES IMAGES
   $sel->run_script(qq{
     var x = jQuery.ajax({
                    url: '$url/i/species/64/$species.png',
                    async: false,
              }).state();
     if (x == 'resolved') {
       jQuery('body').append("<p>Species images present</p>");
     }
  });
  
    $sel->ensembl_is_text_present("Species images present")
    and $sel->ensembl_is_text_present($sc_name)
    and $sel->ensembl_is_text_present("What's New in");

    $sel->go_back();
 }
}

sub test_blog {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 
 $sel->open_ok("/"); 
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_click("link=More news on our blog");
 $sel->ensembl_wait_for_page_to_load("50000")
 and $sel->ensembl_is_text_present('Category Archives'); 
}

sub test_robots_file {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  
  next unless $sel->open_ok("/robots.txt")
  and $sel->ensembl_is_text_present('User-agent: *')
  and $sel->ensembl_is_text_present('Disallow:*/Gene/A*')
  and $sel->ensembl_is_text_present('Sitemap: http://www.ensembl.org/sitemap-index.xml');
}

sub test_sitemap {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sitemap_url = $self->url =~ /test.ensembl.org/ ? "$sel->{browser_url}/sitemaps/sitemap-index.xml" : "$sel->{browser_url}/sitemap-index.xml";

 next unless $sel->open_ok("$sitemap_url");  #ignore just a dummy open so that we can get the url, will always return ok
 my $response = $sel->ua->get("$sitemap_url");

 ok($response->is_success, 'Request for sitemap was successful') 
 and ok($response->decoded_content =~ /sitemapindex/, "First line contains 'sitemapindex'")
 and ok($response->decoded_content =~ /sitemap_Homo_sapiens_1\.xml/, "Home Sapiens xml is present");
}

sub test_doc {
 my ($self, $links) = @_;
 my $sel      = $self->sel;
 my $location = $self->get_location();
 my @skip_link = ('Home', 'FAQs');
 
 $sel->open_ok("/info/index.html");
 print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load; 
 $sel->ensembl_click_all_links('#main', \@skip_link); 
}

sub test_faq {
  my ($self, $links) = @_;
  my $sel      = $self->sel;
  my $location = $self->get_location(); 
  
  $sel->open_ok("/info/index.html");
  print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load; 
  
  my @skip_link = ("Home", "contact our HelpDesk", "developers' mailing list");
  
  $sel->ensembl_click_ok("link=FAQs",'50000')
  and $sel->wait_for_pop_up_ok("", "5000")
  and $sel->select_window_ok("name=popup_selenium_main_app_window")  #thats only handling one popup with no window name cannot be used for multiple popups
  and $sel->ensembl_click_all_links(".content", \@skip_link, 'More FAQs');
}

sub test_login {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $location = $self->get_location(); 

 $sel->open_ok("/");
 
 $sel->ensembl_click("link=Login/Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000)
 and $sel->type_ok("name=email", "ma7\@sanger.ac.uk")
 and $sel->type_ok("name=password", "selenium")
 and $sel->ensembl_click("name=submit")
 and $sel->ensembl_wait_for_page_to_load; 
 
 $sel->ensembl_click_links(["link=Logout"]);
 #$sel->ensembl_wait_for_page_to_load_ok;
}

sub test_register {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/");
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_click("link=Login/Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 
 $sel->ensembl_click("link=Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 
 $sel->ensembl_is_text_present("Email");
 
 $sel->ensembl_click("link=Lost password")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000)
 and $sel->ensembl_is_text_present("If you have lost your password");
}

sub test_search {
 my ($self, $links) = @_;
 my $sel      = $self->sel;
 my $location = $self->get_location();

 $sel->open_ok("/");
 #$sel->ensembl_wait_for_page_to_load_ok;
 
 $sel->type_ok("name=q", "BRCA2");
 $sel->ensembl_click_links(["//input[\@type='image']"]);
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_is_text_present("results match");
# $sel->ensembl_click("link=Gene");
 $sel->ensembl_click("//a[contains(\@href, '#Gene')]")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 $sel->ensembl_is_text_present("when restricted to");
 $sel->ensembl_is_text_present("category: Gene");
 $sel->ensembl_is_text_present("(Human Gene)");

 next unless $sel->ensembl_click("//div[\@id='solr_content']//div[\@class='search_table']//a[\@class='table_toplink'][1]");

# next unless $sel->open_ok("/Homo_sapiens/Search/Details?species=Homo_sapiens;idx=Gene;q=brca2");  
 print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load;
}

sub test_contact_us {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sd = $self->get_species_def;

 $sel->open_ok("/info/about/contact");
 $sel->ensembl_is_text_present("Contact Ensembl");
 $sel->ensembl_click("link=email Helpdesk"); 
 $sel->wait_for_pop_up_ok("", "5000");
 $sel->select_window_ok("name=popup_selenium_main_app_window");  #thats only handling one popup with no window name cannot be used for multiple popups
 ok($sel->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error')
 and $sel->ensembl_is_text_present("Your name");
 $sel->close();
 $sel->select_window();
}
1;
