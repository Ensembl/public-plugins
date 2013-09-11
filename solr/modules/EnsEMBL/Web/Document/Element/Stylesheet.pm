package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;
use warnings;

use EnsEMBL::Web::Tools::MethodMaker(copy => ['init','_init2']);

sub init {
  my ($self,@rest) = @_;
  $self->add_solr if $self->hub->type eq 'Search';
  $self->_init2(@rest);
}

sub add_solr {
  my ($self) = @_;

  my $sd = $self->species_defs;
  $self->add_sheet('all',sprintf("/%s/%s.css",$sd->ENSEMBL_JSCSS_TYPE,
                                 $sd->SOLR_CSS_NAME)); 
}

1;

