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

package EnsEMBL::Web::Component::Transcript::PDB;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self        = shift;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $html;
  if ($object->Obj->isa('Bio::EnsEMBL::Transcript')) {
    #my $stable_id      = $hub->param('g'); 
    my $species     = $hub->species;
    my $translation = $object->translation_object;
    return unless $translation;
  
    my $translation_id = $translation->stable_id;
    my $ensembl_rest_url = $hub->species_defs->ENSEMBL_REST_URL;
    my $pdbe_rest_url    = $hub->species_defs->PDBE_REST_URL;

    $html .= qq{
  <input class="panel_type" value="PDB" type="hidden" />
  <input type="hidden" name="ensembl_rest_url" class="js_param" value="$ensembl_rest_url">
  <input type="hidden" name="pdbe_rest_url" class="js_param" value="$pdbe_rest_url">
 
  <div> 
    <h2 class="float_left">3D representation of the Ensembl protein</h2>
    <a id="mapping_top_ensp" class="float_left viewer_btn viewer_btn_link left-margin _ht" title="Selected Ensembl protein"><span id="ensp_id">$translation_id</span></a>
    <a id="mapping_top_pdb" class="float_left viewer_btn viewer_btn_link left-margin _ht" target=_blank" style="background-color:#669966" title="Selected PDB model"></a>
    <div style="clear:both"></div>
  </div>
   
  <div id="pdb_msg"></div>

  <div id="ensp_pdb" class="navbar" style="display:none">
    <div style="float:left">
      <form>
        <label id="pdb_list_label" class="left-margin" style="display:none">Select PDBe model:</label>
        <select id="pdb_list" style="display:none;margin-left:5px"></select>
      </form>
    </div>
    <div id="right_form" style="float:left;margin-left:15px"></div>
    <div style="clear:both"></div>
  </div>

  <div style="margin-bottom:300px">

    <div style="float:left;position:relative;height:600px;width:800px">
      <div class="view_spinner" style="display:none"></div>
      <div id="litemol_canvas" style="height:600px;width:800px">
        <!-- Canvas for PDB LiteMol-->
      </div>
    </div>

    <div id="litemol_buttons" style="float:left;margin-left:20px;display:none">

      <div>
        <div rel="viewer_help" class="float_left view_toggle viewer_btn viewer_helper_btn closed" title="Click to toggle the 3D Viewer Help">
          <span>3D Viewer Help</span>
        </div>
        <div class="float_left viewer_btn viewer_reset_btn left-margin">
          <span>Reset viewer</span>
        </div>
        <div style="clear:both"></div>
      </div>

      <div id="viewer_help_div" style="display:none">
          <table>
            <thead>
              <tr>
                <th>Action</th><th>Mouse</th><th>Touchscreen</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Rotate</td><td>Left click + drag</td><td>One finger touch</td></tr>
              <tr><td>Zoom</td><td>Right click + drag</td><td>Pinch</td></tr>
              <tr><td>Move</td><td>Middle click + drag</td><td>Two finger touch</td></tr>
              <tr><td>Slab</td><td>Mouse wheel</td><td>Three finger touch</td></tr>
            </tbody>
        </table>
      </div>

      <table class="ss pdb_markup">
        <thead>
          <tr><th class="pdb_category"><span id="mapping_ensp"></span> - <span id="mapping_pdb"></span> mapping</th></tr>
        </thead>
        <tbody>

          <tr>
            <td id="mapping_block">
              <div>
                <div>
                  <h3 class="float_left" style="margin-bottom:0px">Ensembl-PDBe mapping</h3>
                  <div class="float_right view_toggle view_toggle_btn open" rel="mapping_details"></div>
                  <div class="float_right pdb_feature_group view_enabled" title="Click to highlight / hide ENSP-PDB mapping coverage on the 3D viewer" id="mapping_group"></div>
                  <div style="clear:both"></div>
                </div>
                <div class="mapping_details">
                  <div id="mapping_details_div" class="pdb_features_container toggleable" style="padding-top:5px">
                    <table class="pdb_features">
                      <thead>
                        <tr><th>Label</th><th class="location _ht" title="Position in the selected PDB model"><span>PDB</span></th><th class="location _ht" title="Position in the selected     En     sembl protein"><span>ENSP</span></th><th></th></tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td style="border-color:#DDD">Coverage</td><td id="mapping_pdb_pos"></td><td id="mapping_ensp_pos"></td>
                          <td>
                            <span class="pdb_feature_entry view_enabled float_left" id="mapping_cb" data-value="" data-group="mapping_group" data-name="Mapping" data-colour="#DDD"></span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <table class="ss pdb_markup">
        <thead>
          <tr><th class="pdb_category">Exons</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="exon_block"></td>
          </tr>
        </tbody>
      </table>

      <table class="ss pdb_markup">
        <thead>
          <tr><th class="pdb_category">Protein information</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="protein_block"></td>
          </tr>
        </tbody>
      </table>

      <table class="ss pdb_markup">
        <thead>
          <tr><th class="pdb_category">Variants</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="variant_block"></td>
          </tr>
        </tbody>
      </table>
    </div> 
   
    <div style="clear:both"></div>

  </div>
};

  }    

  return $html;
}

1;
