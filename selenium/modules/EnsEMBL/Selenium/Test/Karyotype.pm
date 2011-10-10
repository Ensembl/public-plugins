# $Id$
package EnsEMBL::Selenium::Test::Karyotype;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl Karyotype link test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------

sub test_karyotype {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;
  $self->open_species_homepage($self->species);

#karyotype link test
  if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) {
    print "  No Karyotype \n";
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
      print "  Test ZMenu\n";
      $sel->ensembl_open_zmenu('Genome')
      and $sel->ensembl_is_text_present("Jump to location View")
      and $sel->ensembl_click_links(["link=Jump to location View"]);
    }
  }
}
1;