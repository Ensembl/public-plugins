=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

  return $main_js unless $self->hub->action eq 'ExpressionAtlas'; #adding js only for gxa view

  $main_js .=  qq{
  <script type="text/javascript"  src="http://cdnjs.cloudflare.com/ajax/libs/react/0.11.1/react.min.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/jquery-ui-1.10.3.fix-8740.0520a49/dist/jquery-ui.min.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/jquery-migrate-1.2.0.min.js"></script>
  
  <script type="text/javascript"  src="http://code.highcharts.com/highcharts.js"></script>
  <script type="text/javascript"  src="http://code.highcharts.com/highcharts-more.js"></script>
  <script type="text/javascript"  src="http://code.highcharts.com/modules/exporting.js"></script>

  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/jsx/factorTooltip.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/factorTooltipModule.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/jsx/contrastTooltip.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/contrastTooltipModule.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/helpTooltipsModule.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/genePropertiesTooltipModule.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/highlight.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/anatomogramModule.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/jquery.svg.package-1.4.5/jquery.svg.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/js/EventEmitter-4.2.7.js"></script>

  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/jsx/cellBaselineVariance.js"></script>

  <script type="text/javascript"  src="http://www.ebi.ac.uk/web_guidelines/js/libs/modernizr.minified.2.1.6.js"></script>

  <script type="text/javascript"  src="http://www.ebi.ac.uk/Tools/biojs/biojs/Biojs.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/biojs/AtlasHeatmapReact.js"></script>

  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/jsx/heatmap.js"></script>
  <script type="text/javascript"  src="http://www.ebi.ac.uk/gxa/resources/jsx/heatmapContainer.js"></script>
  }; 

  return $main_js;

}

1;
