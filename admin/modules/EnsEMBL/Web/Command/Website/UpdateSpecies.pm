package EnsEMBL::Web::Command::Website::UpdateSpecies;

### Updates ensembl_website with settings from SiteDefs

use strict;
use warnings;

use EnsEMBL::Web::Data::Release;
use EnsEMBL::Web::Data::Species;
use EnsEMBL::Web::Data::ReleaseSpecies;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url = '/Website/CurrentSpecies';
  my $param = {};
  my $release_id = $object->species_defs->ENSEMBL_VERSION;

  my $current_release = EnsEMBL::Web::Data::Release->new($release_id);
  my $previous_release = EnsEMBL::Web::Data::Release->new($release_id - 1);
  my @current_species = $current_release->species;

  foreach my $species ( $object->species_defs->valid_species ) {
    next if grep {$_ eq $species} @current_species;
    ## Get info about previous release entries
    my $db_species = EnsEMBL::Web::Data::Species->find('name' => $species); 
    my $assembly_code = 'TBC';
    my $assembly_name = 'TBC';
    if ($db_species) {
      my $previous = EnsEMBL::Web::Data::ReleaseSpecies->find(
        'release_id' => $release_id - 1, 'species_id' => $db_species->id);
      if ($previous) {
        $assembly_code = $previous->assembly_code;
        $assembly_name = $previous->assembly_name;
      }
    }
    my $add_to_release = EnsEMBL::Web::Data::ReleaseSpecies->new();
    $add_to_release->release_id($release_id);
    $add_to_release->species_id($db_species->id);
    $add_to_release->assembly_code($assembly_code);
    $add_to_release->assembly_name($assembly_name);
    $add_to_release->save;
  }
  
  $self->ajax_redirect($url, $param); 
}

}

1;
