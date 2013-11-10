package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use previous qw(merge_all);

sub merge_all {
  my $species_defs = $_[0];
  $species_defs->{'_storage'}{'GENOVERSE_JS_NAME'} = merge($species_defs, 'js', [split 'modules', __FILE__]->[0] . 'htdocs', 'genoverse');
  
  PREV::merge_all(@_);
}

1;
