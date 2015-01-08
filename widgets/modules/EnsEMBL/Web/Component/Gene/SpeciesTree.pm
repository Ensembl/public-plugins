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

use JSON qw(to_json);

use previous qw(content);


sub content {
  my $self        = shift;
  my $cdb         = shift || 'compara';
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $hub->param('g');  
  my $image_type  = $hub->session->get_data(type => 'image_type', code => $self->id) || {};
  my $html        = '<input type="hidden" value="Widget" class="panel_type">';
   
  return $self->PREV::content(@_) if($image_type->{'static'} || $hub->param('static') || $hub->param('export') || !(grep $_->[0] eq 'SpeciesTree', @{$hub->components}));
  
#  return if $self->_export_image($image);

  my ($member, $tree, $node)            = $self->get_details($cdb);
  my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id);  #get corresponding species for current gene
  my $species_name                      = $hub->species_defs->get_config(ucfirst($species), 'SPECIES_SCIENTIFIC_NAME');    
  my $hash                              = Bio::EnsEMBL::Compara::Utils::CAFETreeHash->convert($tree);
  my $str                               = to_json($hash);    

  $html .= "<div id='cafe_tree' class='js_tree ajax js_panel image_container ui-resizable'></div>
            <script>
              Ensembl.CafeTree.displayTree($str,\"$species_name\");
            </script>";

  return $html;
}

1;
