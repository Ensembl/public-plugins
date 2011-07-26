package EnsEMBL::Selenium::Test::Species;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
#------------------------------------------------------------------------------
# Ensembl test module for species
#------------------------------------------------------------------------------
sub test_genome_statistics {
  my $self = shift;
  my $sel  = $self->sel;
  my $SD = $self->get_species_def;

  $self->open_species_homepage($self->species);
  
  $sel->ensembl_click_links(["//a[contains(\@href,'/Info/StatsTable')]"]); #Assembly and Genebuild page
  $sel->ensembl_is_text_present_ok("Assembly:");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop40')]"]); #Top 40 InterPro hits
  $sel->ensembl_is_text_present_ok("InterPro name");
  
  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop500')]"]); #Top 500 InterPro hits
  $sel->ensembl_is_text_present_ok("InterPro name");

  $sel->ensembl_click_links(["//a[contains(\@href,'Info/WhatsNew')]"]);
  $sel->ensembl_is_text_present_ok("What's New in Release $SD->ENSEMBL_VERSION");
}

sub test_karyotype {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;
  $self->open_species_homepage($self->species);

#karyotype link test
  if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) {
    print "No Karyotype \n";
    $sel->ensembl_is_text_present_ok("Karyotype (not available)");
  } else {
    $sel->ensembl_click_links(["link=Karyotype"]);
    $sel->ensembl_is_text_present_ok("Click on the image above to jump to a chromosome");

    #Checking if karyotype image loaded fine
    $sel->ensembl_images_loaded;

    #Testing the configuration panel (human only)
    $self->configure_page if(lc($self->species) eq 'homo_sapiens');

    #TODO:: Making the features_karyotype, add_track, attach_remote_file separate test that can be run
    #Test features on karyotype (human only)
    $self->features_karyotype if(lc($self->species) eq 'homo_sapiens');

    #Adding tack to the karyotype (human only)
    $self->add_track if(lc($self->species) eq 'homo_sapiens');
    $self->attach_remote_file if(lc($self->species) eq 'homo_sapiens');

    #Testing ZMenu on karyotype
    print "Test ZMenu\n";
    $sel->ensembl_open_zmenu('Genome')
    and $sel->ensembl_is_text_present_ok("Jump to location View")
    and $sel->ensembl_click_links(["link=Jump to location View"]);
  }
}

sub test_location {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;
  $self->open_species_homepage($self->species);
  my $location_text = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{LOCATION_TEXT};
  
  if($location_text) {
    $sel->ensembl_click_links(["link=Location ($location_text)"]);
    my @location_array = split(/\:/,$location_text);    
    $sel->ensembl_is_text_present_ok($SD->thousandify(@location_array[1]))
    and $sel->ensembl_is_text_present_ok("Region in detail")
    and $sel->ensembl_images_loaded;
    
    #Test ZMENU (only for human and mouse)
    if($self->species eq 'homo_sapiens') {
      $sel->ensembl_open_zmenu('Summary',"class^=drag");
      $sel->ensembl_is_text_present_ok("Centre here")
      and $sel->ensembl_click_links(["link=Centre here"]);
      $sel->ensembl_images_loaded;
      $sel->go_back();     
      
      #TODO:: ZMenu on viewtop and ViewBottom panel
    }
    #Whole genome link
    $sel->ensembl_click_links(["link=Whole genome"]);    
    !scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')} ?  $sel->ensembl_is_text_present_ok("This genome has yet to be assembled into chromosomes") :  $sel->ensembl_images_loaded;

    @location_array[0] =~ s/chr//;
    #Chromosome summary link (only click for sepcies with chromosome)
    if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')})) {
      $sel->ensembl_click_links(["link=Chromosome summary"]);
      $sel->ensembl_is_text_present_ok("Chromosome Statistics")
      and $sel->ensembl_images_loaded ;
    }

    $sel->ensembl_click_links(["link=Region overview"]);
    $sel->ensembl_images_loaded;
    
    $sel->ensembl_click_links(["link=Region in detail"]);
    $sel->ensembl_images_loaded;
    
    $sel->ensembl_click_links(["link=Comparative Genomics"]);
    $sel->ensembl_images_loaded;
        
    my %synteny_hash  = $SD->multi('DATABASE_COMPARA', 'SYNTENY');
    my $synteny_count = scalar keys %{$synteny_hash{ucfirst($self->species)}};
    my %alignments    = $SD->multi('DATABASE_COMPARA', 'ALIGNMENTS');
    
    my ($alignment_count, $multi_species_count);
    foreach (grep $_->{'species'}{ucfirst($self->species)}, values %alignments) {
      $alignment_count++;
      $multi_species_count++ if $_->{'class'} =~ /pairwise_alignment/;
    }
    
    if($alignment_count) {
      $sel->ensembl_click_links(["link=Alignments (image) ($alignment_count)"]);
      $sel->ensembl_images_loaded;      
      
      $sel->ensembl_click_links(["link=Alignments (text) ($alignment_count)"]);
      $sel->ensembl_images_loaded;           
      
      $sel->ensembl_click_links(["link=Multi-species view ($multi_species_count)"],'8000');
      $sel->ensembl_images_loaded;     
    }
    
    if($synteny_count) {
      $sel->ensembl_click_links(["link=Synteny ($synteny_count)"], '8000');
      $sel->ensembl_images_loaded;
    }
        
    #Markers        
    if($SD->table_info_other(ucfirst($self->species),'core', 'marker_feature')->{'rows'}) {
      $sel->ensembl_click_links(["link=Markers"], '8000');      
      $sel->ensembl_images_loaded;      
      
      if($self->species eq 'homo_sapiens') {
        $sel->ensembl_is_text_present_ok("mapped markers found:");
        $sel->ensembl_click_links(["link=D6S989"]);
        $sel->ensembl_is_text_present_ok("Marker D6S989");
        $sel->go_back();
      }
    }
        
    #Testing genetic variations last for human only
    if($self->species eq 'homo_sapiens') {      
      my $resequencing_counts = $SD->databases->{'DATABASE_VARIATION'}{'#STRAINS'} if exists $SD->databases->{'DATABASE_VARIATION'};
      $sel->ensembl_click_links(["link=Resequencing ($resequencing_counts)"], '8000');
      $sel->ensembl_images_loaded;
      $sel->type_ok("loc_r", "6:27996744-27996844");
      $sel->click_ok("//input[\@value='Go']");
      $sel->pause(5000);
      $sel->ensembl_is_text_present_ok("Basepairs in secondary strains");
      
      $sel->ensembl_click_links(["link=Linkage Data"], '8000');
#       $sel->click_ok("link=Select populations");
#       $sel->click_ok("/html/body[\@id='ensembl-webpage']/div[\@id='modal_panel']/div[\@id='modal_default']/div[2]/div/div/div[2]/ul/li[1]/span[1]"); #choosing the first population (not working)
#       $sel->click_ok("modal_bg");
      $sel->open_ok("Homo_sapiens/Location/LD?db=core;r=6:27996744-27996844;pop1=12131"); #couldn't get the above code to work so a direct check to the page to see if LD works fine. 
      $sel->pause(5000);     
      $sel->ensembl_images_loaded
      and $sel->ensembl_is_text_present_ok("Prediction method:");
    }
        
  } else {
    print "No Location \n";
    $sel->ensembl_is_text_present_ok("Location (not available)"); 
  }
}

#TODO::Test in location
sub attach_das {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  #$self->open_species_homepage
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->click_ok("link=Attach DAS")
  and $sel->ensembl_wait_for_ajax
  and $sel->type_ok("name=preconf_das", "http://das.sanger.ac.uk/das")
  and $sel->click_ok("wizard_submit")
  and $sel->ensembl_wait_for_ajax
  and $sel->pause(5000)
  and $sel->click_ok("//div[\@id='DasSources']//input[\@type='checkbox'][1]") # tick first das source
  and $sel->click_ok("wizard_submit")
  and $sel->wait_for_text_present_ok("The following DAS sources have now been attached")
  and $sel->click_ok("//div[\@class='modal_close']");
}

sub attach_remote_file {
  my ($self, $name, $format, $file_url) = @_;
  my $sel  = $self->sel;
  
  $name   ||= 'test';
  $format ||= 'BED'; 
  $file_url ||= 'http://ensweb-1-18.internal.sanger.ac.uk:11000/test.bed';
  
  print "Test Attach remote file\n";
 
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present_ok("Your data");
 
  $sel->click_ok("link=Attach Remote File")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=url","$file_url")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("name", "$name")
  and $sel->click_ok("name=wizard_submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->ensembl_is_text_present_ok("Go to first region with data");  
}
sub add_track {  
  my $self = shift;
  my $sel  = $self->sel;
  
  print "Test Upload data\n";   
  $self->upload_data;  
  $sel->click_ok("link=Configure Page")
  and $sel->ensembl_wait_for_ajax;

  $sel->ensembl_is_text_present_ok("test2")
  and $sel->click_ok("//form[\@id='location_genome_configuration']/div[1]/ul/li/img")
  and $sel->click_ok("//img[\@alt='Arrows on both sides']");
  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present_ok("pairedReads2")
  and $sel->ensembl_images_loaded;
}

sub configure_page {
  my $self = shift;
  my $sel  = $self->sel;
  
  print "Test Configure Page\n";
  $sel->click_ok("link=Configure this page")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present_ok("Configure Page");
  
  $sel->click_ok("link=Display options")
  and $sel->ensembl_wait_for_ajax;
  $sel->select_ok("rows","2");
  $sel->type_ok("name=chr_length","400");  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax(undef,'1200')
  and $sel->ensembl_is_text_present_ok("Click on the image above to jump to a chromosome");  
}


sub features_karyotype {
  my ($self, $feature_id) = @_;
  my $sel  = $self->sel;
  
  $feature_id ||= 'BRCA2';
  
  print "Test Features on karyotype\n";
 
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present_ok("Your data");
 
  $sel->click_ok("link=Features on Karyotype")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=id","$feature_id")  
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax  
  and $sel->ensembl_is_text_present_ok("$feature_id")
  and $sel->ensembl_images_loaded;  
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

sub open_species_homepage {
  my ($self, $species) = @_;
  my $sel  = $self->sel; 
  my $species_name = $species;
  $species_name    =~ s/_/ /;
  
  ##TODO::CHeck for species image loaded fine  
  $sel->open_ok("$species/Info/Index")
  and $sel->ensembl_wait_for_page_to_load
  and $sel->ensembl_is_text_present_ok(ucfirst($species_name));
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
  and $sel->ensembl_is_text_present_ok("Your data");
 
  $sel->click_ok("link=Upload Data")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=name","$name")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("text", "$data")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->ensembl_is_text_present_ok("Go to first region with data");  
}

1;