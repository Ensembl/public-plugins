=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
  my $sp_bio_name = $SD->get_config($self->species,'SPECIES_BIO_NAME');  
  $self->open_species_homepage($self->species, undef, $sp_bio_name);

#karyotype link test
  if($SD->get_config($self->species, 'ENSEMBL_CHROMOSOMES') && !scalar @{$SD->get_config($self->species, 'ENSEMBL_CHROMOSOMES')}) {
    print "  No Karyotype \n";
    #$sel->ensembl_is_text_present("Karyotype (not available)");
  } else {
    $sel->ensembl_click_links(["link=View karyotype"], "60000");
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

    #Testing ZMenu on karyotype
    if($self->species eq 'homo_sapiens') {      
      $sel->ensembl_open_zmenu('Genome')
      and $sel->ensembl_is_text_present("Jump to location view")
      and $sel->ensembl_click_links(["link=Jump to location view"]);
    }
  }
}
1;
