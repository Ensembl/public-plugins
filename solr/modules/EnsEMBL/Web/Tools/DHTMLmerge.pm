package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use previous qw(merge_all);

sub merge_all {
  my $species_defs = $_[0];
  my $dir          = [split 'modules', __FILE__]->[0] . 'htdocs';
  
  $species_defs->{'_storage'}{'SOLR_JS_NAME'}  = merge($species_defs, 'js',  $dir, 'solr');
  $species_defs->{'_storage'}{'SOLR_CSS_NAME'} = merge($species_defs, 'css', $dir, 'solr');

  PREV::merge_all(@_);
}

1;
