# $Id$
package EnsEMBL::Selenium::Test::Species;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl base module for species
# NOTE: THIS IS A BASE CLASS DON'T ADD ANY TEST CASES IN HERE. Generic functions can be added
#------------------------------------------------------------------------------

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
  my $url = $sel->get_location();
  
  print "  Test Attach das\n";
  
  $sel->ensembl_click("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_click("link=Custom Data")  
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)
  and $sel->ensembl_click("link=Attach DAS")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)
  and $sel->type_ok("name=preconf_das", "http://das.sanger.ac.uk/das")
  and $sel->ensembl_click("wizard_submit")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)  
  and $sel->ensembl_click("//div[\@id='DasSources']//input[\@type='checkbox'][1]") # tick first das source
  and $sel->ensembl_click("wizard_submit")
  and $sel->wait_for_text_present_ok("The following DAS sources have now been attached")
  and $sel->ensembl_click("//div[\@class='modal_close']");
}

sub attach_remote_file {
  my ($self, $name, $format, $file_url) = @_;
  my $sel  = $self->sel;
  
  $name   ||= 'test';
  $format ||= 'BED'; 
  $file_url ||= "http://www.ensembl.org/info/website/upload/sample_files/example.bed";
  
  print "  Test Attach remote file\n";
 
  $sel->ensembl_click("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok(undef,10000)
  and $sel->ensembl_click("link=Custom Data")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)
  and $sel->ensembl_is_text_present("Your data");
 
  $sel->ensembl_click("link=Attach Remote File")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
  
  $sel->type_ok("name=url","$file_url")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("name", "$name")
  and $sel->ensembl_click("name=wizard_submit")
  and $sel->ensembl_wait_for_ajax(5000,5000); #timeout=5s and pause=5s
  
  $sel->ensembl_is_text_present("Go to first region with data");
  $sel->ensembl_click("css=div.modal_close");
  
  #Checking if karyotype image loaded fine
  $sel->ensembl_wait_for_ajax_ok(undef,5000)
  and $sel->ensembl_images_loaded_ok;
}
sub add_track {  
  my $self = shift;
  my $sel  = $self->sel;
    
  $self->upload_data;   #BED
  $self->upload_data('BEDGRAPH', 'bedGraph', undef, 'http://www.ensembl.org/info/website/upload/sample_files/bedgraph_example.bed' ); #bedgraph format  
  $self->upload_data('GFF', 'GFF', undef, 'http://www.ensembl.org/info/website/upload/sample_files/example.gff' ); #GFF format
  $self->upload_data('GTF', 'GTF', undef, 'http://www.ensembl.org/info/website/upload/sample_files/example.gtf' ); #GTF format
  $self->upload_data('PSL', 'PSL', undef, 'http://www.ensembl.org/info/website/upload/sample_files/example.psl' ); #PSL format
  $self->upload_data('WIG', 'WIG', undef, 'http://www.ensembl.org/info/website/upload/sample_files/example.wig' ); #WIG format

  print "  Test selecting track(uploaded data)\n";
  $sel->ensembl_click("link=Configure Page")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 
  $sel->ensembl_is_text_present("BED")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[1]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']");
  
  $sel->ensembl_is_text_present("BEDGRAPH")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[2]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']");
  
  $sel->ensembl_is_text_present("GFF")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[3]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']");
      
  $sel->ensembl_is_text_present("GTF")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[4]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']"); 
  
  $sel->ensembl_is_text_present("PSL")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[5]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']"); 
  
  $sel->ensembl_is_text_present("WIG")
  and $sel->ensembl_click("//form[\@id='location_genome_configuration']/div[1]/div/ul/li[6]/img")
  and $sel->ensembl_click("//img[\@alt='Arrows on both sides']"); 
    
  $sel->ensembl_click("css=div.modal_close")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)   
  #and $sel->ensembl_is_text_present("Click on the image above to jump to a chromosome, or click and drag to select a region")
  and $sel->ensembl_is_text_present("BED")            #making sure karyotype displayed the track for the uploaded data(track name in the uploaded file)
  and $sel->ensembl_is_text_present("BEDGRAPH")
  and $sel->ensembl_is_text_present("GFF")
  and $sel->ensembl_is_text_present("GTF")
  and $sel->ensembl_is_text_present("PSL")
  and $sel->ensembl_is_text_present("WIG")   #name of track in the WIG upload file  
}

sub configure_page {
  my $self = shift;
  my $sel  = $self->sel;

  print "  Test Configure Page\n";
  $sel->ensembl_click("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)
  and $sel->ensembl_is_text_present("Configure Page");

  $sel->ensembl_click("link=Display options")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
  $sel->select_ok("rows","2");
  $sel->type_ok("name=chr_length","400");
  $sel->ensembl_click("modal_bg")
  and $sel->ensembl_wait_for_ajax_ok(undef,'5000')
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

#To turn display empty track on
sub display_empty_track {
  my ($self) = @_;
  
  my $sel = $self->sel;
  print "  Turning display empty track on\n";
  $sel->ensembl_click("link=Configure this page")  
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
  
  $sel->ensembl_click("link=Information and decorations")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
  
  $sel->ensembl_click("//form[\@id='location_viewbottom_configuration']/div[7]/div/ul/li[5]/img")   #turn the track display empty tracks on 
  and $sel->ensembl_click("modal_bg")  
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);
}

#text_to_check is the text to verify when the output is displayed for example for csv you will want to check if seqname,source is present
sub export_data {
  my ($self, $output, $text_to_check) = @_;
  my $sel = $self->sel;
  
  $output ||= 'CSV (Comma separated values)';
  
  print "  Test Export Data\n";
  $sel->ensembl_click("link=Export data")
  and $sel->ensembl_wait_for_ajax_ok(50000,'25000');  
  
  $sel->select_ok("output","$output")
  and $sel->ensembl_click("name=next");
  
  $sel->ensembl_wait_for_ajax_ok(undef,5000);
  $sel->ensembl_is_text_present("Please choose the output format for your export");
  
#  $sel->uncheck_ok("name=bed_variation") if($output eq 'BED Format');
  
  #since selenium can't cope with multiple windows and the output is opened in multiple windows, workaround is to get the url of the HTML output and open it.
  my $output_url = $sel->get_eval(qq{
    var \$ = selenium.browserbot.getCurrentWindow().jQuery;
    \$('a.modal_close').attr('href')
  });

  #removing variation param because this is making the export so slow that the url fail to open even after 50s
  $output_url =~ s/param=variation;//g if($output_url =~ /param=variation;/);
  $output_url =~ s/^\///g;
  $output_url =~ s/^(\s)*//g;

  $sel->ensembl_click("modal_bg");  
  $sel->open_ok("$output_url")  
  and $sel->ensembl_wait_for_page_to_load(50000);
  $sel->ensembl_is_text_present("$text_to_check");
}

sub features_karyotype {
  my ($self, $feature_id) = @_;
  my $sel  = $self->sel;

  $feature_id ||= 'BRCA2';

  print "  Test Features on karyotype\n";

  $sel->ensembl_click("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok(undef,10000)
  and $sel->ensembl_click("link=Custom Data")
  and $sel->ensembl_wait_for_ajax_ok(undef,10000)
  and $sel->ensembl_is_text_present("Your data");

  $sel->ensembl_click("link=Features on Karyotype")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);

  $sel->type_ok("name=id","$feature_id")
  and $sel->ensembl_click("name=submit")
  and $sel->ensembl_wait_for_ajax_ok(5000,5000) #timeout=5s and pause=5s
  and $sel->ensembl_is_text_present("$feature_id");
}

# function to get the number of tracks active (should be called before and after choosing the track to check if the counts has been updated correctly).
# parameters: 
# Note: Function should be called after link(track) has been clicked.
sub get_track_counts {
  my ($self) = @_;
  my $sel = $self->sel;

  #$('.modal_nav li:not(.active) .on:first');   #TODO: get track count and track name for not active track (first one only) just to make sure they stay the same

  # Getting the track count for the selected track, return a string containing _ to separate the child and parent track count.
  my $track = $sel->get_eval(qq{
        var \$ = selenium.browserbot.getCurrentWindow().jQuery;
        var el = \$('.track:visible').eq(0);
        var type = el.parents('.config').attr('class').replace(/config|active|first|\\s/g, '');
        var subset = el.parents('.subset').attr('class').replace(/subset|active|first|\\s/g, '');
        
        \$('.modal_nav').find('a.' + type + ', a.' + type + '-' + subset).siblings('.count').children('.on').map(function(){ return \$(this).html(); }).toArray().join('_');        
     });

    my @count_array  = split('_',$track);
    my $parent_track = @count_array[0]; #getting track counts for parent track (the main track)
    my $sub_track    = @count_array[1];    #getting the count for the sub track (if there is any)

  return ($sub_track, $parent_track)
}

sub open_species_homepage {
  my ($self, $species, $timeout, $species_bio_name) = @_;
  my $sel  = $self->sel;
#  my $species_name = $species;
#  $species_name    =~ s/_/ /;

  ##TODO::CHeck for species image loaded fine
  $sel->open_ok("$species/Info/Index")
  and $sel->ensembl_wait_for_page_to_load($timeout)
  and $sel->ensembl_is_text_present($species_bio_name);
}

#function to get all the databases available for the species, take species_def as argument
sub species_databases {
  my ($self, $SD) = @_;
  
  my $hash = { map { ('database:'. lc(substr $_, 9) => 1) } keys %{$SD->get_config(ucfirst($self->species), 'databases')} };
  map { my $key =lc(substr($_,9)); $hash->{"database:$key"} = 1} @{$SD->compara_like_databases || [] };  

  return $hash; 
}

# function to turn tracks ON/OFF and check to see if the total track count increase/decrease by 1
# PARAMETERS: $track_name - The track name as it is shown on the left side of the configuration panel within the a tag(link) 
#             $track_image_xpath - The track image (the square box to select the track) xpath for the track to be turn on/off (eg: //form[\@id='location_viewbottom_configuration']/div[4]/div/ul/li[1]/img)
#             $action - whether to turn the track on or off (eg: 'on' or 'off')
#             $search(optional) - the track name you want to search for in the search box.
sub turn_track {
  my ($self, $track_name, $track_image_xpath, $action, $search) = @_;

  my $sel = $self->sel;
  my $parent_test;
  
  $sel->ensembl_click("link=Configure this page")  
  and $sel->ensembl_wait_for_ajax_ok(undef,4000)
  and $sel->ensembl_is_text_present("Active tracks");
  
  if($search) {
    print "  Test searching for $search track and turning the track ".uc($action)."\n" ;
    
    $sel->ensembl_click("name=configuration_search_text")    
    and $sel->type_keys_ok("configuration_search_text", "$search") #searching for the track in the search textfield    
    and $sel->ensembl_wait_for_ajax_ok(undef,'2000');
  } else {
    print "  Test turning $track_name track ".uc($action)."\n";
    $sel->ensembl_click("link=$track_name")
    and $sel->ensembl_wait_for_ajax_ok(undef,10000);
  }

  #function to get the total count for track (parent_track is empty since there isn't any parent)
  my ($sub_track, $parent_track) = $self->get_track_counts;

  # if there is a main track (parent track) get the parent track name and build the text to check for test
  if($sub_track) {
    my $parent_trackname = $sel->get_eval(qq{
      var \$ = selenium.browserbot.getCurrentWindow().jQuery;
      var el = \$('.track:visible').eq(0);
      var type = el.parents('.config').attr('class').replace(/config|active|first|\\s/g, '');
      var subset = el.parents('.subset').attr('class').replace(/subset|active|first|\\s/g, '');
  
      \$('.modal_nav').find('a.' + type ).html();
    });
    $parent_track = lc($action) eq 'on' ? $parent_track + 1 : $parent_track - 1;
    $parent_track  = qq{$parent_trackname($parent_track/*};
    $parent_test   = 1;
  } else {
    $sub_track = $parent_track;
  }
  
  #Check if image_xpath exist/valid, if not go to label SKIP and carry on
  if(!$sel->is_element_present($track_image_xpath)) {
    print "ERROR:: Invalid xpath ($track_image_xpath) for track $track_name !!! \n";
    goto SKIP;
  }

  (my $track_input = $track_image_xpath) =~ s/img/input/g; #the hidden input to check if the track is on/off  
  
  $sub_track += 1 if($sel->get_value($track_input) eq 'off' && lc($action) eq 'on');  # track is chosen, track count should increment by 1 only do this if track is off and action is turning track on.
  $sub_track -= 1 if($sel->get_value($track_input) ne 'off' && lc($action) eq 'off'); # unselecting track, track count should decement by 1 only if it wasn't off before and action is turning track off.

  my $track_select_image = $track_image_xpath;
  $track_select_image =~ s/img/ul\/li[4]\/img/g if(lc($action) eq 'on'); #generating the xpath for the track select image (the normal one)
  $track_select_image =~ s/img/ul\/li[2]\/img/g if(lc($action) eq 'off');#generating the xpath for the track select image (the blank one)

  $sel->ensembl_click($track_image_xpath)  
  and $sel->ensembl_click($track_select_image)    
  and $sel->ensembl_is_text_present("$track_name($sub_track/*");  #maybe add a different error if failure (use selenium is_text_present instead of ensembl one)  
  
  $sel->ensembl_is_text_present($parent_track) if($parent_test);
  
  SKIP:
  $sel->ensembl_click("modal_bg")
  and $sel->ensembl_wait_for_ajax_ok(undef,6000)
  and $sel->ensembl_images_loaded;
}

# Function: Uploading data from the manage your data in configuration panel 
# params: $name        - name of the uploaded data/track (name field on the form - also will be the name that appears in the configuration panel when choosing the track)
#         $format      - format of the data to be uploaded (should match the HTML of the format dropdown)
#         $data        - include this is you want to upload data for the track. (will insert the data in the paste file textarea - optional)
#         $upload_file - url for the file to be uploaded (optional)

sub upload_data {
  my ($self, $name, $format, $data, $upload_file) = @_;
  my $sel  = $self->sel;
  
  $name   ||= 'BED';
  $format ||= 'BED'; 
  $data   ||= qq{
  track name=pairedReads2 description="BED" useScore=1 color=ff5cbc
  chr21 31010000 31050000 cloneA 960 + 1010000 1050000 0 2 567,488, 0,3512
  chr21 31020000 31060000 cloneB 900 - 1020000 1060000 0 2 433,399, 0,3601 
};

  print "  Test Upload data $format \n";
  $sel->ensembl_click("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok(undef,10000)
  and $sel->ensembl_click("link=Custom Data")
  and $sel->ensembl_wait_for_ajax_ok(undef,10000)
  and $sel->ensembl_is_text_present("Your data");

  $sel->ensembl_click("link=Add your data")
  and $sel->ensembl_wait_for_ajax_ok(undef,7000)  
  and $sel->type_ok("name=name","$name")
  and $sel->select_ok("format", "$format")
  and $upload_file ? $sel->type_ok("name=url", "$upload_file") : $sel->type_ok("text", "$data")  
  and $sel->ensembl_click("name=submit")
  and $sel->ensembl_wait_for_ajax_ok(50000,10000); #timeout=50s and pause=10s
  
  $sel->ensembl_is_text_present("Go to first region with data");
  $sel->ensembl_click("css=div.modal_close")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000);  
}

1;
