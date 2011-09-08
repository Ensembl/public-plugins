package EnsEMBL::Selenium::Test::Species;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 5000);
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
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->click_ok("link=Attach DAS")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->type_ok("name=preconf_das", "http://das.sanger.ac.uk/das")
  and $sel->click_ok("wizard_submit")
  and $sel->ensembl_wait_for_ajax_ok(undef,5000)  
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
  
  print "  Test Attach remote file\n";
 
  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_is_text_present("Your data");
 
  $sel->click_ok("link=Attach Remote File")
  and $sel->ensembl_wait_for_ajax_ok;
  
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
  
  print "  Test Upload data\n";   
  $self->upload_data;  
  $sel->click_ok("link=Configure Page")
  and $sel->ensembl_wait_for_ajax_ok;

  $sel->ensembl_is_text_present("test2")
  and $sel->click_ok("//form[\@id='location_genome_configuration']/div[1]/ul/li/img")
  and $sel->click_ok("//img[\@alt='Arrows on both sides']");
  
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_is_text_present("pairedReads2")
  and $sel->ensembl_images_loaded;
}

sub configure_page {
  my $self = shift;
  my $sel  = $self->sel;

  print "  Test Configure Page\n";
  $sel->click_ok("link=Configure this page")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_is_text_present("Configure Page");

  $sel->click_ok("link=Display options")
  and $sel->ensembl_wait_for_ajax_ok;
  $sel->select_ok("rows","2");
  $sel->type_ok("name=chr_length","400");
  $sel->click_ok("modal_bg")
  and $sel->ensembl_wait_for_ajax_ok(undef,'1200')
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
  
  print "  Test Export Data\n";
  $sel->ensembl_click("link=Export data")
  and $sel->ensembl_wait_for_ajax_ok(20000);  
  
  $sel->select_ok("output","$output")
  and $sel->click_ok("name=next");
  
  $sel->pause('3000');
  $sel->ensembl_is_text_present("Please choose the output format for your export");

  #since selenium can't cope with multiple windows and the output is opened in multiple windows, workaround is to get the url of the HTML output and open it.
  my $output_url = $sel->get_eval(qq{
    var \$ = selenium.browserbot.getCurrentWindow().jQuery; 
    \$('a.modal_close').attr('href')
  });
  $sel->open_ok($output_url,50000);
  $sel->ensembl_is_text_present("$text_to_check");  
}

sub features_karyotype {
  my ($self, $feature_id) = @_;
  my $sel  = $self->sel;

  $feature_id ||= 'BRCA2';

  print "  Test Features on karyotype\n";

  $sel->click_ok("link=Manage your data")
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_is_text_present("Your data");

  $sel->click_ok("link=Features on Karyotype")
  and $sel->ensembl_wait_for_ajax_ok;

  $sel->type_ok("name=id","$feature_id")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax_ok(5000,5000); #timeout=5s and pause=5s
  #and $sel->ensembl_is_text_present("$feature_id");

#   $sel->click_ok("modal_bg")
#   and $sel->ensembl_wait_for_ajax_ok   
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
  and $sel->ensembl_wait_for_ajax_ok
  and $sel->ensembl_is_text_present("Your data");

  $sel->click_ok("link=Upload Data")
  and $sel->ensembl_wait_for_ajax_ok;
  
  $sel->type_ok("name=name","$name")
  and $sel->select_ok("format", "$format")
  and $sel->type_ok("text", "$data")
  and $sel->click_ok("name=submit")
  and $sel->ensembl_wait_for_ajax_ok(50000,10000); #timeout=50s and pause=5s
  
  $sel->ensembl_is_text_present("Go to first region with data");  
}

1;