=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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
  my $object      = $self->object;
  my $species     = $hub->species;
  my $common_name = $hub->get_species_info($species)->{common};
  my $reactomeUrl = $hub->species_defs->REACTOME_URL;
  my $gene        = $hub->param('g');
  # my $contentServiceSpecies = $hub->species_defs->REACTOME_CONTENT_SERVICE_SPECIES
  # my $contentServicePathways = $hub->species_defs->REACTOME_CONTENT_SERVICE_PATHWAYS
  my $html;
  my $xrefs;

  if ($SiteDefs::IS_INVERTEBRATE->{$SiteDefs::SUBDOMAIN_DIR}) {
    eval { $xrefs = $object->Obj->get_all_DBEntries('Gramene_Plant_Reactome'); };
  }
  else {
    eval { $xrefs = $object->Obj->get_all_DBLinks('Reactome%'); };
  }
  warn ("SIMILARITY_MATCHES Error on retrieving gene xrefs $@") if ($@);
  

  if ($#$xrefs < 0) {
    return $self->_info_panel("info", "No data available!", sprintf('No data available to retrieve for this gene %s', $hub->param('g')));
  }

  if (!$hub->pathway_status) {
    $html = $self->_info_panel("error", "Plant reactome site down!", "<p>The widget cannot be displayed as the plant reactome site is down. Please check again later.</p>");
  } else {

    my %xref_map = map { $_->{primary_id} => $_->{description} } @$xrefs;

    $html = $self->_info_panel("info", "Pathway", "<p> <b>$gene</b> has been highlighted in the pathway. Click on the list of pathway IDs below to display that pathway </p>");
    $html .= sprintf '
              <input class="panel_type" value="Pathway" type="hidden" />
              <input type="hidden" class="js_param" name="xrefs" value="%s" />
              <input type="hidden" class="js_param" name="geneId" value="%s" />
              <input type="hidden" class="js_param" name="species_common_name" value="%s" />
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
              $common_name;
  }

  return $html;
}

1;
