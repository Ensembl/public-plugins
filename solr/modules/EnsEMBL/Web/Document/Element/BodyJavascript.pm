package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

sub add_sources_solr {
  my $type = $_[0]->hub->type;
  $_[0]->add_sources('solr', 'SOLR_JS_NAME') if $type and $type eq 'Search'; 
}

1;
