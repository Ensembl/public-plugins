package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

use previous qw(init);

sub init {
  my $self = shift;
  my $type = $self->hub->type;
  
  $self->PREV::init;
  $self->add_sources('solr', 'SOLR_JS_NAME') if $type and $type eq 'Search';
}

1;
