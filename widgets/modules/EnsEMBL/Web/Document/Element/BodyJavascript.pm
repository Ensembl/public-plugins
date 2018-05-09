=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

## DESCRIPTION: Adding new js file from external link for gene expression atlas

package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;
use warnings;
  
use previous qw(content);

sub content {
  my $self = shift;

  my $main_js = $self->PREV::content(@_);
  
  if ($self->hub->action && $self->hub->action eq 'ExpressionAtlas' && $self->hub->gxa_status) {
    # adding js only for gxa view and do not add them if their site is down
    # don't forget to remove their jquery lib as this will cause conflict with our one which is the latest one
    $main_js .=  qq{
      <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js-bundles/vendorCommons.bundle.js"></script>
      <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js-bundles/expressionAtlasHeatmapHighcharts.bundle.js"></script>
    };
  }
  
  if ($self->hub->action && $self->hub->action eq 'Pathway' && $self->hub->pathway_status) {
    #adding js for pathway
    my $js_file = $self->species_defs->REACTOME_JS_LIBRARY;
    if ($js_file) {
      $main_js .=  qq{<script type="text/javascript" language="javascript" src="$js_file"></script>};
    }
  }
  
  return $main_js;

}

1;
