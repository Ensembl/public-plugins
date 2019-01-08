/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2017] EMBL-European Bioinformatics Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.PDB = Ensembl.Panel.Content.extend({
  init: function() {
    var panel = this;
    this.base.apply(this, arguments);

    // Load a specific plugin to highlight the different parts of the protein with different colour
    // and the focus variant with its corresponding amino acid(s) side chain(s)
    $.getScript('/pdbe/litemol-custom-theme.js');

    // Setup variables
    this.species = Ensembl.species;

    // Check if we can get the REST URL from the webiste
    this.rest_url_root         = this.params['ensembl_rest_url'];
    this.rest_vep_url          = this.rest_url_root+'/vep/'+this.species+'/id/';
    this.rest_pr_url           = this.rest_url_root+'/overlap/translation/';
    this.rest_lookup_url       = this.rest_url_root+'/lookup/id/';
    this.pdbe_url_root         = this.params['pdbe_rest_url'];
    this.rest_pdbe_url_root    = this.pdbe_url_root+'/api/';
    this.rest_pdbe_url         = this.rest_pdbe_url_root+'pdb/entry/molecules/';
    this.rest_pdbe_quality_url = this.rest_pdbe_url_root+'validation/summary_quality_scores/entry/';
    this.rest_pdbe_sifts_url   = this.rest_pdbe_url_root+'mappings/ensembl/';

    // Setup external links   
    this.protein_sources = { 
                             'Pfam'   : 'http://pfam.xfam.org/family/',
                             'PRINTS' : 'https://www.ebi.ac.uk/interpro/signature/',
                             'Gene3D' : 'http://gene3d.biochem.ucl.ac.uk/Gene3D/search?mode=protein&sterm='
                           };
    this.protein_features = {};

    this.hexa_to_rgb = { 
                         'red'        : {r:255, g:0,   b:0},
                         'blue'       : {r:0,   g:0,   b:250},
                         'green'      : {r:0,   g:128, b:0},
                         'orange'     : {r:255, g:165, b:0},
                         'white'      : {r:255, g:255, b:255},
                         'dark_grey'  : {r:100, g:100, b:100},
                         'darkred'    : {r:55,  g:0,   b:0},
                         '#DDD'       : {r:221, g:221, b:221}
                       };

    // Module variables
    this.liteMolScope;
    
    this.var_id;
    this.ensp_id;

    this.ensp_list = [];
    this.ensp_pdb_list = {};
    this.ensp_pdb_quality_list = {};
    this.ensp_pdb_author_pos = {};
    this.ensp_var_pos  = {};
    this.ensp_var_cons = {};
    this.ensp_length   = {};

    this.max_feature_per_gp   = 150;
    this.mapping_min_percent  = 50
    this.mapping_min_length   = 10;
    this.max_pdb_entries      = 10;
    this.spinner_waiting_time = 20;

    this.pdb_id;
    this.pdb_start;
    this.pdb_end;
    this.pdb_hit_start;
    this.pdb_author_start;
    this.pdb_author_end;
    this.pdb_struct_asym;
    this.pdb_chain_struc_entity = new Object();

    this.details_header = '<th>ID</th>'+
                          '<th class="location _ht" title="Position in the selected PDB model"><span>PDB</span></th>'+
                          '<th class="location _ht" title="Position in the selected Ensembl protein"><span>ENSP</span></th>';

    panel.addSpinner();


    $(document).ready(function () {
      console.log('>>>>> STEP 00: init PDB variables and run document ready');
      
      panel.addSpinner(); 

      // Transcript portal
      if ($("#ensp_id").length) {
        panel.ensp_id = $("#ensp_id").html();
        panel.ensp_list.push(panel.ensp_id);
        // Get ENSP length
        $.when(panel.get_ens_protein_length()).then(function() {
          // Get the corresponding PDB list 
          panel.get_all_pdb_list();
        });
      }
      // Variation portal
      else {
        // Get variant ID, the list of ENSP overlapping the variant with the variant coordinates and the variant consequence
        $.when(panel.get_var_ensp_data()).then(function() {
          if (panel.ensp_list.length) {
            // Get the length of all the ENSP
            $.when(panel.get_ens_protein_length()).then(function() {
              // Get the PDB list of each ENSP
              panel.get_all_pdb_list();
            });
          }
        });

        // Setup variant position (and display it) regarding the selected ENSP
        $('#ensp_list').change(function () {
          panel.ensp_id = $(this).val();
          if (panel.ensp_id) {
            $('.var_pos').html(panel.ensp_var_pos[panel.ensp_id]);
            $('#var_cons').html('('+panel.ensp_var_cons[panel.ensp_id]+')');
            $('#var_ensp_id').html(panel.ensp_id);
            panel.display_pdb_list(panel.ensp_id);
          }
          // Reset the variant position display on the page
          else {
            $('.var_pos').html('');
            $('#var_cons').html('');
            $('#var_ensp_id').html('');
            $('#variant_pos_info').hide();
          }
        });
      }  


      // Select a PDBe model
      $('#pdb_list').change(function () {
        var pdb_id = $(this).val();
        panel.selectPDBEntry(pdb_id);
      });

      // Select a group of features to highlight
      $(document).on('click', '.pdb_feature_group', function() {
        $(this).toggleClass('view_enabled view_disabled');
        panel.selectedFeatureGroupsToHighlight($(this).attr('id'));
      });

      // Select a subgroup of features to highlight
      $(document).on('click', '.pdb_feature_subgroup', function() {
        $(this).toggleClass('view_enabled view_disabled');
        panel.selectedFeatureSubGroupsToHighlight($(this).attr('id'));
      });
      
      // Select a feature (or a list of features) to highlight
      $(document).on('click', '.pdb_feature_entry', function() {
        $(this).toggleClass('view_enabled view_disabled');
        panel.selectedFeaturesToHighlight();
      });
      
      // Expans/collapse a list of features
      $(document).on('click', '.view_toggle', function() {
        var div_id = '#'+$(this).attr('rel')+'_div';
        if ($(this).hasClass('closed')) {
          $(div_id).show();
        }
        else {
          $(div_id).hide();
        }
        $(this).toggleClass('open closed');
      });

      // Reset the viewer
      $(document).on('click', '.viewer_reset_btn', function() {
        $('.view_spinner').show();
        // Needed to show the spinner
        setTimeout(function(){ 
          // Reset to default view (like the "Reset" button in the viewer) - Code from LiteMol
          panel.liteMolScope.LiteMolComponent.Bootstrap.Command.Visual.ResetScene.dispatch(panel.liteMolScope.LiteMolComponent.plugin.context, void 0);
          // Reset right hand menu
          panel.setDefaultHighlighting();
          // Reset to default highlighting
          panel.selectedFeatureGroupsToHighlight();
        }, panel.spinner_waiting_time);
      });
    });
  },

  // Reset default highlighting:
  // everything is disabled except the mapping ENSP-PDB and the focus variant (if on a variant page)
  setDefaultHighlighting: function() {
    var panel = this;
   
    // Disable everything 
    $('.view_enabled').switchClass('view_enabled','view_disabled');

    // Enable default options
    $('#mapping_group').switchClass('view_disabled','view_enabled');
    if (panel.var_id) {
      $('#variant_group').switchClass('view_disabled','view_enabled');
    }
  }, 


  // Select the PDB entry, setup display and launch 3D model
  selectPDBEntry: function(pdb_id) {
    var panel = this;
    console.log(">>>>> STEP 10: Select PDB entry (selectPDBEntry) - start");

    panel.setDefaultHighlighting();

    // Extracting PDB data and store it in panel
    if (pdb_id) {
      var sel = $('#pdb_list').find('option:selected');

      // Store information about selected PDB model in module variables
      panel.pdb_id           = pdb_id;
      panel.pdb_start        = Number(sel.attr('data-start'));
      panel.pdb_end          = Number(sel.attr('data-end'));
      panel.pdb_chains       = sel.attr('data-chain').split(',');
      panel.pdb_hit_start    = Number(sel.attr('data-hit-start'));
      panel.pdb_author_start = (sel.attr('data-author-start')) ? Number(sel.attr('data-author-start')) : panel.pdb_hit_start;
      panel.pdb_author_end   = (sel.attr('data-author-end'))   ? Number(sel.attr('data-author-end'))   : Number(sel.attr('data-hit-end'));
      console.log("    # PDB coords of "+pdb_id+" (on ENSP): "+panel.pdb_start+'-'+panel.pdb_end);

      // Display selected ENSP ID and PDB model ID in page
      $('#mapping_top_ensp').html('<small style="color:#DDF">Ensembl: </small><span>'+panel.ensp_id+'</span>');
      $('#mapping_top_ensp').attr("href", '/'+panel.species+'/Transcript/Summary?t='+panel.ensp_id);
      $('#mapping_top_ensp').show();
      $('#mapping_top_pdb').html('<small style="color:#DFD">PDBe: </small><span>'+pdb_id.toUpperCase()+'</span>');
      $('#mapping_top_pdb').attr("href", panel.pdbe_url_root+'/entry/pdb/'+pdb_id);
      $('#mapping_top_pdb').show();

      $('#mapping_ensp').html(panel.ensp_id);
      $('#mapping_pdb').html(pdb_id.toUpperCase());

      // Assign position to variant
      if (panel.var_id) {

        // Position on ENSP
        var var_pos_ensp = panel.ensp_var_pos[panel.ensp_id].split('-');
        // Position on PDB
        var var_pdb_coords = panel.ensp_to_pdb_coords(var_pos_ensp[0],var_pos_ensp[1]);
        // Position on PDB author coordinates
        var var_pdb_author_coords = panel.ensp_to_pdb_coords(var_pos_ensp[0],var_pos_ensp[1],1);

        $('#'+panel.var_id+'_cb').attr('data-value', var_pdb_coords[0]+','+var_pdb_coords[1]);

        // Special display for the stop_gained variants
        var var_cons = panel.ensp_var_cons[panel.ensp_id];
        if (var_cons && (var_cons == 'stop_gained' || var_cons == 'frameshift_variant')) {
          var var_pos_after_stop =  Number(var_pdb_coords[1]) + 1;

          var altered_sequence = '<tr>'+
                                 '  <td style="border-color:darkred">Altered/missing sequence</td>'+
                                 '  <td>from '+var_pdb_author_coords[0]+'</td><td>from '+var_pos_ensp[1]+'</td>'+
                                 '  <td><span class="pdb_feature_entry float_left view_enabled" id="'+
                                      panel.var_id+'_alt_cb" data-value="'+var_pos_after_stop+','+panel.pdb_end+'" data-group="variant_group" data-name="'+
                                      panel.var_id+'_alt" data-colour="darkred"></span></td>'+
                                 '</tr>';
          
          $('#var_details_div > table > tbody').append(altered_sequence);
        }

        // Display variant coordinates on ENSP and PDB
        var var_pos_pdb = (var_pdb_author_coords[0] == var_pdb_author_coords[1]) ? var_pdb_author_coords[0] : var_pdb_author_coords[0]+'-'+var_pdb_author_coords[1];
        $('#var_pos_pdb').html(var_pos_pdb);
        var_pos_ensp = (var_pos_ensp[0] == var_pos_ensp[1]) ? var_pos_ensp[0] : var_pos_ensp[0]+'-'+var_pos_ensp[1];
        $('#var_pos_ensp').html(var_pos_ensp);

        console.log("  >>> STEP 11a: Select PDB entry (selectPDBEntry) - variant setup done");
      }
      // No need to check for variant position: selection done
      else {
        console.log("  >>> STEP 11b: Select PDB entry (selectPDBEntry) - done"); 
      }

      // Assign position to ENSP mapping
      var ensp_pdb_coords = panel.ensp_to_pdb_coords(panel.pdb_start, panel.pdb_end);
      $('#mapping_cb').attr('data-value', ensp_pdb_coords[0]+','+ensp_pdb_coords[1]);

      // ENSP covered coordinates
      $('#mapping_ensp_pos').html(panel.pdb_start+'-'+panel.pdb_end);
      // PDB  covered coordinates
      var ensp_pdb_author_coords = panel.ensp_to_pdb_coords(panel.pdb_start, panel.pdb_end,1);
      $('#mapping_pdb_pos').html(ensp_pdb_author_coords[0]+'-'+ensp_pdb_author_coords[1]);

      // Display the LiteMol canvas
      panel.load3DWidget();
  

      // Load the right hand side menu
      if (panel.ensp_id) {
        // Exons
        panel.get_exon_data(panel.ensp_id);
        // Protein features
        panel.get_protein_feature_data(panel.ensp_id);
        // SIFT and PolyPhen2
        panel.get_sift_polyphen_data(panel.ensp_id);
      }

      // Wait for the loading of the model into the widget before starting to load the  default highlighting
      LiteMol.Bootstrap.Event.Tree.NodeAdded.getStream(panel.liteMolScope.LiteMolComponent.plugin.context).subscribe(function (e) {

        if(e.data.ref == "model"){

          console.log(">>>>> STEP 12: Load 3D widget (selectPDBEntry) - done");
        
          // Set timeout because it needs a bit of extra time at the end of the model rendering and before starting the group highlighting
          var timeout = 0 ;
          if (!panel.var_id) {
            var pdb_size = panel.pdb_end-panel.pdb_start+1;
            if (pdb_size > 800) {
              timeout = 800;
            }
            else if (pdb_size < 100) {
              timeout = 100;
            }
            else {
              timeout = Math.round(pdb_size / 10) * 10;
            }
          }
          setTimeout(function(){ panel.selectedFeatureGroupsToHighlight(); }, timeout);
          $('#litemol_buttons').show();
        }
      });
    }
    else {
      $('#litemol_buttons').hide();
    }
  },


  // Function to load the PDB LiteMol 3D Widget (Angular), with the colouration plugin
  load3DWidget: function() {
    var panel = this;

    // Reset if an other model already loaded
    panel.removeComponents(); 
  
    var pdb_litemol_id = 'litemol_pdb_model';
  
    var pdb_tag = '<pdb-lite-mol id="'+pdb_litemol_id+'" pdb-id="\''+panel.pdb_id+'\'" hide-controls="true" show-logs="false"></pdb-lite-mol>';
    
    $("#litemol_canvas").html(pdb_tag);

    var componentElements = $('#'+pdb_litemol_id);

    // Start Angular application
    angular.bootstrap(componentElements, ['pdb.component.library']);

    // Method to bind component scope
    var bindPdbComponentScope = function(element){
      return angular.element(element).isolateScope();
    }
    panel.liteMolScope = bindPdbComponentScope($('#'+pdb_litemol_id));
  },

 
  // Function to remove any existing component instance
  removeComponents: function() {
    $('#litemol_canvas').empty();
  },


  // Select/unselect a group of entries to highlight
  selectedFeatureGroupsToHighlight: function(id) {
    var panel = this;

    if (!id) {
      id = '_group';
    }

    var regex = /(sift|polyphen)/;
    var waiting_time = 0;
    if (regex.test(id)) {
      $('.view_spinner').show();
      waiting_time = panel.spinner_waiting_time;
    }

    // Display spinner icon for long loading highlighting such as SIFT and PolyPhen
    setTimeout(function(){
      $('div[id$='+id+']').each(function() {
        var gp_id = $(this).attr('id');

        // Check if group already selected
        var is_selected = $('#'+gp_id).hasClass('view_enabled');
        var pdb_feature_entry_array = $('[data-group="'+gp_id+'"]');

        // Update display of each item of the group
        pdb_feature_entry_array.each(function() {
          if (is_selected) {
            $(this).switchClass('view_disabled','view_enabled');
          }
          else {
            $(this).switchClass('view_enabled','view_disabled');
          }
        });
      });

      // Highlight the selected items
      panel.selectedFeaturesToHighlight();

      // Hide spinner if visible
      if ($('.view_spinner').is(":visible")) {
        $('.view_spinner').hide();
      }
    }, waiting_time);
  },


  // Select/unselect a subgroup of entries to highlight
  selectedFeatureSubGroupsToHighlight: function(id) {
    var panel = this;

    if (!id) {
      id = '_sg';
    }

    var regex = /(sift|polyphen)/;
    var waiting_time = 0;
    if (regex.test(id)) {
      $('.view_spinner').show();
      waiting_time = panel.spinner_waiting_time;
    }

    // Display spinner icon for long loading highlighting such as SIFT and PolyPhen
    setTimeout(function(){
      $('div[id$='+id+']').each(function() {
        var subgp_id = $(this).attr('id');
      
        // Check if sub-group already selected
        var is_selected = $('#'+subgp_id).hasClass('view_enabled');
        var pdb_feature_entry_array = $('[data-sg="'+subgp_id+'"]');
    
        // Update display of each item of the sub-group
        pdb_feature_entry_array.each(function() {
          if (is_selected) {
            $(this).switchClass('view_disabled','view_enabled');
          }
          else {
            $(this).switchClass('view_enabled','view_disabled');
          }
        });
      });

      // Highlight the selected items
      panel.selectedFeaturesToHighlight();
     
      // Hide spinner 
      if (regex.test(id)) {
        $('.view_spinner').hide();
      }
    }, waiting_time);
  },


  // Select/unselect a list of entries to highlight  
  selectedFeaturesToHighlight: function() {
    var panel = this;

    if (!panel.liteMolScope) {
      return;      
    }

    // Recolour to default colour when no selection
    var coloring_default = {
      base: panel.hexa_to_rgb['dark_grey'],
      entries: []
    };
    
    var model_default = panel.liteMolScope.LiteMolComponent.plugin.context.select('model')[0];
    if (!model_default) {
      return;
    }
    var theme_default = LiteMolPluginInstance.CustomTheme.createTheme(model_default.props.model, coloring_default);
  
    // instead of "polymer-visual", "model" or any valid ref can be used: all "child" visuals will be colored.
    LiteMolPluginInstance.CustomTheme.applyTheme(panel.liteMolScope.LiteMolComponent.plugin, 'polymer-visual', theme_default);

    // List the PDB struct_asyms mapped to the ENSP
    var pdb_chain_ids = ['A'];
    if (panel.pdb_chains && panel.pdb_chain_struc_entity[panel.pdb_id]) {
      pdb_chain_ids = panel.pdb_chains;
    }

    // Move the Variant element at the end of the array, in order to have it display all the time
    var pdb_feature_entry_array = $('.pdb_feature_entry');
    var var_index = '';
    pdb_feature_entry_array.each(function(index, el) {
      if (el.classList.contains('pdb_var_entry')) {
        var_index = index;
        return false;
      }
    });
    if (var_index != '') {
     // Move the Variant element at the end of the array
     var pdb_var_entry = pdb_feature_entry_array.splice(var_index, 1);
      pdb_feature_entry_array.push(pdb_var_entry[0]);
    }

    // Loop over the right hand menu to see what has been selected in order to highlight it
    var residueToHighlight = panel.features2LiteMol(pdb_feature_entry_array, pdb_chain_ids);
    var residueDetails = residueToHighlight[0];
    var specialResidueDetails = residueToHighlight[1];

    // Implementation from LiteMol core example
    var model = panel.liteMolScope.LiteMolComponent.plugin.context.select('model')[0];
    if (!model) {
      return;
    }
    var coloring = {
      base: panel.hexa_to_rgb['dark_grey'],
      entries: residueDetails
    };
    var theme = LiteMolPluginInstance.CustomTheme.createTheme(model.props.model, coloring);

    // Special highlight
    if (specialResidueDetails.length > 0) {
      var action = panel.liteMolScope.LiteMolComponent.Transform.build();
 
      for(var si=0, sl=specialResidueDetails.length; si<sl; si++ ){
        var query = panel.liteMolScope.LiteMolComponent.Query.sequence(
                        specialResidueDetails[si].entity_id.toString(),
                        specialResidueDetails[si].struct_asym_id.toString(),
                        { seqNumber: specialResidueDetails[si].start_residue_number }, 
                        { seqNumber: specialResidueDetails[si].end_residue_number }
                    );
        if (specialResidueDetails[si].checked) {
          action.add(model, panel.liteMolScope.LiteMolComponent.Transformer.Molecule.CreateSelectionFromQuery, { query: query, name: 'Selection-'+si }, { ref: 'sequence-selection-'+si })
          .then(panel.liteMolScope.LiteMolComponent.Transformer.Molecule.CreateVisual, { style: panel.liteMolScope.LiteMolComponent.Visualization.Molecule.Default.ForType.get('BallsAndSticks') });
        }
      }
  
      // Apply the transformation/highlighting 
      panel.liteMolScope.LiteMolComponent.applyTransforms(action).then(function(){
        // instead of "polymer-visual", "model" or any valid ref can be used: all "child" visuals will be colored.
        LiteMolPluginInstance.CustomTheme.applyTheme(panel.liteMolScope.LiteMolComponent.plugin, 'polymer-visual', theme);
      });
    }
    else if (residueDetails.length > 0) {
      // instead of "polymer-visual", "model" or any valid ref can be used: all "child" visuals will be colored.
      LiteMolPluginInstance.CustomTheme.applyTheme(panel.liteMolScope.LiteMolComponent.plugin, 'polymer-visual', theme);
    }
    
    console.log(">>>>> STEP 14: Highlight selected features (selectedFeaturesToHighlight) - done");
  },

 
  // Convert selected items from the menu to the 3D viewer
  features2LiteMol: function(pdb_feature_entry_array, pdb_chain_ids) {
    var panel = this;
    var residueDetails = [];
    var specialResidueDetails = [];
    var featureGroups = {};   

    pdb_feature_entry_array.each(function(index, el) {

      // Check whether all the group entries have been checked or not
      // Then it check or uncheck the "Group" checkbox
      var group_id = el.getAttribute('data-group');
      var is_enabled = $(this).hasClass('view_enabled');
      if (!featureGroups[group_id]) {
        var pdb_feature_entry_array = $('[data-group="'+group_id+'"]');
        var count_checked = 0;
        pdb_feature_entry_array.each(function() {
          if ($(this).hasClass('view_enabled')) {
            count_checked++;
          }
        });
        // Check if all the item of a group have been checked or not
        if (count_checked == pdb_feature_entry_array.length) {
          $('#'+group_id).switchClass('view_disabled','view_enabled');
          if ($("#"+group_id+"[data-has-sg]").length) {
            $('[data-super-group="'+group_id+'"]').switchClass('view_disabled','view_enabled');
          }
        }
        else {
          $('#'+group_id).switchClass('view_enabled','view_disabled');
          if ($("#"+group_id+"[data-has-sg]").length && count_checked == 0) {
            $('[data-super-group="'+group_id+'"]').switchClass('view_enabled','view_disabled');
          }
        }
        featureGroups[group_id] = 1;
      }

      var special_hl = el.getAttribute('data-highlight');

      // Check if item is checked
      if (is_enabled || special_hl) {  
        var data_colours = el.getAttribute('data-colour');
        var var_colours  = data_colours.split(';');
        var data_value   = el.getAttribute('data-value');
        
        var pos_list = data_value.split(';');

        // Loop over the reported positons
        $.each(pos_list, function(index, se_pos) {

          var pos = se_pos.split(',');

          // Colour the AA 1 by 1 because of some gaps in the 3D models messing up the colouration of a range of sequence.
          for (var i = Number(pos[0]); i <= Number(pos[1]); i++) {
 
            var start_residue = i;
            var end_residue   = i;

            var var_colour = var_colours[index];
            
            // Produce the highlighting on each chain
            for (var j = 0; j < pdb_chain_ids.length; j++) {
              var chain = pdb_chain_ids[j];
              var struct_asym = chain; 
              var entity = 1;
              if (panel.pdb_chain_struc_entity[panel.pdb_id] && panel.pdb_chain_struc_entity[panel.pdb_id][chain]) {
                entity      = panel.pdb_chain_struc_entity[panel.pdb_id][chain]['entity_id'];
                struct_asym = panel.pdb_chain_struc_entity[panel.pdb_id][chain]['struct_asym_id'];
              }
              // Data structure to be sent to LiteMol
              var selectionDetails = {
                                       entity_id : entity, 
                                       struct_asym_id : struct_asym,
                                       start_residue_number : start_residue, 
                                       end_residue_number : end_residue,
                                       color: panel.hexa_to_rgb[var_colour],
                                       checked: is_enabled
                                     };
              if (is_enabled) {
                residueDetails.push(selectionDetails);
              }
              // Special highlighting with side chaine
              if (typeof special_hl !== typeof undefined && special_hl !== false && special_hl !== null) {
                var hl_list = special_hl.split(';');
                if (hl_list[index] == 1) {
                  specialResidueDetails.push(selectionDetails);
                }
              }

            }
          }
        });
      }
    });
    return [residueDetails,specialResidueDetails];
  },



  //------------//
  //  PDB data  //
  //------------//

  // Method to fetch all the ENSP-PDB mappings from the Ensembl database and then:
  // - Get extra PDB information (quality, chain, author coordinates)
  // - Filter/sort the results and build PDB objects
  get_all_pdb_list: function() {
    var panel = this;
    console.log(">>>>> STEP 06: Get all the PDB lists (get_all_pdb_list) - start");
    $('#pdb_list_label').hide();
    $('#pdb_list').hide();
    $('#right_form').addClass('loader_small');

    var pdb_list_calls    = [];
    var ensp_list_cleaned = [];
    // Get the list of mapped PDB entries for each ENSP (from Ensembl 'protein_features' DB table, throught the REST API)
    $.each(panel.ensp_list, function(i,ensp) {
      if ((panel.var_id && panel.ensp_var_pos[ensp]) || !panel.var_id) {    
        pdb_list_calls.push(panel.get_pdb_by_ensp(ensp));
        ensp_list_cleaned.push(ensp);
      }
    });

    // Remove the Ensembl proteins which don't overlap the variant (if we are on a variant page)
    if (panel.ensp_list.length != ensp_list_cleaned.length) {
      panel.ensp_list = ensp_list_cleaned;
    }

    // Waiting that the search of PDB entries for each ENSP has been done, using a list of promises,
    // so it can returns an error message if no mappings at all have been found
    $.when.apply(undefined, pdb_list_calls).then(function(results){
      var pdb_unique_list = []; 
      $.each(panel.ensp_list, function(i,ensp) {
        // Extract list of PDB IDs and fetch extra PDB information (through the PDBe REST API)
        if (panel.protein_features[ensp]['pdb'] && panel.protein_features[ensp]['pdb'].length !=0) {
          var var_pos = panel.ensp_var_pos[ensp];          

          // Loop over the PDB models for a given ENSP
          $.each(panel.protein_features[ensp]['pdb'],function (index, result) {
            var pdb_acc = result.id.split('.');
            var pdb_id = pdb_acc[0];

            if ($.inArray(pdb_id,pdb_unique_list) == -1) {
              // If variant page, check that the PDB model(s) overlap the variant
              var var_in_pdb = 0;
              if (var_pos) {
                var var_pos_list = var_pos.split('-');
                if (var_pos_list[0] >= result.start && var_pos_list[1] <= result.end) {
                  var_in_pdb = 1;
                }
              }
              if ((var_pos && var_in_pdb == 1) || !var_pos) {
                // Setup ensp_id if none has been assigned
                if (panel.ensp_id == undefined) {
                   panel.ensp_id = ensp;
                }
                // Add PDB model to the list;
                pdb_unique_list.push(pdb_id);     
              }
            }
          });
        }
        // Can't get PDB model for this ENSP
        else {
          panel.no_pdb_list_available(ensp);
        }
      });

      // Add additional information for each PDB model
      if (pdb_unique_list.length > 0) {
        panel.get_pdb_extra_data(pdb_unique_list);
      }
      // No PDB mapping retained
      else {
        panel.no_mapping_available();
      }
    });
  },


  // Extract the list of mapped PDB model for all the ENSP
  // and then fetch extra information about these PDB models (through the PDB REST API)
  get_pdb_extra_data: function(pdb_list) {
    var panel = this;

    // Get quality score and PDB chain structure before generating the final list of PDB entries for this ENSP
    $.when(panel.get_pdb_quality_score(pdb_list), panel.get_pdb_chain_struc_entity(pdb_list)).then(function() {
        // Will store the list of PDB AJAX calls to get the author position of each PDB model
        var list_pdb_ensp_for_author_pos = [];

        $.each(panel.ensp_list, function(index, ensp) {
          // Build PDB objects and reduce the number of PDB models if the list is too long (e.g. > 10 PDB models per ENSP)
          panel.parse_pdb_results(ensp);

          // Extract the list of PDB IDs with chain information in order to fetch each PDB model's author coordinates
          var pdb_list_author_pos = [];
          if (panel.ensp_pdb_list[ensp]) {
            // Generate the list of AJAX calls to get the author position for each PDB
            $.each(panel.ensp_pdb_list[ensp],function(index, pdb_entry) {
              if(panel.pdb_chain_struc_entity[pdb_entry.id]) {
                list_pdb_ensp_for_author_pos.push(pdb_entry.id+'#'+ensp);
              }
            });
          }
        });

        // Will store the list of PDB AJAX calls to get the author position of each PDB model
        var pdb_list_author_pos = [];
        $.each(list_pdb_ensp_for_author_pos, function(index,pdb_ensp) {
          var ensp_pdb_ids = pdb_ensp.split('#');
          var pdb_id  = ensp_pdb_ids[0];
          var ensp_id = ensp_pdb_ids[1];

          pdb_list_author_pos.push(panel.get_pdb_author_pos(pdb_id,ensp_id)); 
        });

        // Waiting that the PDB author positions are fetched for each PDB model, using a list of promises,
        // and then it finalise the list of PDB models for the given ENSP
        $.when.apply(undefined,pdb_list_author_pos).then(
          // Success
          function(){
            console.log("  >>> STEP 08c: PDB author coordinates (get_pdb_author_pos) - done");
            panel.finish_parse_pdb_results();
          },
          // Error
          function(){
            panel.no_mapping_available();            
          }
        );
      });
  },


  // Get list of PDBe models and other protein annotations mapped to the ENSP
  get_pdb_by_ensp: function(ensp) {
    var panel = this;
    panel.protein_features[ensp] = { 'pdb' : [] };

    return $.ajax({
      url: panel.rest_pr_url+ensp+'?feature=protein_feature',
      method: "GET",
      contentType: "application/json; charset=utf-8"
    })
    .done(function (data) {
      $.each(data, function(index,item) {
        var type = item.type;

        var ensp_mapping_length = item.end-item.start+1;
        var hit_mapping_length  = item.hit_end-item.hit_start+1;

        // Store the mapping information in an associative array
        if (panel.protein_sources[type] || type == null) {
          // Case of PDB entries
          if (type == null) {
            // Calculate the percentage of coverage
            var percent_coverage = (hit_mapping_length / panel.ensp_length[ensp])*100;
            // Filter out short PDB mappings or PDB mappings with different length
            if (hit_mapping_length < panel.mapping_min_length || percent_coverage < panel.mapping_min_percent || ensp_mapping_length != hit_mapping_length) {
              return true;
            }
            type = 'pdb';
          }
          if (panel.protein_features[ensp][type]) {
            panel.protein_features[ensp][type].push(item);
          }
          else {
            panel.protein_features[ensp][type] = [item];
          }
        }
      });

      console.log(">>>>> STEP 07: Get list of PDBs by ENSP - "+ensp+" (get_pdb_by_ensp) - done");
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });
  },

  // Get the quality score of each PDB model, through the PDBe REST API
  get_pdb_quality_score: function(pdb_list) {
    var panel = this;

    return $.ajax({
      type: "POST",
      url: panel.rest_pdbe_quality_url,
      data: pdb_list.join(',')
    })
    .done(function (pdb_data) {
      // Store each PDB model quality score
      $.each(pdb_data,function (pdb_id, pdb_results) {
          panel.ensp_pdb_quality_list[pdb_id] = pdb_results.overall_quality;
  console.log('    > Quality for '+pdb_id+": "+panel.ensp_pdb_quality_list[pdb_id]);
      })
      console.log("  >>> STEP 08a: Get PDB quality (get_pdb_quality_score) - done");
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });
  },


  // Get extra information about the model. Very useful to highlight the correct parts of the model:
  // - entity: get the protein entity ID in the model (avoid to highlight DNA or water molecules) => polypeptide(L)
  // - chain: get the list of chains for the entity (e.g. A, B, C)
  // - struct_asyms: get the internal name of the chains ("used to store details about the structural elements in the asymmetric unit").
  //                 Most of the time the struct_asyms match the chain names (e.g. A, B, C)
  get_pdb_chain_struc_entity: function(pdb_list) {
    var panel = this;

    return $.ajax({
      type: "POST",
      url: panel.rest_pdbe_url,
      data: pdb_list.join(',')
    })
    .done(function (pdb_data) {
      $.each(pdb_data,function (pdb_id, pdb_results) {
        // Get entity ID
        $.each(pdb_results, function (index, pdb_result) {
          var entity = pdb_result.entity_id;

          if (pdb_result.molecule_type!='polypeptide(L)' || !entity) {
            return true;
          }
          
          // Store the chain list and structure asyms data for each PDB model
          $.each(pdb_result.in_chains,function (j, chain) {
            var struct_asym = pdb_result.in_struct_asyms[0];
            if (pdb_result.in_struct_asyms[j] && j != 0) {
              struct_asym = pdb_result.in_struct_asyms[j];
            }
            if (!panel.pdb_chain_struc_entity[pdb_id]) {
              panel.pdb_chain_struc_entity[pdb_id] = {};
            }
            panel.pdb_chain_struc_entity[pdb_id][chain] = { 'struct_asym_id': struct_asym, 'entity_id': entity };
          });
        });
      });
      console.log("  >>> STEP 08b: Get PDB chain info (get_pdb_chain_struc_entity) - done");
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });
  },
 

  // Get the PDB author position as it cooresponds to the position displayed on the 3D viewer.
  // However we need to provide the PDB "Curator" coordinates to the 3D viewer
  get_pdb_author_pos: function(pdb_id,ensp) {
    var panel = this;

    var chain;
    $.each(panel.ensp_pdb_list[ensp], function(index,pdb_entry) {
      if (pdb_entry.id == pdb_id) {
        chain = pdb_entry.chain[0];
        return false;
      }
    });

    var entity_id = panel.pdb_chain_struc_entity[pdb_id][chain]['entity_id'];

    return $.ajax({
      url: panel.rest_pdbe_sifts_url+pdb_id,
      method: "GET"
    })
    .done(function (data) {
      var data_pdb = data[pdb_id].Ensembl;

      var mapped_gene = 0;
      var author_start;
      var author_end;
      var has_undef_author_start = 0;
      var has_undef_author_end = 0;
      var residue_start;
      var residue_end;
      // Browse into the JSON output
      $.each(data[pdb_id].Ensembl, function (index, ens_gene) {
        $.each(ens_gene.mappings, function(index2, pdb_mapping) {
          // Only look at the entries corresponding to the given ENSP data
          if (pdb_mapping.translation_id == ensp) {
            mapped_gene = 1;
            // Check that we are looking at the right data (entity_id and chain_id)
            if (pdb_mapping.entity_id == entity_id && pdb_mapping.chain_id == chain) {
              var tmp_start = pdb_mapping.start.residue_number;
              var tmp_end   = pdb_mapping.end.residue_number;

              var tmp_author_start = pdb_mapping.start.author_residue_number;
              var tmp_author_end   = pdb_mapping.end.author_residue_number;

              // Flag the entries with undefined author start and/or end
              if (tmp_author_start == undefined) {
                has_undef_author_start = 1;
              }
              if (tmp_author_end == undefined) {
                has_undef_author_end = 1;
              }

              if (residue_start == undefined || tmp_start < residue_start) {
                residue_start = tmp_start;
                author_start  = (tmp_author_start) ? tmp_author_start : 1;
              }
              if (residue_end == undefined || tmp_end > residue_end) {
                residue_end = tmp_end;
                author_end  = (tmp_author_end) ? tmp_author_end : residue_end;
              }
            }
          }
        });
        // No need to look at other genes
        if (mapped_gene == 1) {
          return false;
        }
      });
      
      // Add the coordinates to the array if we have enough information
      if (author_start && author_end && (has_undef_author_start == 0 || has_undef_author_end == 0)) {
        if (!panel.ensp_pdb_author_pos[ensp]) {
          panel.ensp_pdb_author_pos[ensp] = { pdb_id: {} };
        }
        panel.ensp_pdb_author_pos[ensp][pdb_id] = { 'start': author_start, 'end': author_end };
      }
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });
  },


  // Select "best" PDBe entries and store all the information needed into an array of Objects
  parse_pdb_results: function(ensp) {
    var panel = this;

    panel.removeSpinner();

    var pdb_list   = [];
    var pdb_objs   = [];
    var pdb_struct_asym_list = new Object();

    var protein_features = panel.protein_features[ensp]['pdb'];
   
    // Generate a distinct list of chains reported in the Ensembl REST for each PDB entry mapped to the givem ENSP
    // The entries can be duplicated for the PDB models composed of several chains, e.g. for 1BMO:
    // 1bmo.A, 1bmo.B => pdb_struct_asym_list['1bmo'] = ['A','B']
    $.each(protein_features,function (index, result) {
      var pdb_acc = result.id.split('.');
      var pdb_id = pdb_acc[0];
      var pdb_struct_asym = pdb_acc[1];
      if (pdb_struct_asym_list[pdb_id] && $.inArray(pdb_struct_asym,pdb_struct_asym_list[pdb_id]) == -1) { 
        pdb_struct_asym_list[pdb_id].push(pdb_struct_asym);
      }
      else {
        pdb_struct_asym_list[pdb_id] = [pdb_struct_asym];
      }
    });

    // Prepare PDB list with the added data (quality and structure)
    $.each(protein_features,function (index, result) {
      var pdb_acc = result.id.split('.');
      var pdb_id = pdb_acc[0];
      // Create object with PDB extra data
      if ($.inArray(pdb_id,pdb_list) == -1) {
        var pdb_size = result.end - result.start + 1;

        // Build a PDB object
        // Example for the mapping ENSP00000231061 - 1BMO:
        // { id: "1bmo", start: 71, end: 303, chain: ['A','B'], size: 233, hit_start: 1, hit_end: 233, author_start: 54, author_end: 286, overall_quality: 9.64 }
        pdb_objs.push(
          { 
            id: pdb_id, 
            start: result.start, 
            end: result.end, 
            chain: pdb_struct_asym_list[pdb_id].sort(), 
            size: pdb_size, 
            hit_start: result.hit_start, 
            hit_end: result.hit_end,
            author_start: undefined,
            author_end: undefined,
            overall_quality: panel.ensp_pdb_quality_list[pdb_id]
          }
        );
        pdb_list.push(pdb_id);
      }
    });

    // Only select "best" models by default
    if (pdb_objs && pdb_objs.length != 0) {
      pdb_objs.sort(function(a,b) {
        return b.size - a.size || b.overall_quality - a.overall_quality;
      });
      // Only get the best models (see max_pdb_entries)
      panel.ensp_pdb_list[ensp] = pdb_objs.slice(0, panel.max_pdb_entries);
    }
  },


  // Finish the list of PDB list to display:
  // - Add the PDB author position
  // - Remove PDB model from list if the length of the author PDB coordinates differs from the PDB curator length
  // - Add the ENSP selection and display its corresponding PDB list
  finish_parse_pdb_results: function() {
    var panel = this;
 
    var count_ensp_with_pdb_list = 0;

    console.log("  >>> STEP 09a: Start parse PDBs results (finish_parse_pdb_results)");

    $.each(panel.ensp_pdb_list, function(ensp, pdb_entries) {
      var pdb_entry_to_remove = [];
      // Add the PDB author coordinates and remove the PDB entry having a different length between
      // the PDB author and the PDB curator
      // At the moment we are quite strict on it, just to be on a safe side that the 3D model - PDB entry - ENSP mappings make sense
      $.each(pdb_entries, function(index, pdb_entry) {
        var is_coord_ok = 0;
        // Check that we fetched the author coordinates
        if (panel.ensp_pdb_author_pos[ensp]) {
          var ensp_length = pdb_entry.end-pdb_entry.start;
          var pdb_length  = pdb_entry.hit_end-pdb_entry.hit_start;
          // Check that the author coordinates have been fetched
          if (panel.ensp_pdb_author_pos[ensp][pdb_entry.id]) {
            var author_pdb_length = panel.ensp_pdb_author_pos[ensp][pdb_entry.id]['end'] - panel.ensp_pdb_author_pos[ensp][pdb_entry.id]['start'];
            // Add the author coordinates if the author and curator length match.
            if (pdb_length == author_pdb_length) {
              pdb_entry.author_start = panel.ensp_pdb_author_pos[ensp][pdb_entry.id]['start'];
              pdb_entry.author_end   = panel.ensp_pdb_author_pos[ensp][pdb_entry.id]['end'];
              is_coord_ok = 1;
            }
          }
        }
        // Add PDB entry to the list of PDB model to remove
        if (is_coord_ok == 0) {
          pdb_entry_to_remove.push(pdb_entry);
        }
      });
      // Remove the PDB model(s) from the list
      if (pdb_entry_to_remove.length) {
        $.each(pdb_entry_to_remove, function(index2, pdb_entry) {
          console.log("    > Entry "+pdb_entry.id+" removed from the list");
          panel.ensp_pdb_list[ensp].splice( $.inArray(pdb_entry,panel.ensp_pdb_list[ensp]) ,1);
        });
      }

      // Display ENSP entry in the ENSP selection dropdown if there are some PDB models to display
      if (Object.keys(panel.ensp_pdb_list[ensp]).length > 0) {
        var ensp_option = { 'value' : ensp, 'text' : ensp };
        if (ensp == panel.ensp_id) {
          ensp_option['selected'] = 'selected';
          // Display the list of PDB entries in the selection dropdown
          panel.display_pdb_list(ensp);
        }
        $('#ensp_list').append($('<option>', ensp_option));
        count_ensp_with_pdb_list ++;
      }
      // No PDB model
      else {
        panel.no_pdb_list_available(ensp);
      }
    });

    if (count_ensp_with_pdb_list == 0) {
      panel.no_mapping_available();
    }
    console.log("  >>> STEP 09b: Finish parse PDBs results (finish_parse_pdb_results) - done");
  },


  // Method adding the ENSP to the list of reviewed ENSP
  // Also reset the module ensp_id if no PDB model found for the ENSP 
  // and there are more than 1 ENSP available
  no_pdb_list_available: function(ensp) {
    var panel = this;

    // Reset panel.ensp_id if no PDB model found for the ENSP and there are more than 1 ENSP available
    if (ensp == panel.ensp_id && panel.ensp_list.length > 1) {
      panel.ensp_id = undefined;
    }
  },


  // Method displaying an error message when no ENSP-PDB mappings have been found/retained
  no_mapping_available: function() {
    var panel = this;

    panel.removeSpinner();
    var ensp_no_pdb = (panel.ensp_list.length > 1) ? ':<ul class="top-margin bottom-margin"><li>'+panel.ensp_list.join('</li><li>')+'</li></ul>' : panel.ensp_list[0]+".";
    var var_pos = Object.keys(panel.ensp_var_pos).length;
    if (var_pos) {
      panel.showNoData('No PDB models overlapping this variant on the following protein(s) have been found/selected: '+ensp_no_pdb);
    }
    else {
      panel.showNoData('No PDB models mappings have been found/selected for the  protein(s) '+ensp_no_pdb);
    }
    console.log(">>>>> STEP 99: No ENSP-PDB mappings found/retained (no_mapping_available)");
  },

  // Display the dropdown selector for the PDB models
  display_pdb_list: function(ensp) {
    var panel = this;

    panel.removeSpinner();

    if ($.isEmptyObject(panel.ensp_pdb_list) || !panel.ensp_pdb_list[ensp]) {
      panel.showNoData();
    }
    else {
      if ($('.var_pos').length) {
        $('.var_pos').html(panel.ensp_var_pos[ensp]);
        $('#var_cons').html('('+panel.ensp_var_cons[ensp]+')');
        $('#var_ensp_id').html(ensp);
      }

      // Retrieve the list of PDB entries for this ENSP
      var pdb_objs = panel.ensp_pdb_list[ensp];
      var pdb_objs_length = pdb_objs.length;   

      $('#right_form').removeClass('loader_small');
      $('#pdb_list_label').hide();
      $('#pdb_list').hide();
      $('#pdb_list').html('');

      var selected_pdb;
      var show_pdb_list = 0;
      var first_pdb_entry = 1;

      // Makes sure the length of the ENSP is returned before populating the list of PDBe entries
      // The Ensembl REST call is made at the beginning of the script
      var counter = 0;
      $('#pdb_list').html('');

      // Add PDB models to the dropdomn list
      $.each(pdb_objs, function (i, pdb_obj) {
        var pdb_mapping_length = pdb_obj.end - pdb_obj.start + 1;
        var ensp_pdb_percent  = (pdb_mapping_length/panel.ensp_length[ensp])*100;
        var ensp_pdb_coverage = Math.round(ensp_pdb_percent);

        var pdb_coord = " - Coverage: [ PDBe: "+pdb_obj.author_start+"-"+pdb_obj.author_end+" | ENSP: "+pdb_obj.start+"-"+pdb_obj.end+" ] => "+ensp_pdb_coverage+"% of ENSP length";
        var pdb_option = {
          'value'         : pdb_obj.id,
          'data-start'    : pdb_obj.start,
          'data-end'      : pdb_obj.end,
          'data-hit-start': pdb_obj.hit_start,
          'data-chain'    : pdb_obj.chain,
          'text'          : pdb_obj.id + pdb_coord
        };
        // Add author coordinates
        if ((pdb_obj.hit_start != pdb_obj.author_start || pdb_obj.hit_end != pdb_obj.author_end) && (pdb_obj.author_start && pdb_obj.author_end)) {
          pdb_option['data-author-start'] = pdb_obj.author_start;
          pdb_option['data-author-end']   = pdb_obj.author_end;
        }
        // Use hit end (from Ensembl REST API)
        else {
          pdb_option['data-hit-end'] = pdb_obj.hit_end;
        }

        // Automatically select the first PDB entry in the list
        if (first_pdb_entry == 1 || pdb_objs_length == 1) {
          pdb_option['selected'] = 'selected';
          selected_pdb = pdb_obj.id;
          first_pdb_entry = 0;
        }
        $('#pdb_list').append($('<option>', pdb_option));
        show_pdb_list = 1;
      });

      // Display PDB list dropdown
      if (show_pdb_list) {
        $('#pdb_list_label').show();
        $('#pdb_list').show();
        panel.selectPDBEntry(selected_pdb);
      }
      else {
        panel.showNoData();
      }
    }
    $('#ensp_pdb').show();
  },
 

 
  //----------------// 
  //  Ensembl data  //
  //----------------//

  // Variant data //

  // Add variant link
  add_var_link: function(var_id) {
    var panel = this;
    return '<a href="/'+panel.species+'/Variation/Explore?v='+var_id+'" target="_blank">'+var_id+'</a>';
  },
 
  // Get variant ID, overlapping protein(s), variant coordinates on the protein(s) and its consequence(s)
  // Use the Ensembl VEP endpoint
  get_var_ensp_data: function() {
    var panel = this;

    // Get the variant ID
    var var_id_param = this.getParameterByName("v");
    var var_id;
    if (var_id_param) {
      var_id = var_id_param;
    }
    else if ($("#var_id").length) {
      var_id = $("#var_id").html();
    }

    panel.var_id = var_id;

    $("#var_id").html(panel.var_id);

    console.log(">>>>> STEP 01: Get Variant ID (get_var_ensp_data) - done");

    // Get variant/protein information
    return $.ajax({
      url: panel.rest_vep_url+panel.var_id+"?protein=1",
      method: "GET",
      contentType: "application/json; charset=utf-8"
    })
    .done(function (data) {
      console.log(">>>>> STEP 02: Get Variant data (get_var_ensp_data) - done");
      var tv_list = data[0].transcript_consequences;
      if (tv_list.length > 0) {
        var var_ensp_list = [];
        $.each(tv_list,function (index, tv) {
          if (tv.protein_id) {
            // Get ENSP, variant position and variant consequence
            var ensp = tv.protein_id;
            if ($.inArray(ensp,var_ensp_list) == -1) {
              // ENSP list
              var_ensp_list.push(ensp);
              // Var ENSP coordinates
              panel.ensp_var_pos[ensp] = tv.protein_start+'-'+tv.protein_end;
              // Var ENSP consequence
              panel.ensp_var_cons[ensp] = tv.consequence_terms[0];
              console.log("  >>> STEP 03a: Get Variant pos on "+ensp+" (get_var_ensp_data) - done");
            } 
          }
        });
      }
 
      $('#right_form').removeClass('loader_small');
      $('#ensp_list').html('');
      $('#pdb_list').html('');

      if (var_ensp_list.length == 0) {
        panel.showNoData('No overlapping Ensembl protein found');
      }
      else {
        // Sorth the list of ENSP and select by default the first ENSP in the list
        var_ensp_list.sort();
        panel.ensp_list = var_ensp_list;
        if (!panel.ensp_id) {
          panel.ensp_id = var_ensp_list[0];
        }
        console.log(">>>>> STEP 04: Get ENSP list (get_var_ensp_data) - done");
      }
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
      panel.removeSpinner();
      panel.showMsg();
    });
  },

  
  // Get the ENSP length - unfortunately this has to be done on a different REST endpoint
  get_ens_protein_length: function() {
    var panel = this;

    return $.ajax({
      type: "POST",
      url: panel.rest_lookup_url,
      data: '{ "ids" : ["'+panel.ensp_list.join('","')+'"], "db_type" : "core" }',
      dataType: "json",
      contentType: 'application/json; charset=utf-8'
      })
      .done(function (data) {
        $.each(data, function(ensp, ensp_info) {
          panel.ensp_length[ensp] = ensp_info.length;
        });
        console.log(">>>>> STEP 05: Get ENSP length (get_ens_protein_length) - done");
      })
      .fail(function (xhRequest, ErrorText, thrownError) {
        console.log('ErrorText: ' + ErrorText + "\n");
        console.log('thrownError: ' + thrownError + "\n");
        panel.removeSpinner();
        panel.showMsg();
      });
  },


  
  //------------------------------------//
  //  Get and display Ensembl features  //
  //------------------------------------//
  
  // Exon //
  
  // Get overlapping exons
  get_exon_data: function(ensp_id) {
    var panel = this;

    $.ajax({
        url: panel.rest_pr_url+ensp_id+'?feature=translation_exon',
        method: "GET",
        contentType: "application/json; charset=utf-8",
        success: function (data) {
          console.log("  >>> STEP 13a: Get Exon data (get_exon_data) - done");
          panel.parse_exon_results(data);
        },
        error: function (xhRequest, ErrorText, thrownError) {
          console.log('ErrorText: ' + ErrorText + "\n");
          console.log('thrownError: ' + thrownError + "\n");
        }
    });
  },
  // Parse AJAX results for the overlapping exons and display them on the right hand side menu
  parse_exon_results: function(data) {
    var panel = this;
    if (!data.error) {
      var exon_details = '';
      $("#exon_details_div").html('');

      // List the exons inside and outside the PDB model
      var exon_in_pdb_count = 0;
      var exon_not_in_pdb = new Object();
      $.each(data,function (index, result) {
        var exon_start = result.start;
        var exon_end   = result.end;

        if ((exon_start < panel.pdb_start && exon_end < panel.pdb_start) || (exon_start > panel.pdb_end && exon_end > panel.pdb_end)) {
          exon_not_in_pdb[index] = 1;
          return true;
        }
        exon_in_pdb_count ++;
      });

      // Prepare the list of exons to be displayed on the right hand side menu
      var data_size = Object.keys(data).length;
      var exon_count = 0;
      $.each(data,function (index, result) {

        if (exon_not_in_pdb[index]) {
          return true;
        }

        var exon_number = index + 1;

        var exon_start = result.start;
        var exon_end   = result.end;

        // Remove condon stop at the end of the last exon (1aa)
        if (exon_number == data_size) {
          exon_end--;
        }

        // Start the exon with the beginning of the ENSP mapping
        if (exon_start < panel.pdb_start && exon_end > panel.pdb_start) {
          exon_start = panel.pdb_start;
        }
        // End the exon with the ending of the ENSP mapping
        if (exon_end > panel.pdb_end && exon_start < panel.pdb_end) {
          exon_end = panel.pdb_end;
        }

        var exon_pdb_coords = panel.ensp_to_pdb_coords(exon_start,exon_end);
        if (exon_pdb_coords.length == 0) {
          return true;
        }
        var exon_pdb_label_coords = panel.ensp_to_pdb_coords(exon_start,exon_end,1);

        var exon_pdb_start = exon_pdb_coords[0];
        var exon_pdb_end   = exon_pdb_coords[1];
        var exon_label_pdb_start = exon_pdb_label_coords[0];
        var exon_label_pdb_end   = exon_pdb_label_coords[1];

        // Colour
        var hexa_colour = panel.get_hexa_colour(exon_count, exon_in_pdb_count);

        var exon_label = '<a href="/'+panel.species+'/Transcript/Exons?t='+panel.ensp_id+'">Exon '+exon_number+'</a>';

        var exon_coords = exon_pdb_start+','+exon_pdb_end;

        exon_details += '<tr><td style="border-color:'+hexa_colour+'">'+exon_label+'</td>'+
          '<td>'+exon_label_pdb_start+'-'+exon_label_pdb_end+'</td><td>'+exon_start+'-'+exon_end+'</td>'+
          '<td><span class="pdb_feature_entry float_left view_disabled" id="exon_'+exon_number+'_cb" data-value="'+exon_coords+'"'+
          ' data-group="exon_group" data-name="'+exon_number+'" data-colour="'+hexa_colour+'"></span></td></tr>';
     
        exon_count ++;
      });

      var label = (exon_count > 1) ? 'Exons' : 'Exon';

      panel.render_selection_details('exon','exon', label, exon_count, exon_details);
    }
  },


  // Protein annotations //

  // Extract the list of protein data overlapping the ENSP (except PDB)
  get_protein_feature_data: function(ensp_id) {
    var panel = this;

    var has_data = 0;
    $.each(panel.protein_sources, function(type, url) {
      if (panel.protein_features[ensp_id][type]) {
        panel.parse_protein_feature_results(panel.protein_features[ensp_id][type],type);
        has_data = 1;
      }
    });
    if (has_data == 0) {
      $("#protein_block").html("<div>No protein annotation found</div>");
    }
    console.log("  >>> STEP 13b: Get Proteins feature (get_protein_feature_data) - done");
  },
  // Parse AJAX results for the overlapping protein data (except PDB) and display them on the right hand side menu  
  parse_protein_feature_results: function(data,type) {
    var panel = this;

    var pf_details = '';
    var pf_count   = 0;

    var lc_type = type.toLowerCase();
     
    data.sort(function(a,b) {
      return a.start - b.start;
    });
 
    var data_size = Object.keys(data).length;
 
    // Prepare the list of protein features to be displayed on the right hand side menu
    $.each(data,function (index, result) {
      var pf_pdb_coords = panel.ensp_to_pdb_coords(result.start, result.end);
      if (pf_pdb_coords.length == 0) {
        return true;
      }
      var pf_pdb_label_coords = panel.ensp_to_pdb_coords(result.start,result.end,1);
      
      var pf_pdb_start = pf_pdb_coords[0];
      var pf_pdb_end   = pf_pdb_coords[1];
      var pf_label_pdb_start = pf_pdb_label_coords[0];
      var pf_label_pdb_end   = pf_pdb_label_coords[1];

      // Colour
      var hexa_colour = panel.get_hexa_colour(index, data_size);

      var pf_coords = pf_pdb_start+','+pf_pdb_end;
       
      var pf_id = result.id;
      if (panel.protein_sources[type]) {
        var pf_url = panel.protein_sources[type];
            pf_url += (type == 'Gene3D') ? panel.ensp_id : result.id;
        pf_id = '<a href="'+pf_url+'" rel="external">'+result.id+'</a>';
      }
 
      pf_details += '<tr><td style="border-color:'+hexa_colour+'">'+pf_id+'</td>'+
       '<td>'+pf_label_pdb_start+'-'+pf_label_pdb_end+'</td><td>'+result.start+'-'+result.end+'</td>'+
       '<td><span class="pdb_feature_entry float_left view_disabled" id="'+type+'_cb" data-value="'+pf_coords+'"'+
       ' data-group="'+lc_type+'_group" data-name="'+result.id+'" data-colour="'+hexa_colour+'"></span></td></tr>';

      pf_count ++;
    });

    panel.render_selection_details('protein', lc_type, type, pf_count, pf_details);
  },


  // SIFT and PolyPhen //

  // Get the SIFT and PolyPhen data of the overlapping variants
  get_sift_polyphen_data: function(ensp_id) {
    var panel = this;

    $.ajax({
      url: panel.rest_pr_url+ensp_id+'?feature=transcript_variation',
      method: "GET",
      contentType: "application/json; charset=utf-8"
    })
    .done(function (data) {
      console.log("  >>> STEP 13c: Get SIFT and PolyPhen data (get_sift_polyphen_data) - done");
      panel.parse_sift_results(data);
      panel.parse_polyphen_results(data);
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });
  },

  // Parse AJAX results for the overlapping SIFT variant data and display them on the right hand side menu
  parse_sift_results: function(data) {
    var panel = this; 

    data.sort(function(a,b) {
      return a.start - b.start;
    });

    var sift_details = '';
    var sift_count   = 0;

    var sift_sg = {'score_good' : 'sift_1_sg', 'score_bad' : 'sift_2_sg'};

    var sift_categories = {};

    // Prepare the list of SIFT data to be displayed on the right hand side menu
    $.each(data,function (index, result) {
      if (result.sift) {

        var var_pdb_coords = panel.ensp_to_pdb_coords(result.start, result.end);
        if (var_pdb_coords.length == 0) {
          return true;
        }
        var var_pdb_label_coords = panel.ensp_to_pdb_coords(result.start,result.end,1);

        var var_pdb_start = var_pdb_coords[0];
        var var_pdb_end   = var_pdb_coords[1];
        var var_label_pdb_start = var_pdb_label_coords[0];
        var var_label_pdb_end   = var_pdb_label_coords[1];

        var var_pdb  = (var_pdb_start == var_pdb_end) ? var_label_pdb_start : var_label_pdb_start+'-'+var_label_pdb_end;
        var var_ensp = (result.start == result.end) ? result.start : result.start+'-'+result.end;

        var sift_score = result.sift;

        var sift_coords = var_pdb_start+','+var_pdb_end;

        var sift_residues = result.residues;

        if (sift_residues.length > 5) {
          var sift_residues_label = sift_residues.substr(0,2)+'...';
          sift_residues = '<span class="ht" title="'+sift_residues+'">'+sift_residues_label+'</span>';
        }       

        // Colour
        var sift_class  = 'score_good';
        var sift_colour = 'green';
        if (sift_score <= 0.05) {
          sift_class  = 'score_bad';
          sift_colour = 'red';
        }

        sift_categories[sift_class] = 1;

        var var_id = panel.add_var_link(result.id);

        sift_details += '<tr><td style="border-color:'+sift_colour+'">'+var_id+'</td><td>'+var_pdb+'</td><td>'+var_ensp+'</td>'+
          '<td>'+sift_residues+'</td><td><div class="score '+sift_class+'">'+sift_score+'</div></td>'+
          '<td><span class="pdb_feature_entry float_left view_disabled" id="sift_'+result.id+'_cb" data-value="'+sift_coords+'"'+
          ' data-group="sift_group" data-name="'+result.id+'" data-colour="'+sift_colour+'" data-sg="'+sift_sg[sift_class]+'"></span></td></tr>';
        
        sift_count++;
      }
    });

    // Legend
    var legend_data = [
      { 'score_good' : { 'id': sift_sg['score_good'], 'class' : 'score_bg_good', 'label' : 'Tolerated',   'title' : 'Greater than or equal to 0.05' } },
      { 'score_bad'  : { 'id': sift_sg['score_bad'],  'class' : 'score_bg_bad',  'label' : 'Deleterious', 'title' : 'Less than 0.05' } }
    ];
    var legend = panel.build_legend(sift_categories,legend_data,'sift');

    panel.render_selection_details('variant','sift', 'SIFT', sift_count, sift_details, 'Residues;Score', legend, 1);
  },

  // Parse AJAX results for the overlapping PolyPhen variant data and display them on the right hand side menu
  parse_polyphen_results: function(data) {
    var panel = this;

    data.sort(function(a,b) {
      return a.start - b.start;
    });

    var polyphen_details = '';
    var polyphen_count   = 0;

    var polyphen_sg = {
          'score_good'    : 'polyphen_1_sg',
          'score_ok'      : 'polyphen_2_sg',
          'score_bad'     : 'polyphen_3_sg',
          'score_neutral' : 'polyphen_4_sg'
       };

    var polyphen_categories = {};

    // Prepare the list of PolyPhen data to be displayed on the right hand side menu
    $.each(data,function (index, result) {
      if (result.polyphen) {

        var var_pdb_coords = panel.ensp_to_pdb_coords(result.start, result.end);
        if (var_pdb_coords.length == 0) {
          return true;
        }
        var var_pdb_label_coords = panel.ensp_to_pdb_coords(result.start,result.end,1);

        var var_pdb_start = var_pdb_coords[0];
        var var_pdb_end   = var_pdb_coords[1];
        var var_label_pdb_start = var_pdb_label_coords[0];
        var var_label_pdb_end   = var_pdb_label_coords[1];

        var var_pdb  = (var_pdb_start == var_pdb_end) ? var_label_pdb_start : var_label_pdb_start+'-'+var_label_pdb_end;
        var var_ensp = (result.start == result.end) ? result.start : result.start+'-'+result.end;

        var polyphen_score = result.polyphen;

        var polyphen_coords = var_pdb_start+','+var_pdb_end;

        var polyphen_residues = result.residues;
        if (polyphen_residues.length > 5) {
          var polyphen_residues_label = polyphen_residues.substr(0,2)+'...';
          polyphen_residues = '<span class="ht" title="'+polyphen_residues+'">'+polyphen_residues_label+'</span>';
        }

        // Colour
        var polyphen_class  = 'score_neutral';
        var polyphen_colour = 'blue'; 
        if (polyphen_score > 0.908) {
          polyphen_class  = 'score_bad';
          polyphen_colour = 'red';
        }
        else if (polyphen_score > 0.445 && polyphen_score <= 0.908) {
          polyphen_class  = 'score_ok';
          polyphen_colour = 'orange';
        }
        else if (polyphen_score <= 0.445) {
          polyphen_class  = 'score_good';
          polyphen_colour = 'green';
        }
       
        polyphen_categories[polyphen_class] = 1;

        var var_id = panel.add_var_link(result.id);

        polyphen_details += '<tr><td style="border-color:'+polyphen_colour+'">'+var_id+'</td><td>'+var_pdb+'</td><td>'+var_ensp+'</td>'+
          '<td>'+polyphen_residues+'</td><td><div class="score '+polyphen_class+'">'+polyphen_score+'</div></td>'+
          '<td><span class="pdb_feature_entry float_left view_disabled" id="polyphen_'+result.id+'_cb" data-value="'+polyphen_coords+'"'+
          ' data-group="polyphen_group" data-name="'+result.id+'" data-colour="'+polyphen_colour+'" data-sg="'+polyphen_sg[polyphen_class]+'"></span></td></tr>';
        
        polyphen_count++;
      }
    });

    // Legend
    var legend_data = [
      { 'score_good'    : { 'id': polyphen_sg['score_good'],    'class' : 'score_bg_good',    'label' : 'Benign',            'title' : 'Less than or equal to 0.446' } },
      { 'score_ok'      : { 'id': polyphen_sg['score_ok'],      'class' : 'score_bg_ok',      'label' : 'Possibly Damaging', 'title' : 'Greater than 0.446 and less than or equal to 0.908' } },
      { 'score_bad'     : { 'id': polyphen_sg['score_bad'],     'class' : 'score_bg_bad',     'label' : 'Probably Damaging', 'title' : 'Greater than 0.908' } },
      { 'score_neutral' : { 'id': polyphen_sg['score_neutral'], 'class' : 'score_bg_neutral', 'label' : 'Unknown',           'title' : 'Unknown' } }
    ];
    var legend = panel.build_legend(polyphen_categories,legend_data,'polyphen');

    panel.render_selection_details('variant','polyphen', 'PolyPhen', polyphen_count, polyphen_details, 'Residues;Score', legend, 1);
  },


  // Generic rendering of the data on the right hand side menu
  render_selection_details: function (category,type,type_label,type_count,details,extra_col,legend,has_subgroup) {
    var panel = this;

    var cat_id    = category+'_block';
    var td_label  = type+'_label';
    var row_id    = type+'_row';
    var cb_group  = type+'_group';
    var sg_flag   = (has_subgroup) ? ' data-has-sg="1"' : '';

    var label_id     = type+'_details';
    var label_id_div = label_id+'_div';

    
    extra_col = (extra_col) ? '<th>'+extra_col.replace(';','</th><th>')+'</th>' : '';
    view_col  = '<th></th>';

    legend = (legend) ? legend : '';

    if (type_count) {

      var label;
      if ($('#'+td_label).length) {
        label = $('#'+td_label);
      }
      else {
        label = $('<div></div>');
        label.attr('id', td_label);
      }
      var entry_scalar  = (type_count > 1) ? 'ies' : 'y';
      var overlap_label = (type_count > 1) ? '' : 's';
      label.html(
        '<div>'+
        '  <h3 class="float_left">'+type_label+'</h3>'+
        '  <div class="float_right view_toggle view_toggle_btn closed" rel="'+label_id+'"></div>'+
        '  <div class="float_right pdb_feature_group view_disabled" title="Click to highlight / hide '+type_label+' on the 3D viewer" id="'+cb_group+'"'+sg_flag+'></div>'+
        '  <div class="float_right view_badge" title="'+type_count+' '+type_label+' entr'+entry_scalar+' overlap'+overlap_label+' this PDB model">'+type_count+'</div>'+
        '  <div style="clear:both"></div>'+
        '</div>'+
        '<div class="'+label_id+'">'+
        '  <div id="'+label_id_div+'" class="pdb_features_container toggleable" style="padding-top:5px;display:none">'+legend+
        '    <table class="pdb_features"><thead><tr>'+panel.details_header+extra_col+view_col+'</tr></thead><tbody>'+details+'</tbody></table>'+
        '  </div>'+
        '</div>');

      if (!$('#'+row_id).length) {
        var row = $('<div></div>');
            row.attr('id', row_id);;
            row.append(label);
        $('#'+cat_id).append(row);
      }
    }
    else if ($('#'+row_id).length) {
      $('#'+row_id).remove();
    }
    $('._ht').helptip();
  },


  // Build legend on the right hand side menu
  build_legend : function(type_list,legend_data,data_type) {

    var legend_content = '';
    var type_count = type_list.length;
    var count = 0;
    $.each(legend_data, function(i,legend_item) {
      $.each(legend_item, function(type,data) {
        if (type_list[type]) {
          count++;
          var margin = (count == type_count) ? '' : ' style="margin-right:10px"';
          var view_title = 'Click to highlight / hide '+data['label']+' '+data_type+' Variant';
          legend_content += '  <div class="float_left"'+margin+'>'+
                            '    <div class="float_left _ht score_legend_left '+data['class']+'" title="'+data['title']+'">'+data['label']+'</div>'+
                            '    <div class="float_left score_legend_right">'+
                            '      <div class="pdb_feature_subgroup view_disabled" title="'+view_title+'" id="'+data['id']+'" data-super-group="'+data_type+'_group"></div>'+
                            '    </div>'+
                            '    <div style="clear:both"></div>'+
                            '  </div>';
        }
      });
    });

    if (legend_content == '') {
      return undefined;
    }

    var legend = '<div class="pdb_legend">'+
                 legend_content+ 
                 '  <div style="clear:both"></div>'+
                 '</div>';

    return legend;
  },


  // Convert ENSP position into PDBe postion
  ensp_to_pdb_coords: function(start_res, end_res, use_author) {
    var panel = this;

    start_res = Number(start_res);
    end_res   = Number(end_res);

    var pdb_res_start;
    var pdb_res_end;

    var pdb_start_coord = panel.pdb_start;
    var pdb_end_coord   = panel.pdb_end;

    if ((start_res < pdb_start_coord && end_res < pdb_start_coord) ||
        (start_res > pdb_end_coord && end_res > pdb_end_coord)) {
      return [];
    }

    var pdb_hit_start_coord = (use_author) ? panel.pdb_author_start : panel.pdb_hit_start;

    // Convert to PDB coordinates
    var coords_shift = pdb_hit_start_coord - panel.pdb_start;

    if (start_res < pdb_start_coord && end_res > pdb_start_coord) {
      pdb_res_start = pdb_start_coord + coords_shift;
    }

    if (end_res > pdb_end_coord && start_res < pdb_end_coord) {
      pdb_res_end = pdb_end_coord + coords_shift;
    }

    // Convert to PDB coordinates (will need to be fixed properly)
    if (!pdb_res_start) {
      pdb_res_start = start_res + coords_shift;
    }
    if (!pdb_res_end) {
      pdb_res_end = end_res + coords_shift;
    }

    if (pdb_res_start < pdb_hit_start_coord) {
      pdb_res_start = pdb_hit_start_coord;
    }

    return [pdb_res_start,pdb_res_end];
  },

  

  //-----------------------//
  //  Colouration methods  //
  //-----------------------//

  // Method used to create a colour in a range 
  sin_to_hex: function(i, phase, size) {
    var sin = Math.sin(Math.PI / size * 2 * i + phase);
    var intg = Math.floor(sin * 127) + 128;
    var hexa = intg.toString(16);

    return hexa.length === 1 ? "0"+hexa : hexa;
  },
  // Method used to create a colour gradient
  get_hexa_colour: function(index, size) {
    var panel = this;

    var red   = panel.sin_to_hex(index, 0 * Math.PI * 2/3, size); // 0   deg
    var blue  = panel.sin_to_hex(index, 1 * Math.PI * 2/3, size); // 120 deg
    var green = panel.sin_to_hex(index, 2 * Math.PI * 2/3, size); // 240 deg

    var hexa_colour = "#"+ red + green + blue
    panel.add_colour(hexa_colour);

    return hexa_colour;
  },
  // Add colour to the list of available highlighting colours
  add_colour: function(hexa) {
    var panel = this;

    if (!panel.hexa_to_rgb[hexa]) {

      var h=hexa.replace('#', '');
      var bigint = parseInt(h, 16);
      var r_colour = (bigint >> 16) & 255;
      var g_colour = (bigint >> 8) & 255;
      var b_colour = bigint & 255;

      panel.hexa_to_rgb[hexa] = {r:r_colour, g:g_colour, b:b_colour};
    }
  },



  //-------------------//
  //  Generic methods  //
  //-------------------//

  isOdd: function(num) { return num % 2;},

  // Function to retrieve the searched term 
  getParameterByName: function(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
    results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
  },
  showMsg: function(message) { 
    var msg = message ? message : 'Sorry, we are currently unable to get the data to display this view. Please try again later.';
    $('#ensp_pdb').html('<span class="left-margin right-margin">'+msg+'</span>');
    $('#ensp_pdb').show();  
  },
  showNoData: function(message) {
    if (!message) { message = 'No data available'; }
    this.showMsg(message);
  },
  addSpinner: function() {
    $('#pdb_msg').addClass('spinner');
  },
  removeSpinner: function() {
    $('#pdb_msg').removeClass('spinner');
  }
});

