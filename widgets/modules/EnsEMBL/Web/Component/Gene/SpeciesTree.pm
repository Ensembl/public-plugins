=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::SpeciesTree;

use strict;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Compara::Utils::CAFETreeHash;

use EnsEMBL::Web::Constants;
use JSON qw(to_json);

use base qw(EnsEMBL::Web::Component::Gene);

sub content {
  my $self        = shift;
  my $cdb         = shift || 'compara';
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $hub->param('g');  
  my $image_type  = $hub->session->get_data(type => 'image_type', code => $self->id) || {};

  return $self->SUPER::new_image({hub => $hub, component => $self->id, image_config => $hub->get_imageconfig($self->view_config->image_config)})->render if($image_type->{'static'} || $hub->param('static') || $hub->param('export') || !(grep $_->[0] eq 'SpeciesTree', @{$hub->components}));
  
#  return if $self->_export_image($image);

  my ($member, $tree, $node)            = $self->get_details($cdb);
  my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id);  #get corresponding species for current gene
  my $species_name                      = $hub->species_defs->get_config(ucfirst($species), 'SPECIES_SCIENTIFIC_NAME');    
  my $hash                              = Bio::EnsEMBL::Compara::Utils::CAFETreeHash->convert($tree);
  my $str                               = to_json($hash);    

  my $html = "<div id='cafe_tree' class='js_tree ajax js_panel image_container ui-resizable'></div>
            <script>
            (function () {
              var tree_vis = tnt.tree();
              var theme = Ensembl.CafeTree.tnt_theme_tree_cafe_tree()
                             .json_data($str)
                             .highlight(\"$species_name\");
              theme(tree_vis, document.getElementById('cafe_tree'));
            })();
            </script>";

  return $html;
}

1;
