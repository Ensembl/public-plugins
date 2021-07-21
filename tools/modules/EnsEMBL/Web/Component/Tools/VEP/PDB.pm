=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP::PDB;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;

use base qw(EnsEMBL::Web::Component::Variation EnsEMBL::Web::Component::PDB);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $species = $hub->species;
  
  my $var_id  = $hub->param('var');
  my $var_pos = $hub->param('pos');
  my $var_cons  = $hub->param('cons');
  my $var_enst  = $hub->param('t');
  
  # Add REST API URLs as hidden param
  my $html = $self->get_rest_urls();

  $html .= qq{
  <input type="hidden" id="variant_use_param" value="1"/>
  <input type="hidden" id="variant_pos" value="$var_pos"/>
  <input type="hidden" id="variant_cons" value="$var_cons"/>
  <input type="hidden" id="variant_enst" value="$var_enst"/>
  };

  # Add IDs header
  $html .= $self->get_ids_header($var_id);

  # Add selection dropdowns
  $html .= $self->get_ensp_pdb_dropdowns();

  # Litmol viewer + right hand side menu
  $html .= $self->get_main_content($var_id);

  return $html;
}

1;
