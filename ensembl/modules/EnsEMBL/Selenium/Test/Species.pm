package EnsEMBL::Selenium::Test::Species;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);

#------------------------------------------------------------------------------
# Ensembl test module for species
#------------------------------------------------------------------------------
sub test_species {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  my $SD = $self->get_species_def;
  my $this_release = $SD->ENSEMBL_VERSION;
  my @valid_species = $SD->valid_species;
  @valid_species = ("Homo_sapiens","Erinaceus_europaeus"); 
  #my $species = $self->conf('species'); #parsing the species through the command line.
      
  #Testing each Species
  for(@valid_species) {
    $sel->open_ok("/info/about/species.html");
    
    my $species_label = $SD->species_label($_,1);
    $species_label =~ s/(\s\(.*?\))// if($species_label =~ /\(/);    
    
    my $species_name = $_;
    $species_name =~ s/_/ /;
    
    print "\nTesting $_\n";
    $sel->ensembl_click_links(["link=$species_label"])
    and $sel->is_text_present_ok("$species_name");
    
#     $self->genome_statistics;
#     $sel->ensembl_click_links(["//a[contains(\@href,'Info/WhatsNew')]"])
#     and $sel->is_text_present_ok("What's New in Release $this_release");   
         
    #karyotype link test
    if(scalar @{$SD->get_config($_, 'ENSEMBL_CHROMOSOMES')}) {
      print "Karyotype \n";
      $self->karyotype;
    } else {
      print "No Karyotype \n";
      $sel->is_text_present_ok("Karyotype (not available)");
    }
    
    #Gene page test
    #$self->gene_links;
  }
}

sub attach_remote_file {
  my ($self, $name, $format, $file_url) = @_;
  my $sel  = $self->sel;
  
  $name   ||= 'test';
  $format ||= 'BED'; 
  $file_url ||= 'http://ensweb-1-18.internal.sanger.ac.uk:11000/test.bed ';
 
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->is_text_present_ok("Your data");
 
  $sel->click_ok("link=Attach Remote File")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=url","$file_url")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("name", "$name")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->is_text_present_ok("Go to nearest region with data");  
}
sub add_track {  
  my $self = shift;
  my $sel  = $self->sel;
   
  $self->upload_data;  
  $sel->click_ok("link=Configure Page")
  and $sel->ensembl_wait_for_ajax;

  $sel->is_text_present_ok("test2")
  and $sel->click_ok("//form[\@id='location_genome_configuration']/div[1]/ul/li/img")
  and $sel->click_ok("//img[\@alt='Arrows on both sides']");
  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax  
  and $sel->is_text_present_ok("pairedReads2")
  and $sel->ensembl_images_loaded;  
}

sub configure_page {
  my $self = shift;
  my $sel  = $self->sel;

  $sel->click_ok("link=Configure this page")
  and $sel->ensembl_wait_for_ajax
  and $sel->is_text_present_ok("Configure Page");
  
  $sel->click_ok("link=Display options")
  and $sel->ensembl_wait_for_ajax;
  $sel->select_ok("rows","2");
  $sel->type_ok("name=chr_length","400");  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax(undef,'1200')
  and $sel->is_text_present_ok("Click on the image above to jump to a chromosome");  
}

sub genome_statistics {
  my $self = shift;
  my $sel  = $self->sel;
  
  $sel->ensembl_click_links(["//a[contains(\@href,'/Info/StatsTable')]"]) #Assembly and Genebuild page
  and $sel->is_text_present_ok("Assembly:");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop40')]"]) #Top 40 InterPro hits
  and $sel->is_text_present_ok("InterPro name");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop500')]"]) #Top 500 InterPro hits
  and $sel->is_text_present_ok("InterPro name");  
}

sub gene_links {
  my $self = shift;
  my $sel  = $self->sel;
  
  $sel->ensembl_click_links([
    "link=Gene*",
    "link=Gene summary",
    "link=Splice variants*",
    "link=Supporting evidence",
    "link=Sequence",
    "link=External references*",
    "link=Regulation",
    "link=Expression",
    "link=Literature",
    "link=//a[contains(\@href,'Gene/Compara?')]",
      "link=Genomic alignments*",
      "link=Gene Tree (image)",
      "link=Gene Tree (text)",
      "link=Gene Tree (alignment)",
      "link=Orthologues*",
      "link=Paralogues*",
      "link=Protein families*",    
      "link=//a[contains(\@href,'Gene/Compara_Tree/pan_compara')]",        # Gene Tree (image)
      "link=//a[contains(\@href,'Gene/Compara_Tree/Text_pan_compara')]",   # Gene Tree (text)
      "link=//a[contains(\@href,'Gene/Compara_Tree/Align_pan_compara')]",  # Gene Tree (alignment)
      "link=//a[contains(\@href,'Gene/Compara_Ortholog/pan_compara')]",    # Orthologues
      "link=//a[contains(\@href,'Gene/Compara_Paralog/pan_compara')]",     # Paralogues
      "link=//a[contains(\@href,'Gene/Family/pan_compara')]",
    #-Genetic Variation 
      "link=Variation Table",
      "link=Variation Image",
      "link=External Data",
    #-ID History,
      "link=Gene History",
  ], 30000);
}

sub karyotype {
  my ($self) = @_;
  my $sel  = $self->sel;
  
  $sel->ensembl_click_links(["link=Karyotype"])
  and $sel->ensembl_wait_for_page_to_load_ok
  and $sel->is_text_present_ok("Click on the image above to jump to a chromosome"); 
 
  #Checking if karyotype image loaded fine
  $sel->ensembl_images_loaded;
  
  #Testing the configuration panel
  $self->configure_page;
  
  #TODO Adding tack to the karyotype
  $self->add_track; # if($self->conf('species') eq 'homo_sapiens);
  $self->attach_remote_file;
   
  #Testing ZMenu on karyotype
  print "Opening ZMenu\n" if($self->verbose);
  $sel->ensembl_open_zmenu('Genome')
  and $sel->is_text_present_ok("Jump to location View")
  and $sel->ensembl_click_links(["link=Jump to location View"]);
}

sub open_species_homepage {
  my ($self, $species) = @_;
  my $sel  = $self->sel;
  
  $sel->open_ok("$species/Info/Index");  
  and $sel->is_text_present_ok("$species_name"); 
}

sub upload_data {
  my ($self, $name, $format, $data) = @_;
  my $sel  = $self->sel;
  
  $name   ||= 'test2';
  $format ||= 'BED'; 
  $data   ||= qq{
track name=pairedReads2 description="test2" useScore=1 color=ff5cbc
chr21 31010000 31050000 cloneA 960 + 1010000 1050000 0 2 567,488, 0,3512
chr21 31020000 31060000 cloneB 900 - 1020000 1060000 0 2 433,399, 0,3601 
};
 
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->is_text_present_ok("Your data");
 
  $sel->click_ok("link=Upload Data")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=name","$name")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("text", "$data")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->is_text_present_ok("Go to nearest region with data");  
}

