package EnsEMBL::Selenium::Test::Gene;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
#------------------------------------------------------------------------------
# Ensembl Gene test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_gene {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;

  $self->open_species_homepage($self->species, '50000');
  my $gene_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'GENE_TEXT'};
  my $gene_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'GENE_PARAM'};
  my $species_db = $self->species_databases($SD);
  
  if($gene_text) {    
    $sel->ensembl_click_links(["link=Gene ($gene_text)"],"50000")
    and $sel->ensembl_is_text_present("Gene: $gene_text ($gene_param)");    
    
    if(lc($self->species) eq 'homo_sapiens') {      
      print "  Test ZMenu on Gene Summary\n";
      $sel->ensembl_open_zmenu('TranscriptsImage','class^="drag"');
      $sel->click_ok("link=Jump to location View")
      and $sel->ensembl_wait_for_ajax('50000','2000')
      and $sel->go_back();
      
      $sel->ensembl_wait_for_page_to_load;
      
      #Adding a track from the configuration panel
      print "  Test Configure page, adding a track \n";
      $sel->click_ok("link=Configure this page")
      and $sel->ensembl_wait_for_ajax('10000')
      and $sel->click_ok("link=External data*")
      and $sel->ensembl_wait_for_ajax('10000')
      and $sel->click_ok("//form[\@id='gene_transcriptsimage_configuration']/div[7]/ul/li[1]/img") #choosing the first track
      and $sel->click_ok("//form[\@id='gene_transcriptsimage_configuration']/div[7]/ul/li[1]/ul/li[3]/img") #making it normal
      and $sel->click_ok("modal_bg")
      and $sel->ensembl_wait_for_ajax('15000')
      and $sel->ensembl_images_loaded;      
    }

    $sel->ensembl_click_links([
      "link=Splice variants*",
      "link=Supporting evidence",
      "link=Sequence",
      "link=External references*",
      "link=Comparative Genomics"
     ],'20000');
    $sel->ensembl_click_links(["link=Regulation"]) if($SD->table_info_other(ucfirst($self->species),'funcgen', 'feature_set')->{'rows'} && $gene_text !~ /^ASMPATCH/);
    
    if(lc($self->species) eq 'homo_sapiens') {
      print "  Test ZMenu on Regulation\n";
      $sel->ensembl_open_zmenu('RegulationImage','class^="group"');
      $sel->click_ok("link=ENSR*")
      and $sel->ensembl_wait_for_ajax('50000','2000')
      and $sel->go_back();
    }

    my ($alignment_count,$multi_species_count) = $self->alignments_count($SD);
    $sel->ensembl_click_links(["link=Genomic alignments"],'20000') if($alignment_count);
    #"link=Gene Tree (image)", need to add back to array below
    $sel->ensembl_click_links([      
      "link=Gene Tree (text)",
      "link=Gene Tree (alignment)"
    ]) if(lc($self->species) ne 'saccharomyces_cerevisia');
    
    my $counts = $self->count_homologues($gene_param);
    $sel->ensembl_click_links(["link=Orthologues ($counts->{'orthologs'})"]) if($counts->{'orthologs'});    
    $sel->ensembl_click_links(["link=Paralogues ($counts->{'paralogs'})"]) if($counts->{'paralogs'});
    $sel->ensembl_click_links(["link=Protein families*"]) if($counts->{'families'});
    
    $sel->click_ok("link=JalView")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->go_back() if(lc($self->species) eq 'homo_sapiens'); #testing for human only as this is opening too many java applet and making the server slow

    $sel->pause(1000);
    $sel->ensembl_click_links(["link=all proteins in family"]) if($counts->{'families'});

    $sel->ensembl_click_links(["link=Variation Table", "link=Variation Image", "link=Structural Variation"]) if($species_db->{'database:variation'} && $gene_text !~ /^ASMPATCH/);
    $sel->ensembl_click("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->click_ok("link=Configure this page")
    and $sel->ensembl_wait_for_ajax
    and $sel->click_ok("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->click_ok("modal_bg")
    and $sel->ensembl_wait_for_page_to_load;

    $sel->ensembl_click_links(["link=Gene history"]) if($SD->table_info_other(ucfirst($self->species),'core', 'stable_id_event')->{'rows'});
        
    $self->export_data('FASTA sequence','cdna:') if(lc($self->species) eq 'homo_sapiens');
    
  } else {
    print "  No Gene \n";    
  }
}

1;