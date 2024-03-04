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

use strict;

package EnsEMBL::Widgets::SiteDefs;

sub update_conf { 

  $SiteDefs::GXA_REST_URL = 'https://www.ebi.ac.uk/gxa/json/expressionData?geneId=';#'http://wwwdev.ebi.ac.uk/gxa/json/expressionData?geneId=';
  $SiteDefs::GXA_EBI_URL  = 'https://www.ebi.ac.uk/gxa/resources';#'http://wwwdev.ebi.ac.uk/gxa/resources'; #dev  environment for GXA for pre testing their release

  $SiteDefs::REACTOME_URL = 'https://reactome.org';
  $SiteDefs::REACTOME_JS_LIBRARY = 'https://www.reactome.org/DiagramJs/diagram/diagram.nocache.js';

  $SiteDefs::Pathway = 1;

  $SiteDefs::PDBE_REST_URL = 'https://www.ebi.ac.uk/pdbe';
  $SiteDefs::PDBE_EBI_URL  = 'https://www.ebi.ac.uk/pdbe/pdb-component-library';
}

1;
