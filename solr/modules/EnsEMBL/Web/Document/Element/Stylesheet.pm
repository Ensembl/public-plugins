package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;

sub add_sheets_solr {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  my $type = $self->hub->type;
  
  $self->add_sheet('all', sprintf '/%s/%s.css', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->SOLR_CSS_NAME) if $type and $type eq 'Search'; 
}

1;

