=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::Gene::Pathway;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;
use JSON;
use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self        = shift;

  my $hub         = $self->hub;
  my $species     = $hub->species;
  my $common_name = $hub->get_species_info($species)->{common};
  my $gene        = $hub->param('g');
  my $html;
  my $reactome_url;
  my $xrefs = $self->object->getReactomeXrefs();

  warn ("SIMILARITY_MATCHES Error on retrieving gene xrefs $@") if ($@);

  if ($#$xrefs < 0) {
    return $self->_info_panel("info", "No data available!", sprintf('No data available to retrieve for the gene %s', $hub->param('g')));
  }

  if (!$hub->pathway_status) {
    $html = $self->_info_panel("error", "Reactome site down!", "<p>The display cannot be shown since the Reactome site from where we retrieve the data is unavailable, please try again later. If the issue persists please <a class='modal_link' href='/Help/Contact'>contact us</a>.</p>");
  } else {

    my %xref_map = map { $_->{primary_id} => ($_->{description} || $_->{display_id}) } @$xrefs;

    $html = $self->_info_panel("info", "Pathway", "<p> <b>$gene</b> has been highlighted in the pathway where applicable. Click on the list of pathway IDs below to display that pathway </p>");
    $html .= sprintf '
              <input class="panel_type" value="Pathway" type="hidden" />
              <input type="hidden" class="js_param" name="xrefs" value="%s" />
              <input type="hidden" class="js_param" name="geneId" value="%s" />
              <input type="hidden" class="js_param" name="species_common_name" value="%s" />
              <input type="hidden" class="js_param" name="reactome_url" value="%s" />
              <div class="pathway">
                <div class="pathways_list">
                  <ul></ul>
                </div>
                <div class="widget">
                  <div class="title"></div>
                  <div id="pathway_widget"></div>
                </div>
              </div>',
              encode_entities($self->jsonify(\%xref_map)),
              $gene,
              $common_name,
              $hub->species_defs->REACTOME_URL;
  }

  return $html;
}

1;
