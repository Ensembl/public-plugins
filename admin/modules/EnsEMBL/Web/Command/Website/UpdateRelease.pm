package EnsEMBL::Web::Command::Website::UpdateRelease;

### Updates ensembl_website with settings from SiteDefs

use strict;
use warnings;

use EnsEMBL::Web::Data::Release;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url = '/Website/CurrentSpecies';
  my $param = {};
  my $release_id = $object->species_defs->ENSEMBL_VERSION;

  ## Do some sanity checking on input! Set release date to first of next month
  ## if not correctly formatted
  my $date = $object->param('date');
  if ($date !~ /\d{4}-\d{2}-\d{2}/) {
    my @time = localtime();
    my $year = $time[4] == 11 ? $time[5] + 1901 : $time[5] + 1900;
    my $next_month = sprintf('%02d', $time[4] + 2);
    $date = $year.'-'.$next_month.'-01';
  }

  my $new_release = EnsEMBL::Web::Data::Release->new();
  $new_release->number($release_id);
  $new_release->date($date);
  $new_release->archive($object->species_defs->ARCHIVE_VERSION);
  $new_release->online('Y');
  $new_release->mart('Y');
  $new_release->save;
  
  $self->ajax_redirect($url, $param); 
}

}

1;
