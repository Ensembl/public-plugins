package EnsEMBL::Selenium::Test::Generic;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);

#------------------------------------------------------------------------------
# Ensembl generic test
#------------------------------------------------------------------------------
sub test_homepage {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $SD = $self->get_species_def;   
 my $this_release = $SD->ENSEMBL_VERSION;
 
 $sel->open_ok("/"); 
 $sel->ensembl_wait_for_page_to_load_ok
 and $sel->is_text_present_ok("Ensembl release $this_release")
 and $sel->is_text_present_ok("What's New in Release $this_release")
 and $sel->is_text_present_ok('Did you know...?') 
 and $sel->ensembl_click_links(["link=View full list of all Ensembl species"]);
 
 $sel->go_back();
 $sel->ensembl_click_links(["link=acknowledgements page"]); 
 
}

sub test_species_list {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $SD = $self->get_species_def;
 my @valid_species = $SD->valid_species;
 
 $sel->open_ok("/info/about/species.html");

 foreach my $species (@valid_species) {
   my $species_label = $SD->species_label($species,1);
   $species_label =~ s/(\s\(.*?\))// if($species_label =~ /\(/);    
   $sel->ensembl_click_links(["link=$species_label"]);
   $sel->go_back();
 }
}

sub test_blog {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 
 $sel->open_ok("/"); 
 $sel->ensembl_wait_for_page_to_load_ok;
 $sel->click_ok("link=More release news on our blog ?");
 $sel->wait_for_page_to_load_ok("5000")
 and $sel->is_text_present_ok('Category Archives'); 
}

sub test_robots_file {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  
  $sel->open_ok("/robots.txt")
  and $sel->is_text_present_ok('User-agent: *')
  and $sel->is_text_present_ok('Disallow:*/Gene/A*')
  and $sel->is_text_present_ok('Sitemap: http://www.ensembl.org/sitemap-index.xml');
}

sub test_sitemap {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sitemap_url = $self->url =~ /test.ensembl.org/ ? "$sel->{browser_url}/sitemaps/sitemap-index.xml" : "$sel->{browser_url}/sitemap-index.xml";

 $sel->open_ok("$sitemap_url");  #ignore just a dummy open so that we can get the url, will always return ok
 my $response = $sel->ua->get("$sitemap_url");

 ok($response->is_success, 'Request for sitemap was successful') 
 and ok($response->decoded_content =~ /sitemapindex/, "First line contains 'sitemapindex'")
 and ok($response->decoded_content =~ /sitemap_Homo_sapiens_1\.xml/, "Home Sapiens xml is present");
}

#TODO:: NEED TO ADD MORE TEST
sub test_doc {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/info/index.html");
 $sel->ensembl_wait_for_page_to_load_ok; 
 $sel->ensembl_click_links(["link=Web code"]); 
}

sub test_login {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/");
 $sel->click_ok("link=Login");
 $sel->ensembl_wait_for_ajax;
 $sel->type_ok("name=email", "ma7\@sanger.ac.uk");
 $sel->type_ok("name=password", "selenium");
 $sel->click_ok("name=submit"); 
 $sel->ensembl_wait_for_page_to_load_ok; 
 $sel->click_ok("link=Logout");
 $sel->ensembl_wait_for_page_to_load_ok;
}

sub test_register {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/");
 $sel->ensembl_wait_for_page_to_load_ok;
 $sel->click_ok("link=Register");
 $sel->ensembl_wait_for_ajax;
 $sel->is_text_present_ok("Your name");
 
 $sel->click_ok("link=Lost Password");
 $sel->ensembl_wait_for_ajax;
 $sel->is_text_present_ok("If you have lost your password");
}

sub test_search {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/");
 $sel->ensembl_wait_for_page_to_load_ok;
 
 $sel->type_ok("name=q", "BRCA2");
 $sel->click_ok("//input[\@type='image']");
 $sel->ensembl_wait_for_page_to_load_ok;
 $sel->is_text_present_ok("returned the following results:");
 $sel->click_ok("link=Gene");
 $sel->is_text_present_ok("Homo sapiens (");
 
 $sel->open_ok("/Homo_sapiens/Search/Details?species=Homo_sapiens;idx=Gene;q=brca2");
 $sel->ensembl_wait_for_page_to_load_ok;
 $sel->is_text_present_ok("Genes match your query");  
}

sub test_contact_us {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sd = $self->get_species_def;

 $sel->open_ok("/");
 $sel->ensembl_wait_for_page_to_load_ok;
 
 $sel->ensembl_click_links(["link=Contact Us"]);
 $sel->is_text_present_ok("Contact Ensembl");
 $sel->click_ok("link=email Helpdesk"); 
 $sel->wait_for_pop_up_ok("", "5000");
 $sel->select_window_ok("name=popup_selenium_main_app_window");  #thats only handling one popup with no window name cannot be used for multiple popups
 ok($sel->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error')
 and $sel->is_text_present_ok("Your name");
 $sel->close();
 $sel->select_window();
}
1;