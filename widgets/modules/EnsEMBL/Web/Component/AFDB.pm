=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::AFDB;

use strict;

use base qw(EnsEMBL::Web::Component::Shared);


sub get_rest_urls {
  my $self = shift;
  my $hub  = $self->hub;

  my $ensembl_rest_url = $hub->species_defs->ENSEMBL_REST_URL;
  my $afdb_url         = $hub->species_defs->AFDB_URL;

  return qq{
    <input class="panel_type" value="AFDB" type="hidden" />
    <input type="hidden" name="ensembl_rest_url" class="js_param" value="$ensembl_rest_url">
    <input type="hidden" name="afdb_url" class="js_param" value="$afdb_url">
  };
}

sub get_ids_header {
  my $self   = shift;
  my $var_id = shift;

  my $var_id_display = ($var_id) ? qq{<h2 class="float_left">Variant <span id="var_id">$var_id</span> <small><span id="var_cons"></span></small></h2>} : '';
  my $var_separator  = ($var_id) ? qq{<span class="left-margin right-margin">|</span>} : '';

  return qq{
  <div>
    $var_id_display
    <h2 class="float_left" id="mappings_top" style="display:none">
      $var_separator
      <span id="mapping_top_ensp"></span>
      <span class="left-margin right-margin">|</span>
      <span id="mapping_top_afdb"></span>
      <small><span id="mapping_top_afdb_protein_name"></span></small>
    </h2>
    <div style="clear:both"></div>
  </div>

  <div id="afdb_msg"></div>
  };
}

sub get_ensp_afdb_dropdowns {
  my $self   = shift;
  my $display_ensp_sel = shift;

  my $ensp_sel  = ($display_ensp_sel) ? qq{<label id="ensp_list_label">Select Ensembl protein:</label><select id="ensp_list"></select>} : '';
  my $afdb_label = ($display_ensp_sel) ? 'AFDB model' : 'Select AFDB model';

  return qq{
  <div id="ensp_afdb" class="navbar" style="display:none">
    <div style="float:left">
      <form>
        $ensp_sel
        <label id="afdb_list_label" class="left-margin" style="display:none">$afdb_label:</label>
        <select id="afdb_list" style="display:none"></select>
      </form>
    </div>
    <div id="right_form" style="float:left;margin-left:15px"></div>
    <div style="clear:both"></div>
  </div>
  };
}


sub get_main_content {
  my $self = shift;
  my $focus_var_id = shift;

  my $viewer_html = $self->get_viewer_canvas();
  my $menu_html   = $self->get_menu_selection($focus_var_id);

  return qq{
  <div>
    $viewer_html
    $menu_html
    <div style="clear:both"></div>
  </div>
  }
}

sub get_viewer_canvas {
  my $self = shift;

  return qq{
    <div style="float:left;position:relative;height:450px;width:600px">
      <div class="view_spinner" style="display:none"></div>
      <div id="molstar_canvas">
        <!-- Canvas for AFDB Molstar-->
      </div>
    </div>
  }
}

sub get_menu_selection {
  my $self = shift;
  my $focus_var_id = shift;

  my $help_buttons  = $self->get_help_buttons();
  my $ensp_afdb_menu = $self->get_menu_ensp_afdb_mapping();
  my $exons_menu    = $self->get_menu_exons();
  my $proteins_menu = $self->get_menu_proteins();
  my $variants_menu = $self->get_menu_variants($focus_var_id);

  return qq{
    <div id="molstar_buttons" style="float:left;margin-left:20px;display:none">
      $help_buttons
      $ensp_afdb_menu
      $exons_menu
      $proteins_menu
      $variants_menu
    </div>
  };
}

sub get_help_buttons {
  my $self = shift;

  return qq {
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
  };

}

sub get_menu_ensp_afdb_mapping {
  my $self = shift;

  return qq{
      <table class="ss afdb_markup">
        <thead>
          <tr><th class="afdb_category"><span id="mapping_ensp"></span> - <span id="mapping_afdb"></span> mapping</th></tr>
        </thead>
        <tbody>

          <tr>
            <td id="mapping_block">
              <div>
                <div>
                  <h3 class="float_left">Ensembl-AFDB mapping</h3>
                  <div class="float_right view_toggle view_toggle_btn open" rel="mapping_details"></div>
                  <div class="float_right afdb_feature_group view_enabled" title="Click to highlight / hide ENSP-AFDB mapping coverage on the 3D viewer" id="mapping_group"></div>
                  <div style="clear:both"></div>
                </div>
                <div class="mapping_details">
                  <div id="mapping_details_div" class="afdb_features_container toggleable" style="padding-top:5px">
                    <table class="afdb_features">
                      <thead>
                        <tr><th>Label</th><th class="location _ht" title="Position in the selected AFDB model"><span>AFDB</span></th><th class="location _ht" title="Position in the selected Ensembl protein"><span>ENSP</span></th><th></th></tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td style="border-color:#DDD">Coverage</td><td id="mapping_afdb_pos"></td><td id="mapping_ensp_pos"></td>
                          <td>
                            <span class="afdb_feature_entry view_enabled float_left" id="mapping_cb" data-value="" data-group="mapping_group" data-name="Mapping" data-colour="#DDD"></span>
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
  };
}

sub get_menu_exons {
  my $self = shift;

  return qq{
    <table class="ss afdb_markup">
      <thead>
         <tr><th class="afdb_category">Exons</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="exon_block"></td>
          </tr>
        </tbody>
      </table>
  };
}

sub get_menu_proteins {
  my $self = shift;
  return qq{
      <table class="ss afdb_markup">
        <thead>
          <tr><th class="afdb_category">Protein information</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="protein_block"></td>
          </tr>
        </tbody>
      </table>
  };
}

sub get_menu_variants {
  my $self = shift;
  my $focus_var_id = shift;


  if ($focus_var_id) {
    return qq{
      <table class="ss afdb_markup">
        <thead>
          <tr><th class="afdb_category">Variants</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="variant_block">
              <div>
                <div>
                  <h3 class="float_left">Variant $focus_var_id</h3>
                  <div class="float_right view_toggle view_toggle_btn open" rel="var_details"></div>
                  <div class="float_right afdb_feature_group view_enabled" title="Click to highlight / hide variant on the 3D viewer" id="variant_group"></div>
                  <div style="clear:both"></div>
                </div>
                <div class="var_details">
                  <div id="var_details_div" class="afdb_features_container toggleable" style="padding-top:5px">
                    <table class="afdb_features">
                      <thead>
                        <tr><th>ID</th><th class="location _ht" title="Position in the selected PDB model"><span>PDB</span></th><th class="location _ht" title="Position in the selected Ensembl protein"><span>ENSP</span></th><th></th></tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td style="border-color:red">$focus_var_id</td><td id="var_pos_afdb"></td><td id="var_pos_ensp"></td>
                          <td>
                            <span class="afdb_feature_entry afdb_var_entry view_enabled float_left" id="focus_variant_cb" data-value="" data-group="variant_group" data-name="$focus_var_id" data-colour="red" data-highlight="1"></span>
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
    };
  }
  else {
    return qq{
      <table class="ss afdb_markup">
        <thead>
          <tr><th class="afdb_category">Variants</th></tr>
        </thead>
        <tbody>
          <tr>
            <td id="variant_block"></td>
          </tr>
        </tbody>
      </table>
    };
  }
}
1;
