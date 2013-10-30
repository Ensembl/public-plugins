package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

sub merge_plugin_solr {
  my $species_defs = shift;
  my $dir          = [split 'modules', __FILE__]->[0] . 'htdocs';
  
  $species_defs->{'_storage'}{'SOLR_JS_NAME'}  = merge($species_defs, 'js',  $dir, 'solr');
  $species_defs->{'_storage'}{'SOLR_CSS_NAME'} = merge($species_defs, 'css', $dir, 'solr');
}

1;
