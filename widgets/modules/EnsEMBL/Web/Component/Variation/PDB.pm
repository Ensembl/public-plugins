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

package EnsEMBL::Web::Component::Variation::PDB;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;

use base qw(EnsEMBL::Web::Component::Variation);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self      = shift;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $variation = $object->Obj;
  my $species   = $hub->species;
  
  my $var_id    = $hub->param('v');
  my $var_label = $var_id."_cb";
  my $vf        = $hub->param('vf');

  my $variation_features = $variation->get_all_VariationFeatures;
  my $msc;

  foreach my $vf_object (@$variation_features) {
    if ($vf_object->dbID == $vf) {
      my $overlap_consequences = [$vf_object->most_severe_OverlapConsequence] || [];
      # Sort by rank, with only one copy per consequence type
      my @consequences = sort {$a->rank <=> $b->rank} (values %{{map {$_->label => $_} @{$overlap_consequences}}});
      $msc = $consequences[0];
      last;
    }
  }

  return "No overlapping protein" unless ($msc && $msc->rank < 17);

  my $rest_url = $hub->species_defs->ENSEMBL_REST_URL;

  my $html = qq{
  <input class="panel_type" value="PDB" type="hidden" />
  <input type="hidden" name="ensembl_rest_url" class="js_param" value="$rest_url">
 
  <div> 
    <h2 class="float_left">Variant <span id="var_id">$var_id</span> <small><span id="var_cons"></span></small></h2>
    <a id="mapping_top_ensp" class="float_left viewer_btn viewer_btn_link left-margin _ht" title="Selected Ensembl protein"></a>
    <a id="mapping_top_pdb" class="float_left viewer_btn viewer_btn_link left-margin _ht" target=_blank" style="background-color:#669966" title="Selected PDB model"></a>
    <div style="clear:both"></div>
  </div>

  <div id="pdb_msg"></div>  

  <div id="ensp_pdb" class="navbar" style="display:none">
    <div style="float:left">
      <form>
        <label id="ensp_list_label">Select Ensembl protein:</label>
        <select id="ensp_list"></select>
        <label id="pdb_list_label" class="left-margin" style="display:none">PDBe model:</label>
        <select id="pdb_list" style="display:none"></select>
      </form>
    </div>
    <div id="right_form" style="float:left;margin-left:15px"></div>
    <div style="clear:both"></div>
  </div>
  
  <div id="variant_pos_info" style="display:none">
    <span id="var_ensp_id"></span><span class="var_pos"></span>
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
                  <h3 class="float_left">Ensembl-PDBe mapping</h3>
                  <div class="float_right view_toggle view_toggle_btn open" rel="mapping_details"></div>
                  <div class="float_right pdb_feature_group view_enabled" title="Click to highlight / hide ENSP-PDB mapping coverage on the 3D viewer" id="mapping_group"></div>
                  <div style="clear:both"></div>
                </div>
                <div class="mapping_details">
                  <div id="mapping_details_div" class="pdb_features_container toggleable" style="padding-top:5px">
                    <table class="pdb_features">
                      <thead>
                        <tr><th>Label</th><th class="location _ht" title="Position in the selected PDB model"><span>PDB</span></th><th class="location _ht" title="Position in the selected En     sembl protein"><span>ENSP</span></th><th></th></tr>
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
            <td id="variant_block">
              <div>
                <div>
                  <h3 class="float_left">Variant $var_id</h3>
                  <div class="float_right view_toggle view_toggle_btn open" rel="var_details"></div>
                  <div class="float_right pdb_feature_group view_enabled" title="Click to highlight / hide variant on the 3D viewer" id="variant_group"></div>
                  <div style="clear:both"></div>
                </div>
                <div class="var_details">
                  <div id="var_details_div" class="pdb_features_container toggleable" style="padding-top:5px">
                    <table class="pdb_features">
                      <thead>
                        <tr><th>ID</th><th class="location _ht" title="Position in the selected PDB model"><span>PDB</span></th><th class="location _ht" title="Position in the selected En         sembl protein"><span>ENSP</span></th><th></th></tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td style="border-color:red">$var_id</td><td id="var_pos_pdb"></td><td id="var_pos_ensp"></td>
                          <td>
                            <span class="pdb_feature_entry pdb_var_entry view_enabled float_left" id="$var_label" data-value="" data-group="variant_group" data-name="$var_id" data-colour="red" data-highlight="1"></span>
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
    </div>
    
    <div style="clear:both"></div>
    
  </div>
};

    

  return $html;
}

1;
