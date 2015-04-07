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

package EnsEMBL::Web::Component::Gene::ExpressionAtlas;

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
  my $stable_id   = $hub->param('g'); 
  my $species     = $hub->species;
  
  $species        =~ s/_/ /gi;
  my $html = qq{
    <script type="text/javascript">
      var instance = new Biojs.AtlasHeatmap ({
            getBaseUrl: "http://www.ebi.ac.uk/gxa",
            params:'geneQuery=$stable_id&species=$species',
            isMultiExperiment: true,
            target : "expressionAtlas"
      });
    </script>  
    <div id="expressionAtlas"></div>    
  };

  return $html;
}

1;
