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
      print "Test ZMenu on Gene Summary\n";
      $sel->ensembl_open_zmenu('TranscriptsImage','class^="drag"');
      $sel->click_ok("link=Jump to location View")
      and $sel->ensembl_wait_for_ajax('50000','2000')
      and $sel->go_back();
      
      $sel->ensembl_wait_for_page_to_load;
      
      #Adding a track from the configuration panel
      print "Test Configure page, adding a track \n";
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
     ]);
    $sel->ensembl_click_links(["link=Regulation"]) if($SD->table_info_other(ucfirst($self->species),'funcgen', 'feature_set')->{'rows'} && $gene_text !~ /^ASMPATCH/);
    
    if(lc($self->species) eq 'homo_sapiens') {
      print "Test ZMenu on Regulation\n";
      $sel->ensembl_open_zmenu('RegulationImage','class^="group"');
      $sel->click_ok("link=ENSR*")
      and $sel->ensembl_wait_for_ajax('50000','2000')
      and $sel->go_back();
    }

    my ($alignment_count,$multi_species_count) = $self->alignments_count($SD);
    $sel->ensembl_click_links(["link=Genomic alignments"]) if($alignment_count);
    #"link=Gene Tree (image)", need to add back to array below
    $sel->ensembl_click_links([      
      "link=Gene Tree (text)",
      "link=Gene Tree (alignment)"
    ]);
    
    my $counts = $self->count_homologues($gene_param);
    $sel->ensembl_click_links(["link=Orthologues ($counts->{'orthologs'})"]) if($counts->{'orthologs'});    
    $sel->ensembl_click_links(["link=Paralogues ($counts->{'paralogs'})"]) if($counts->{'paralogs'});
    $sel->ensembl_click_links(["link=Protein families*"]) if($counts->{'families'});
    
    $sel->click_ok("link=JalView")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->go_back() if(lc($self->species) eq 'homo_sapiens'); #testing for human only as this is opening too many java applet and making the server slow

    $sel->pause(1000);
    $sel->ensembl_click_links(["link=all proteins in family"]);

    $sel->ensembl_click_links(["link=Variation Table", "link=Variation Image", "link=Structural Variation"]) if($species_db->{'database:variation'} && $gene_text !~ /^ASMPATCH/);
    $sel->click_ok("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->click_ok("link=Configure this page")
    and $sel->ensembl_wait_for_ajax
    and $sel->click_ok("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->click_ok("modal_bg")
    and $sel->ensembl_wait_for_page_to_load;

    $sel->ensembl_click_links(["link=Gene history"]) if($SD->table_info_other(ucfirst($self->species),'core', 'stable_id_event')->{'rows'});
        
    $self->export_data('FASTA sequence','cdna:') if(lc($self->species) eq 'homo_sapiens');
    
  } else {
    print "No Gene \n";    
  }
}

sub test_karyotype {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;
  $self->open_species_homepage($self->species);

#karyotype link test
  if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) {
    print "No Karyotype \n";
    $sel->ensembl_is_text_present("Karyotype (not available)");
  } else {
    $sel->ensembl_click_links(["link=Karyotype"]);
    $sel->ensembl_is_text_present("Click on the image above to jump to a chromosome");

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
    if($self->species eq 'homo_sapiens') {
      print "Test ZMenu\n";
      $sel->ensembl_open_zmenu('Genome')
      and $sel->ensembl_is_text_present("Jump to location View")
      and $sel->ensembl_click_links(["link=Jump to location View"]);
    }
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
    $sel->ensembl_is_text_present($SD->thousandify(@location_array[1]))
    and $sel->ensembl_is_text_present("Region in detail");
#    and $sel->ensembl_images_loaded;

    #Test ZMENU (only for human)
    if($self->species eq 'homo_sapiens') {
      $self->attach_das;
      $sel->ensembl_wait_for_ajax(15000);
      
      $sel->ensembl_open_zmenu('Summary',"class^=drag");
      $sel->click_ok("link=Centre here")
      and $sel->ensembl_wait_for_ajax(undef,'2000')      
      and $sel->go_back();      

      #TODO:: ZMenu on viewtop and ViewBottom panel
    }
    #Whole genome link
    $sel->ensembl_click_links(["link=Whole genome"]);
    $sel->ensembl_is_text_present("This genome has yet to be assembled into chromosomes") if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')});

    @location_array[0] =~ s/chr//;
    #Chromosome summary link (only click for sepcies with chromosome)
    if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')})) {
      $sel->ensembl_click_links(["link=Chromosome summary"]);
      $sel->ensembl_is_text_present("Chromosome Statistics");
    }

    $sel->ensembl_click_links(["link=Region overview","link=Region in detail","link=Comparative Genomics"]);

    my %synteny_hash  = $SD->multi('DATABASE_COMPARA', 'SYNTENY');    
    my $synteny_count = scalar keys %{$synteny_hash{ucfirst($self->species)}};
    my %alignments    = $SD->multi('DATABASE_COMPARA', 'ALIGNMENTS');
    
    my ($alignment_count,$multi_species_count) = $self->alignments_count($SD);

    $sel->ensembl_click_links(["link=Alignments (image) ($alignment_count)","link=Alignments (text) ($alignment_count)","link=Multi-species view ($multi_species_count)"],'8000') if($alignment_count);
    $sel->ensembl_click_links(["link=Synteny ($synteny_count)"], '8000') if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) && $synteny_count);

    #Markers        
    if($SD->table_info_other(ucfirst($self->species),'core', 'marker_feature')->{'rows'}) {
      $sel->ensembl_click_links(["link=Markers"], '8000');

      if($self->species eq 'homo_sapiens') {
        $sel->ensembl_is_text_present("mapped markers found:");
        $sel->ensembl_click_links(["link=D6S989"]);
        $sel->ensembl_is_text_present("Marker D6S989");
        $sel->go_back();
      }
    }

    #Testing genetic variations last for human only
    if($self->species eq 'homo_sapiens') {
      my $resequencing_counts = $SD->databases->{'DATABASE_VARIATION'}{'#STRAINS'} if exists $SD->databases->{'DATABASE_VARIATION'};
      $sel->ensembl_click_links(["link=Resequencing ($resequencing_counts)"], '8000');
      $sel->type_ok("loc_r", "6:27996744-27996844");
      $sel->click_ok("//input[\@value='Go']");
      $sel->pause(5000);
      $sel->ensembl_is_text_present("Basepairs in secondary strains");

      $sel->open_ok("Homo_sapiens/Location/LD?db=core;r=6:27996744-27996844;pop1=12131");
      $sel->pause(5000);
      $sel->ensembl_is_text_present("Prediction method:");
      
      $sel->ensembl_click_links(["link=Region in detail"]);
      $self->export_data('CSV (Comma separated values)','seqname,source');
    }

  } else {
    print "No Location \n";
    $sel->ensembl_is_text_present("Location (not available)");
  }
}

sub test_transcript {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;  
  my $species_db = $self->species_databases($SD);
  
  $self->open_species_homepage($self->species);
  my $transcript_text  = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{TRANSCRIPT_TEXT};
  my $transcript_param = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{'TRANSCRIPT_PARAM'};

  #Oryzias_latipes doesn't have any transcript info.
  if($transcript_text && lc($self->species) ne 'Oryzias_latipes') {
    $sel->ensembl_click_links(["link=Transcript ($transcript_text)"],'20000')
    and $sel->ensembl_is_text_present("$transcript_param");
    
    #Testing ZMenu (doing only for human)
    if(lc($self->species) eq 'homo_sapiens') {
      $sel->ensembl_open_zmenu('TranscriptImage','title^="Transcript:"');
      $sel->click_ok("link=ENSG*")
      and $sel->ensembl_wait_for_ajax(undef,'2000')
      and $sel->go_back();
    }
 
    $sel->ensembl_click_links(["link=Supporting evidence*"]) if(!(lc($self->species) eq 'caenorhabditis_elegans' || lc($self->species) eq 'drosophila_melanogaster' || lc($self->species) eq 'saccharomyces_cerevisiae')); #for now that will do
    $sel->ensembl_click_links(["link=Exons*", "link=cDNA", "link=Protein", "link=General identifiers*"],'10000');
    
    my $oligos = $self->count_oligos($transcript_param);
    $sel->ensembl_click_links(["link=Oligo probes*"]) if($oligos);
    
    $sel->ensembl_click_links(["link=Ontology chart*", "link=Ontology table*"],'20000') if(lc($self->species) eq 'homo_sapiens' or lc($self->species) eq 'mus_musculus');
    $sel->ensembl_click_links(["link=Population comparison", "link=Comparison image"],'20000') if($species_db->{'database:variation'} && $SD->databases->{'DATABASE_VARIATION'}->{'#STRAINS'});
    $sel->ensembl_click_links(["link=Protein summary"],'20000');
    
    #Adding a track from the configuration panel
    if(lc($self->species) eq 'homo_sapiens') {          
      print "Test Configure page, removing a track \n";
      $sel->click_ok("link=Configure this page")
      and $sel->ensembl_wait_for_ajax('10000')
      and $sel->click_ok("link=Information*")
      and $sel->ensembl_wait_for_ajax('10000')
      and $sel->click_ok("//form[\@id='transcript_translationimage_configuration']/div[1]/ul/li[1]/img") #untick the first track      
      and $sel->click_ok("modal_bg")
      and $sel->ensembl_wait_for_ajax('15000')
      and $sel->ensembl_images_loaded;
    }
    $sel->ensembl_click_links(["link=Domains & features*"],'20000') if $SD->table_info_other(ucfirst($self->species),'core', 'protein_feature')->{'analyses'};
    $sel->ensembl_click_links(["link=Variations*"],'20000') if($species_db->{'database:variation'} && $SD->databases->{'DATABASE_VARIATION'});
    
    $sel->click_ok("link=External Data")
    and $sel->ensembl_wait_for_page_to_load
    and $sel->click_ok("link=Configure this page")
    and $sel->ensembl_wait_for_ajax
    and $sel->click_ok("//div[\@class='ele-das']//input[\@type='checkbox'][1]") # tick first source
    and $sel->click_ok("modal_bg")
    and $sel->ensembl_wait_for_page_to_load;
    
    $sel->ensembl_click_links(["link=Transcript history", "link=Protein history"]) if $SD->table_info_other(ucfirst($self->species),'core', 'stable_id_event')->{'rows'};
    
    #Testing Export data
    $self->export_data('BED Format','Browser position') if(lc($self->species) eq 'homo_sapiens');
    
  } else {
   print "No Transcript \n"; 
  }
  
}

sub alignments_count {
  my ($self, $SD) = @_;
  my ($alignment_count, $multi_species_count);
  my %alignments    = $SD->multi('DATABASE_COMPARA', 'ALIGNMENTS');

  foreach (grep $_->{'species'}{ucfirst($self->species)}, values %alignments) {
    $alignment_count++;
    $multi_species_count++ if $_->{'class'} =~ /pairwise_alignment/;
  }

  return ($alignment_count,$multi_species_count);
}

sub attach_das {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  
  print "Test Attach das\n";
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
  and $sel->ensembl_is_text_present("Your data");
 
  $sel->click_ok("link=Attach Remote File")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=url","$file_url")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("name", "$name")
  and $sel->click_ok("name=wizard_submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->ensembl_is_text_present("Go to first region with data");  
}
sub add_track {  
  my $self = shift;
  my $sel  = $self->sel;
  
  print "Test Upload data\n";   
  $self->upload_data;  
  $sel->click_ok("link=Configure Page")
  and $sel->ensembl_wait_for_ajax;

  $sel->ensembl_is_text_present("test2")
  and $sel->click_ok("//form[\@id='location_genome_configuration']/div[1]/ul/li/img")
  and $sel->click_ok("//img[\@alt='Arrows on both sides']");
  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present("pairedReads2")
  and $sel->ensembl_images_loaded;
}

sub configure_page {
  my $self = shift;
  my $sel  = $self->sel;

  print "Test Configure Page\n";
  $sel->click_ok("link=Configure this page")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present("Configure Page");

  $sel->click_ok("link=Display options")
  and $sel->ensembl_wait_for_ajax;
  $sel->select_ok("rows","2");
  $sel->type_ok("name=chr_length","400");
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax(undef,'1200')
  and $sel->ensembl_is_text_present("Click on the image above to jump to a chromosome");
}

#function to get the orthologue and paralogue counts
sub count_homologues {
  my ($self, $stable_id) = @_;
  
  my $compara_db = $self->database('compara');
  my $compara_dbh = $compara_db->get_MemberAdaptor->dbc->db_handle;
  my $counts = {};

  my $res = $compara_dbh->selectall_arrayref(
    'select ml.type, h.description, count(*) as N
      from member as m, homology_member as hm, homology as h,
           method_link as ml, method_link_species_set as mlss
     where m.stable_id = ? and hm.member_id = m.member_id and
           h.homology_id = hm.homology_id and 
           mlss.method_link_species_set_id = h.method_link_species_set_id and
           ml.method_link_id = mlss.method_link_id
     group by description', {}, $stable_id
  );
  
  my ($family) = $compara_dbh->selectrow_array(
    'select count(*) from family_member fm, member as m where fm.member_id=m.member_id and stable_id=? and source_name =?',
    {}, $stable_id, 'ENSEMBLGENE'
  );
  
  $counts->{'families'} = $family;

  foreach (@$res) {
    if ($_->[0] eq 'ENSEMBL_PARALOGUES' && $_->[1] ne 'possible_ortholog') {
      $counts->{'paralogs'} += $_->[2];
    } elsif ($_->[1] !~ /^UBRH|BRH|MBRH|RHS$/) {
      $counts->{'orthologs'} += $_->[2];
    }
  }
  
  return $counts;
}
#To check if species has oligo in the transcript page
sub count_oligos {
  my ($self, $transcript_param) = @_;
  my $type = 'funcgen';
  return 0 unless $self->database('funcgen', lc($self->species));
  my $dbc = $self->database('funcgen',lc($self->species))->dbc; 
  
  my $sql = qq{
   SELECT count(distinct(ox.ensembl_id))
     FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND (ox.ensembl_object_type = 'ProbeSet'
           OR ox.ensembl_object_type = 'Probe')
      AND x.info_text = 'Transcript'
      AND x.dbprimary_acc = ?};
      
  my $sth = $dbc->prepare($sql); 
  $sth->execute($transcript_param);
  my $c = $sth->fetchall_arrayref->[0][0];

  return $c;
}

# To check if the species has supporting evidence in the transcript page
# function sub count_supporting_evidence  from Object/Transcript.pm


#text_to_check is the text to verify when the output is displayed for example for csv you will want to check if seqname,source is present
sub export_data {
  my ($self, $output, $text_to_check) = @_;
  my $sel = $self->sel;
  
  $output ||= 'CSV (Comma separated values)';
  
  print "Test Export Data\n";
  $sel->click_ok("link=Export data")
  and $sel->ensembl_wait_for_ajax(10000)
  and $sel->ensembl_is_text_present("Output:");
  
  $sel->select_ok("output","$output")
  and $sel->click_ok("name=next");
  
  $sel->pause('3000');
  $sel->ensembl_is_text_present("Please choose the output format for your export");

  #since selenium can't cope with multiple windows and the output is opened in multiple windows, workaround is to get the url of the HTML output and open it.
  my $output_url = $sel->get_eval(qq{
    var \$ = selenium.browserbot.getCurrentWindow().jQuery; 
    \$('a.modal_close').attr('href')
  });
  $sel->open_ok($output_url,10000);
  $sel->ensembl_is_text_present("$text_to_check");  
}

sub features_karyotype {
  my ($self, $feature_id) = @_;
  my $sel  = $self->sel;

  $feature_id ||= 'BRCA2';

  print "Test Features on karyotype\n";

  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present("Your data");

  $sel->click_ok("link=Features on Karyotype")
  and $sel->ensembl_wait_for_ajax;

  $sel->type_ok("name=id","$feature_id")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s

  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax
  and $sel->ensembl_is_text_present("$feature_id");
#  and $sel->ensembl_images_loaded;
}

sub open_species_homepage {
  my ($self, $species, $timeout) = @_;
  my $sel  = $self->sel;
  my $species_name = $species;
  $species_name    =~ s/_/ /;

  ##TODO::CHeck for species image loaded fine
  $sel->open_ok("$species/Info/Index")
  and $sel->ensembl_wait_for_page_to_load($timeout)
  and $sel->ensembl_is_text_present(ucfirst($species_name));
}

#function to get all the databases available for the species, take species_def as argument
sub species_databases {
  my ($self, $SD) = @_;
  
  my $hash = { map { ('database:'. lc(substr $_, 9) => 1) } keys %{$SD->get_config(ucfirst($self->species), 'databases')} };
  map { my $key =lc(substr($_,9)); $hash->{"database:$key"} = 1} @{$SD->compara_like_databases || [] };  

  return $hash; 
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
  and $sel->ensembl_is_text_present("Your data");

  $sel->click_ok("link=Upload Data")
  and $sel->ensembl_wait_for_ajax;
  
  $sel->type_ok("name=name","$name")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("text", "$data")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->ensembl_is_text_present("Go to first region with data");  
}

1;