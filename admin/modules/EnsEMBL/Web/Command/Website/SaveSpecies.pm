package EnsEMBL::Web::Command::Website::SaveSpecies;

use strict;
use warnings;

use EnsEMBL::Web::Data::Species;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url = '/Website/CurrentSpecies';
  my $param = {};
 
  ## Tidy up user input 
  my $name = $object->param('name');
  $name =~ s/ /_/; 
  my $assembly = $object->param('assembly') || 'TBC';

  ## Try to create a unique code
  my @split = split('_', $name);
  my $code = lc(substr($split[0], 0, 1).substr($split[1], 0, 1));
  my $duplicate = EnsEMBL::Web::Data::Species->find('code' => $code);
  if ($duplicate) {
    $code = lc(substr($split[0], 0, 1).substr($split[1], 0, 3));
    $duplicate = EnsEMBL::Web::Data::Species->find('code' => $code);
    if ($duplicate) {
      $code = '';
      ## TODO: Set a warning here!
    }
  }

  ## First, get/save species information
  my $species = EnsEMBL::Web::Data::Species->find('name' => $name);
  unless ($species) {
    $species = EnsEMBL::Web::Data::Species->new();
    $species->name($name);
    $species->code($code);
    $species->common_name($object->param('common_name'));
    $species->vega('N');
    $species->online('Y');
    $species->save;
  }

  ## Then add this species to release_species table 
  my $add_to_release = EnsEMBL::Web::Data::ReleaseSpecies->new();
  $add_to_release->release_id($object->species_defs->ENSEMBL_VERSION);
  $add_to_release->species_id($species->species_id);
  $add_to_release->assembly_code($assembly);
  $add_to_release->assembly_name($assembly);
  $add_to_release->save;

  $self->ajax_redirect($url, $param); 
}

}

1;
