package EnsEMBL::Selenium::Test::Transcript;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
#------------------------------------------------------------------------------
# Ensembl Transcript test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_transcript {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;  
  my $species_db = $self->species_databases($SD);

  $self->open_species_homepage($self->species);
  my $transcript_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{TRANSCRIPT_TEXT};
  my $transcript_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'TRANSCRIPT_PARAM'};
  my $url = $self->get_location();

  #Oryzias_latipes doesn't have any transcript info.
  if($transcript_text) {
    $sel->ensembl_click_links(["link=Transcript ($transcript_text)"],'50000')
    and $sel->ensembl_is_text_present("$transcript_param");

     #exit if it is not a valid transcript
    unless($sel->is_text_present_ok("Transcript:*")) {
      print "ERROR: TRANSCRIPT NOT FOUND($transcript_text is not a valid transcript) at $url !!! \n" ;
      last;
    }

    #Testing ZMenu (doing only for human)
    if(lc($self->species) eq 'homo_sapiens') {
      $sel->ensembl_open_zmenu('TranscriptImage','title^="Transcript:"');
      $sel->ensembl_click("link=ENSG*")
      and $sel->ensembl_wait_for_ajax('50000','5000')
      and $sel->go_back();
    }

    $sel->ensembl_click_links(["link=Supporting evidence*"]) if(!(lc($self->species) eq 'caenorhabditis_elegans' || lc($self->species) eq 'drosophila_melanogaster' || lc($self->species) eq 'saccharomyces_cerevisiae')); #for now that will do
    $sel->ensembl_click_links(["link=Exons*", "link=cDNA", "link=Protein"],'10000');

    #unfortunately can't implement the check for this link as Obj is required so will test for a few species only
    $sel->ensembl_click_links(["link=General identifiers*"], '10000') if(lc($self->species) eq 'homo_sapiens' || lc($self->species) eq 'mus_musculus' || lc($self->species) eq 'gorilla_gorilla');

    my $oligos = $self->count_oligos($transcript_param);
    $sel->ensembl_click_links(["link=Oligo probes*"]) if($oligos);

    $sel->ensembl_click_links(["link=Ontology chart*", "link=Ontology table*"],'20000') if(lc($self->species) eq 'homo_sapiens' or lc($self->species) eq 'mus_musculus');
    $sel->ensembl_click_links(["link=Population comparison", "link=Comparison image"],'20000') if($species_db->{'database:variation'} && $SD->databases(ucfirst($self->species))->{'DATABASE_VARIATION'}->{'#STRAINS'});
    $sel->ensembl_click_links(["link=Protein summary"],'20000');

    #Adding a track from the configuration panel
    if(lc($self->species) eq 'homo_sapiens') {          
      print "  Test Configuration page \n";
      $sel->ensembl_click("link=Configure this page")
      and $sel->ensembl_wait_for_ajax('10000')
#      and $sel->ensembl_click("link=Information*")
#      and $sel->ensembl_wait_for_ajax('10000')
#      and $sel->ensembl_click("//form[\@id='transcript_translationimage_configuration']/div[1]/ul/li[1]/img") #untick the first track      
      and $sel->ensembl_click("modal_bg")
#      and $sel->ensembl_wait_for_ajax('15000')
#      and $sel->ensembl_images_loaded;
    }
    $sel->ensembl_click_links(["link=Domains & features*"],'20000') if ($SD->table_info_other(ucfirst($self->species),'core', 'protein_feature')->{'analyses'} && lc($self->species) ne 'meleagris_gallopavo');
    $sel->ensembl_click_links(["link=Variations*"],'20000') if(lc($self->species) eq 'homo_sapiens' || lc($self->species) eq 'mus_musculus');

    $sel->ensembl_click("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->ensembl_click("link=Configure this page")
    and $sel->ensembl_wait_for_ajax('30000','5000')
    and $sel->ensembl_click("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->ensembl_click("modal_bg")
    and $sel->ensembl_wait_for_page_to_load;

    $sel->ensembl_click_links(["link=Transcript history", "link=Protein history"]) if $SD->table_info_other(ucfirst($self->species),'core', 'stable_id_event')->{'rows'};

    #Testing Export data
    $self->export_data('BED Format','Browser position') if(lc($self->species) eq 'homo_sapiens');
  } else {
   print "  No Transcript \n"; 
  }
}
1;