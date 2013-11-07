package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use previous qw(merge_all);

sub merge_all {
  PREV::merge_all(@_);
  
  my $species_defs = shift;
  $species_defs->{'_storage'}{'GENOVERSE_JS_NAME'} = merge($species_defs, 'js', [split 'modules', __FILE__]->[0] . 'htdocs', 'genoverse');
}

1;
