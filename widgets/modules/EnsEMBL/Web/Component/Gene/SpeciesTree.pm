=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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
use EnsEMBL::Web::Document::Image::WidgetImage;

use JSON qw(to_json);

use previous qw(content);

sub get_json {
  my $self   = shift;
  my $cdb    = shift;

  my $object = shift || $self->object || $self->hub->core_object('gene');
  my $member = $object->get_compara_Member({'stable_id' => $object->stable_id, 'cdb' => $cdb});

  return (undef, '<strong>Gene is not in the compara database</strong>') unless $member;

  my $tree_json = $object->get_SpeciesTreeJSON($cdb);

  return (undef, '<strong>Gene is not in a compara tree</strong>') unless $tree_json;

  return ($member, $tree_json);
}


sub content {
  my $self        = shift;
  my $cdb         = shift || 'compara';
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $hub->param('g');  
  my $image_type  = $hub->session->get_record_data({type => 'image_type', code => $self->id});
  my $species_map = to_json($hub->species_defs->prodnames_to_urls_lookup()); #creating a json string to pass to widget to map the production_name to url_name for the species images
  my $html        = '<input type="hidden" value="Widget" class="panel_type">';
   
  return $self->PREV::content(@_) if($image_type->{'static'} || $hub->param('static') || $hub->param('export') || !(grep $_->[0] eq 'SpeciesTree', @{$hub->components}));
  
  my ($member, $str)                    = $self->get_json($cdb);
  $str =~ s/'/&#39;/g; #encode comma in the string (some species name has comma)
 
  my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id);  #get corresponding species for current gene
  my $species_name                      = $hub->species_defs->get_config(ucfirst($species), 'SPECIES_SCIENTIFIC_NAME');    

  $html .= qq{
    <input type="hidden" class="js_param" name="treeType" value="CafeTree" />
    <input type="hidden" class="js_param" name="json" value='$str' />
    <input type="hidden" class="js_param" name="species_name_map" value='$species_map' />
    <input type="hidden" class="js_param" name="species_name" value="$species_name" />
  };  
  
  my $image = EnsEMBL::Web::Document::Image::WidgetImage->new($hub, $self);
  $image->{'export_params'} = [['gene_name', $member->display_label],['align', 'tree']];
  $image->{'data_export'}   = 'SpeciesTree';

  return $image->render($html);
}

1;
