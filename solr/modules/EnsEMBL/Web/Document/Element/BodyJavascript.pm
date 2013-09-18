package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

sub add_sources_solr { $_[0]->add_sources('solr', 'SOLR_JS_NAME') if $_[0]->hub->type eq 'Search'; }

1;
