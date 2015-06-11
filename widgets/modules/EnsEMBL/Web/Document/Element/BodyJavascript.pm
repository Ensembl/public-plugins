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

  return $main_js unless $self->hub->action && $self->hub->action eq 'ExpressionAtlas'; #adding js only for gxa view

  $main_js .=  qq{
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/react/react-0.11.1.min.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/jquery-1.9.1.min.js"></script>

    <!--[if lte IE 9]>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/jquery.xdomainrequest-1.0.3.min.js"></script>
    <![endif]-->

    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/jquery-migrate-1.2.0.min.js"></script>

    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>

    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/jsx/factorTooltip.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/factorTooltipModule.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/jsx/contrastTooltip.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/contrastTooltipModule.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/helpTooltipsModule.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/genePropertiesTooltipModule.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/highlight.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/anatomogramModule.js"></script>

    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/highcharts-4.1.5/js/highcharts.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/highcharts-4.1.5/js/highcharts-more.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/highcharts-4.1.5/js/modules/exporting.js"></script>

    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/jsx/cellBaselineVariance.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/jquery.svg.package-1.4.5/jquery.svg.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/EventEmitter-4.2.7.js"></script>

    <script language="JavaScript" type="text/javascript" src="http://www.ebi.ac.uk/web_guidelines/js/libs/modernizr.minified.2.1.6.js"></script>

    <script language="JavaScript" type="text/javascript" src="http://www.ebi.ac.uk/Tools/biojs/biojs/Biojs.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/biojs/AtlasHeatmapReact.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/jsx/heatmap.js"></script>
    <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/jsx/heatmapContainer.js"></script>
  }; 

  return $main_js;

}

1;
