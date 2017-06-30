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

package EnsEMBL::Web::Component::Gene::PlantReactome;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;

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
  my $xref_id     = 'R-OSA-8933811';
  my $species     = $hub->species;
  my $html;
  my $xrefs;

  eval { $xrefs = $object->Obj->get_all_DBEntries('Gramene_Plant_Reactome'); };
  warn ("SIMILARITY_MATCHES Error on retrieving gene xrefs $@") if ($@);
  

  my $xref_id = $xrefs->[0]->{'primary_id'};

  if (!$hub->plant_reactome_status) {
    $html = $self->_info_panel("error", "Plant reactome site down!", "<p>The widget cannot be displayed as the plant reactome site is down. Please check again later.</p>");
  } else {
    #this script tag has been kept here as it was easier to call the perl param within the script tag (the js file wasn't getting the param)
    $html = sprintf '
              <input class="panel_type" value="PlantReactome" type="hidden" />
              <input type="hidden" class="js_param" name="xrefId" value="%s" />
              <input type="hidden" class="js_param" name="geneId" value="%s" />
              <input type="hidden" class="js_param" name="species" value="%s" />', 
              $xref_id,
              $hub->param('g'),
              $species
              ;
  }

  return $html;
}

1;
