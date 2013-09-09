package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

sub merge_plugin_genoverse {
  my $species_defs = shift;
  $species_defs->{'_storage'}{'GENOVERSE_JS_NAME'} = merge($species_defs, 'js', [split 'modules', __FILE__]->[0] . 'htdocs', 'genoverse');
}

1;
