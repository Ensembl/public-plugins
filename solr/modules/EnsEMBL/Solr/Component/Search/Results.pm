# $Id$

package EnsEMBL::Solr::Component::Search::Results;

use strict;

use base qw(EnsEMBL::Web::Component::Search);

use JSON;
use HTML::Entities;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub escape {
  local $_ = shift;
  s/&/&amp;/g;
  s/</&lt;/g;
  s/>/&gt;/g;
  return $_;
}

sub common {
  my ($self,$scientific) = @_;

  return $self->hub->species_defs->get_config($scientific,'SPECIES_COMMON_NAME');
}

sub content {
  my $self = shift;
  my $hub = $self->hub;

  # Species
  my $species = $self->common($hub->species);

  # Columns
  # Encode

  # Misc further config
  my $base = $hub->species_defs->ENSEMBL_BASE_URL;
  $base = encode_json({ url => $base});
  
  # Emit them
  return qq(
    <div>
      <div id='solr_context'>
        <span id='facet_species'>$species</span>
      </div>
      <div id='solr_config'>
        <span class='base'>$base</span>
      </div>
      <div id='solr_templates'>
        <div id='table_main'>
          <table style="width: 100%" class="table_body">
          </table>
        </div>
      </div>
      <div id='solr_content'></div>
    </div>
);

  return "<div id='solr_content'></div>";
}

1;
