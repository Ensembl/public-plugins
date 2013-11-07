package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;

use previous qw(init);

sub init {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  my $type         = $self->hub->type;
  
  $self->PREV::init(@_);
  $self->add_sheet('all', sprintf '/%s/%s.css', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->SOLR_CSS_NAME) if $type and $type eq 'Search'; 
}

1;

