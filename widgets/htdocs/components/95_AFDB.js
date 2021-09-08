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

Ensembl.Panel.AFDB = Ensembl.Panel.Content.extend({

  /**
   * See Molstar usage examples:
   * - As a plugin on Plunkr: https://embed.plnkr.co/plunk/WlRx73uuGA9EJbpn
   * - Helper documentation: https://github.com/PDBeurope/pdbe-molstar/wiki
   *    - for use as a separate JS instance: https://github.com/PDBeurope/pdbe-molstar/wiki/1.-PDBe-Molstar-as-JS-plugin
   *    - for use as a web component: https://github.com/PDBeurope/pdbe-molstar/wiki/2.-PDBe-Molstar-as-Web-component
   */

  init: function() {
    this.base.apply(this, arguments);
    // this.setInitialValues();
    // this.initializeMolstar();

    // this.fetchAlphaFoldId();
    // this.fetchExons();
    // this.fetchSiftAndPolyphen();

    this.tryScript();



    // this.details_header = '<th>ID</th>'+
    //                       '<th class="location _ht" title="Position in the selected AFDB model"><span>AFDB</span></th>'+
    //                       '<th class="location _ht" title="Position in the selected Ensembl protein"><span>ENSP</span></th>';

  },

  tryScript: function () {
    var script = document.createElement('script');
    script.setAttribute('src', '/alphafold/index.js');
    script.setAttribute('type', 'module');
    script.onload = this.onScriptLoaded.bind(this);
    script.onerror = function () { console.log('error') };
    document.body.appendChild(script);
  },

  onScriptLoaded: function() {
    //this.rest_url_root       = this.params['ensembl_rest_url'];
    rest_url_root       = 'http://codon-login-04.ebi.ac.uk:3000';
    afdb_url_root       = 'https://alphafold.ebi.ac.uk';

    var enspIdElement = document.querySelector('#ensp_id'); // <-- expecting 1 or 0 HTML input elements
    if (!enspIdElement) {
      // FIXME: show that the 3D model is not available
      return;
    }

    var container = document.querySelector('#alphafold_container');
    var ensemblAlphafoldElement = document.createElement('ensembl-alphafold-viewer');
    ensemblAlphafoldElement.setAttribute('data-rest-url-root', rest_url_root);
    ensemblAlphafoldElement.setAttribute('data-afdb-url-root', afdb_url_root); // FIXME: delete
    ensemblAlphafoldElement.setAttribute('data-ensp-id', enspIdElement.value);
    container.appendChild(ensemblAlphafoldElement);
  },

  setInitialValues: function () {
    this.species = Ensembl.species;

    // Retrieve Ensembl data through the REST API
    //this.rest_url_root       = this.params['ensembl_rest_url'];
    this.rest_url_root       = 'http://codon-login-04.ebi.ac.uk:3000';
    this.rest_pr_url         = this.rest_url_root+'/overlap/translation/';
    this.rest_lookup_url     = this.rest_url_root+'/lookup/id/';
    //this.afdb_url_root       = this.params['afdb_url'];
    this.afdb_url_root       = 'https://alphafold.ebi.ac.uk';



    // Initialise variables
    this.protein_features = {};

    this.ensp_list = [];
    this.ensp_afdb_list = {};
    this.ensp_length   = {};

    this.max_afdb_entries    = 10;

    this.afdb_unique_list = [];

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
    // this.afdb_id;
    // this.afdb_start;
    // this.afdb_end;
    // this.afdb_hit_start;
  },

  initializeMolstar: function () {
    this.molstarInstance = new PDBeMolstarPlugin();
  },

  renderMolstar: function () {
    var container = document.querySelector('#molstar_canvas');

    var options = {
      customData: {
        url: 'https://alphafold.ebi.ac.uk/files/'+this.afdb_id+'-model_v1.cif',
        format: 'cif'
      },
      bgColor: {r:255, g:255, b:255},
      isAfView: true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo']
    };

    this.molstarInstance.render(container, options);
  },

  showControls: function() {
    $('#molstar_buttons').show();
  },

  updateMolstar: function () {

  },

  fetchAlphaFoldId: function () {
    this.addSpinner(); // FIXME

    var enspIdElement = document.querySelector('#ensp_id'); // <-- expecting 1 or 0 HTML input elements
    if (!enspIdElement) {
      // FIXME: show that the 3D model is not available
      return;
    }

    this.ensp_id = enspIdElement.value;

    $.ajax({
      url: this.rest_pr_url + this.ensp_id + '?feature=protein_feature;type=alphafold',
      method: "GET",
      contentType: "application/json; charset=utf-8"
    })
      .done(function (data) {
        this.removeSpinner();

        // response is an array of overlapping features;
        // expect one item in the response to have a type of "alphafold"
        var alphaFoldData = data.find(function(item) {
          return item.type === 'alphafold';
        });

        if (!alphaFoldData) {
          // FIXME: consider what to do if there is no alphafold data
          return;
        }

        // Note that the alphafold id will end in the name of the chain (e.g. "AF-Q9S745-F1.A")
        // which has to be discarded when passed to Molstar
        this.afdb_id = alphaFoldData.id.split('.').shift();
        this.renderMolstar();
        this.showControls();

        console.log(">>>>> STEP 02: The AFDB id for ENSP ", this.ensp_id, " is: ", this.afdb_id);
      }.bind(this))
      .fail(function (xhRequest, ErrorText, thrownError) {
        console.log('ErrorText: ' + ErrorText + "\n");
        console.log('thrownError: ' + thrownError + "\n");
      });
  },

  fetchExons: function () {
    $.ajax({
      url: this.rest_pr_url + this.ensp_id + '?feature=translation_exon',
      method: "GET",
      contentType: "application/json",
      success: function (data) {
        console.log("  >>> STEP 13a: Get Exon data (get_exon_data) - done");
        this.renderExons(data);
      }.bind(this),
      error: function (xhRequest, ErrorText, thrownError) {
        console.log('ErrorText: ' + ErrorText + "\n");
        console.log('thrownError: ' + thrownError + "\n");
      }
    });
  },

  fetchSiftAndPolyphen: function () {
    $.ajax({
      url: this.rest_pr_url+this.ensp_id+'?feature=transcript_variation',
      method: "GET",
      contentType: "application/json; charset=utf-8"
    })
    .done(function (data) {
      console.log(data);
      // panel.parse_sift_results(data);
      // panel.parse_polyphen_results(data);
    })
    .fail(function (xhRequest, ErrorText, thrownError) {
      console.log('ErrorText: ' + ErrorText + "\n");
      console.log('thrownError: ' + thrownError + "\n");
    });

  },

  renderExons: function(exons) {
    exons.sort(function(exonA, exonB) {
      return exonA.rank - exonB.rank;
    });
    // last exon's end position includes a stop codon; exclude it
    exons[exons.length - 1].end -= 1;

    var exonRows = exons.map(function(exon, index) {
      var exonLabel = 'Exon ' + (index + 1);
      var hexaColour = this.get_hexa_colour(index + 1, index + 1);
      return '<tr>' +
          '<td style="border-color:'+hexaColour+'">' + exonLabel + '</td>' +
          '<td>' + exon.start + '-' + exon.end + '</td>' +
          '<td>' +
            '<span class="view_disabled js_exon" data-start="'+exon.start+'"'+' data-end="'+exon.end+'" data-colour="'+hexaColour+'"></span>' + 
          '</td>' +
        '</tr>';
    }.bind(this)).join('');

    var exonsContainer = document.querySelector('#exon_block');
    exonsContainer.innerHTML = exonRows;

    exonsContainer.addEventListener('click', function (event) {
      if (event.target.classList.contains('js_exon')) {
        var exonElement = event.target;
        var exonStart = exonElement.dataset.start;
        var exonEnd = exonElement.dataset.end;

        console.log('exonStart', exonStart, 'exonEnd', exonEnd);

        this.molstarInstance.visual.select({
          data: [{ struct_asym_id: 'A', start_residue_number: exonStart, end_residue_number: exonEnd }],
          nonSelectedColor: { r:255, g:255, b:255 }
        });
        // var exonStart = exonElement.
      }
    }.bind(this));
  },




  // Method to fetch all the ENSP=AFDB mappings from the Ensembl database
  // get_all_afdb_list: function() {
  //   var panel = this;
  //   console.log(">>>>> STEP 01: Get all the AFDB lists (get_all_afdb_list) - start");
  //   $('#afdb_list_label').hide();
  //   $('#afdb_list').hide();
  //   $('#right_form').addClass('loader_small');

  //   var afdb_list_calls   = [];

  //   // Get the list of mapped AFDB entries for each ENSP (from Ensembl 'protein_features' DB table, throught the REST API)
  //   $.each(panel.ensp_list, function(i,ensp) {
  //     afdb_list_calls.push(panel.get_afdb_by_ensp(ensp));
  //   });

  //   // Waiting that the search of AFDB entries for each ENSP has been done, using a list of promises,
  //   // so it can returns an error message if no mappings at all have been found
  //   $.when.apply(undefined, afdb_list_calls).then(function(results){
  //     var afdb_unique_list = [];
  //     $.each(panel.ensp_list, function(i,ensp) {
  //       // Extract list of AFDB IDs
  //       if (panel.protein_features[ensp]['alphafold'] && panel.protein_features[ensp]['alphafold'].length !=0) {

  //         // Loop over the AFDB models for a given ENSP
  //         $.each(panel.protein_features[ensp]['alphafold'],function (index, result) {
  //           var afdb_acc = result.id.split('.');
  //           var afdb_id = afdb_acc[0];
  //           if ($.inArray(afdb_id,afdb_unique_list) == -1) {
  //             // If variant page, check that the AFDB model(s) overlap the variant
  //               // Setup ensp_id if none has been assigned
  //               if (panel.ensp_id == undefined) {
  //                  panel.ensp_id = ensp;
  //               }
  //               // Add AFDB model to the list;
  //               afdb_unique_list.push(afdb_id);
  //           }
  //         });
  //       }
  //     });

  //     // Add additional information for each AFDB model
  //     if (afdb_unique_list.length > 0) {
  //       panel.get_afdb_extra_data(afdb_unique_list);
  //     }
  //     // No AFDB mapping retained
  //   });
  // },

  // Extract the list of mapped AFDB model for all the ENSP
  // and then fetch extra information about these AFDB models (through the AFDB REST API)
  // get_afdb_extra_data: function(afdb_list) {
  //   var panel = this;

  //   $.each(panel.ensp_list, function(index, ensp) {
  //     // Build AFDB objects and reduce the number of AFDB models if the list is too long (e.g. > 10 AFDB models per ENSP)
  //     panel.parse_afdb_results(ensp);
  //   });

  //   // Waiting that the AFDB author positions are fetched for each AFDB model, using a list of promises,
  //   // and then it finalise the list of AFDB models for the given ENSP
  //   console.log("  >>> STEP 08c: AFDB author coordinates (get_afdb_author_pos) - done");
  //   panel.finish_parse_afdb_results();

  // },

  // Finish the list of AFDB list to display:
  // - Add the ENSP selection and display its corresponding AFDB list
  // finish_parse_afdb_results: function() {
  //   var panel = this;

  //   console.log("  >>> STEP 09a: Start parse AFDBs results (finish_parse_afdb_results)");

  //   $.each(panel.ensp_afdb_list, function(ensp, afdb_entries) {

  //     // Display ENSP entry in the ENSP selection dropdown if there are some AFDB models to display
  //     if (Object.keys(panel.ensp_afdb_list[ensp]).length > 0) {
  //       var ensp_option = { 'value' : ensp, 'text' : ensp };
  //       if (ensp == panel.ensp_id) {
  //         ensp_option['selected'] = 'selected';
  //         // Display the list of AFDB entries in the selection dropdown
  //         panel.display_afdb_list(ensp);
  //       }
  //       $('#ensp_list').append($('<option>', ensp_option));
  //     }
  //   });

  //   console.log("  >>> STEP 09b: Finish parse AFDBs results (finish_parse_afdb_results) - done");
  // },


  // Display the dropdown selector for the AFDB models
  // display_afdb_list: function(ensp) {
  //   var panel = this;

  //   panel.removeSpinner();

  //   if ($.isEmptyObject(panel.ensp_afdb_list) || !panel.ensp_afdb_list[ensp]) {
  //     panel.showNoData();
  //   }
  //   else {

  //     // Retrieve the list of AFDB entries for this ENSP
  //     var afdb_objs = panel.ensp_afdb_list[ensp];
  //     var afdb_objs_length = afdb_objs.length;

  //     $('#right_form').removeClass('loader_small');
  //     $('#afdb_list_label').hide();
  //     $('#afdb_list').hide();
  //     $('#afdb_list').html('');

  //     var selected_afdb;
  //     var show_afdb_list = 0;
  //     var first_afdb_entry = 1;

  //     // Makes sure the length of the ENSP is returned before populating the list of AFDBe entries
  //     // The Ensembl REST call is made at the beginning of the script
  //     var counter = 0;
  //     $('#afdb_list').html('');

  //     // Add AFDB models to the dropdomn list
  //     $.each(afdb_objs, function (i, afdb_obj) {
  //       var afdb_mapping_length = afdb_obj.end - afdb_obj.start + 1;
  //       var ensp_afdb_percent  = (afdb_mapping_length/panel.ensp_length[ensp])*100;
  //       var ensp_afdb_coverage = Math.round(ensp_afdb_percent);

  //       // List the different molecule names (should be equal to one)
  //       var afdb_coord = " - Coverage: [ AFDB: "+afdb_obj.author_start+"-"+afdb_obj.author_end+" | ENSP: "+afdb_obj.start+"-"+afdb_obj.end+" ] => "+ensp_afdb_coverage+"% of ENSP length";
  //       var afdb_option = {
  //         'value'           : afdb_obj.id,
  //         'data-start'      : afdb_obj.start,
  //         'data-end'        : afdb_obj.end,
  //         'data-hit-start'  : afdb_obj.hit_start,
  //         'data-chain'      : afdb_obj.chain,
  //         'text'            : afdb_obj.id + afdb_coord
  //       };
  //       afdb_option['data-hit-end'] = afdb_obj.hit_end;

  //       // Automatically select the first AFDB entry in the list
  //       if (first_afdb_entry == 1 || afdb_objs_length == 1) {
  //         afdb_option['selected'] = 'selected';
  //         selected_afdb = afdb_obj.id;
  //         first_afdb_entry = 0;
  //       }
  //       $('#afdb_list').append($('<option>', afdb_option));
  //       show_afdb_list = 1;
  //     });

  //     // Display AFDB list dropdown
  //     if (show_afdb_list) {
  //       $('#afdb_list_label').show();
  //       $('#afdb_list').show();
  //       panel.selectAFDBEntry(selected_afdb);
  //     }
  //     else {
  //       panel.showNoData();
  //     }
  //   }
  //   $('#ensp_afdb').show();
  // },

  // Select "best" AFDB entries and store all the information needed into an array of Objects
  // parse_afdb_results: function(ensp) {
  //   var panel = this;

  //   panel.removeSpinner();

  //   var afdb_list   = [];
  //   var afdb_objs   = [];

  //   var protein_features = panel.protein_features[ensp]['alphafold'];

  //   // Prepare AFDB list with the added data (quality and structure)
  //   $.each(protein_features,function (index, result) {
  //     var afdb_acc = result.id.split('.');
  //     var afdb_id = afdb_acc[0];
  //     // Create object with AFDB extra data
  //     if ($.inArray(afdb_id,afdb_list) == -1) {
  //       var afdb_size = result.end - result.start + 1;

  //       // Build a AFDB object
  //       // Example for the mapping ENSP00000231061 - 1BMO:
  //       // { id: "1bmo", start: 71, end: 303, chain: ['A','B'], size: 233, hit_start: 1, hit_end: 233, author_start: 54, author_end: 286, overall_quality: 9.64 }
  //       afdb_objs.push(
  //         {
  //           id: afdb_id,
  //           start: result.start,
  //           end: result.end,
  //           size: afdb_size,
  //           hit_start: result.hit_start,
  //           hit_end: result.hit_end,
  //           author_start: undefined,
  //           author_end: undefined,
  //         }
  //       );
  //       afdb_list.push(afdb_id);
  //     }
  //   });

  //   // Only select "best" models by default
  //   if (afdb_objs && afdb_objs.length != 0) {
  //     afdb_objs.sort(function(a,b) {
  //       return b.size - a.size || b.overall_quality - a.overall_quality;
  //     });
  //     // Only get the best models (see max_afdb_entries)
  //     panel.ensp_afdb_list[ensp] = afdb_objs.slice(0, panel.max_afdb_entries);
  //   }
  // },


  // Select the AFDB entry, setup display and launch 3D model
  // selectAFDBEntry: function(afdb_id) {
  //   var panel = this;
  //   console.log(">>>>> STEP 10: Select AFDB entry (selectAFDBEntry) - start with "+afdb_id);

  //   // Extracting AFDB data and store it in panel
  //   if (afdb_id) {
  //     var sel = $('#afdb_list').find('option:selected');

  //     // Store information about selected AFDB model in module variables
  //     panel.afdb_id           = afdb_id;
  //     panel.afdb_start        = Number(sel.attr('data-start'));
  //     panel.afdb_end          = Number(sel.attr('data-end'));
  //     panel.afdb_hit_start    = Number(sel.attr('data-hit-start'));
  //     console.log("    # AFDB coords of "+afdb_id+" (on ENSP): "+panel.afdb_start+'-'+panel.afdb_end);

  //     // Display selected ENSP ID and AFDB model ID in page
  //     $('#mapping_top_ensp').html('Ensembl protein: <a href="/'+panel.species+'/Transcript/Summary?t='+panel.ensp_id+'">'+panel.ensp_id+'</a>');
  //     $('#mapping_top_afdb').html('AFDB model: '+afdb_id.toUpperCase());

  //     $('#mapping_ensp').html(panel.ensp_id);
  //     $('#mapping_afdb').html(afdb_id.toUpperCase());

  //     console.log("  >>> STEP 11b: Select AFDB entry (selectAFDBEntry) - done");

  //     this.initializeMolstarPlugin();
  //     $('#molstar_buttons').show();

  //     }
  //   },


  // Get the ENSP length - unfortunately this has to be done on a different REST endpoint
//   get_ens_protein_length: function() {
//     var panel = this;
// console.log("Retrieving info from "+panel.rest_lookup_url+ " with " + panel.ensp_list);
//     return $.ajax({
//       type: "POST",
//       url: panel.rest_lookup_url,
//       data: '{ "ids" : ["'+panel.ensp_list.join('","')+'"], "db_type" : "core" }',
//       dataType: "json",
//       contentType: 'application/json; charset=utf-8'
//       })
//       .done(function (data) {
//         $.each(data, function(ensp, ensp_info) {
//           panel.ensp_length[ensp] = ensp_info.length;
//         });
//         console.log(">>>>> STEP 01: Get ENSP length (get_ens_protein_length) - done");
//       })
//       .fail(function (xhRequest, ErrorText, thrownError) {
//         console.log('ErrorText: ' + ErrorText + "\n");
//         console.log('thrownError: ' + thrownError + "\n");
//         panel.removeSpinner();
//         panel.showMsg();
//       });
//   },

//   // Build legend on the right hand side menu
//   build_legend : function(type_list,legend_data,data_type) {

//     var legend_content = '';
//     var type_count = type_list.length;
//     var count = 0;
//     $.each(legend_data, function(i,legend_item) {
//       $.each(legend_item, function(type,data) {
//         if (type_list[type]) {
//           count++;
//           var margin = (count == type_count) ? '' : ' style="margin-right:10px"';
//           var view_title = 'Click to highlight / hide '+data['label']+' '+data_type+' Variant';
//           legend_content += '  <div class="float_left"'+margin+'>'+
//                             '    <div class="float_left _ht score_legend_left '+data['class']+'" title="'+data['title']+'">'+data['label']+'</div>'+
//                             '    <div class="float_left score_legend_right">'+
//                             '      <div class="afdb_feature_subgroup view_disabled" title="'+view_title+'" id="'+data['id']+'" data-super-group="'+data_type+'_group"></div>'+
//                             '    </div>'+
//                             '    <div style="clear:both"></div>'+
//                             '  </div>';
//         }
//       });
//     });

//     if (legend_content == '') {
//       return undefined;
//     }

//     var legend = '<div class="afdb_legend">'+
//                  legend_content+
//                  '  <div style="clear:both"></div>'+
//                  '</div>';

//     return legend;
//   },

  // Get list of AFDB models and other protein annotations mapped to the ENSP
  // get_afdb_by_ensp: function(ensp) {
  //   var panel = this;
  //   panel.protein_features[ensp] = { 'alphafold' : [] };

  //   return $.ajax({
  //     url: panel.rest_pr_url+ensp+'?feature=protein_feature;type=alphafold',
  //     method: "GET",
  //     contentType: "application/json; charset=utf-8"
  //   })
  //   .done(function (data) {
  //     $.each(data, function(index,item) {
  //       var type = item.type;
  //       var afdb_id = item.hseqname;
  //       panel.afdb_id = afdb_id;
  //       panel.protein_features[ensp][type].push(item);
  //     });

  //     console.log(">>>>> STEP 02: Get list of AFDBs by ENSP - "+ensp+" (get_afdb_by_ensp) - done and got "+panel.afdb_id);
  //   })
  //   .fail(function (xhRequest, ErrorText, thrownError) {
  //     console.log('ErrorText: ' + ErrorText + "\n");
  //     console.log('thrownError: ' + thrownError + "\n");
  //   });
  // },





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
    $('#ensp_afdb').html('<span class="left-margin right-margin">'+msg+'</span>');
    $('#ensp_afdb').show();
  },
  showNoData: function(message) {
    if (!message) { message = 'No data available'; }
    this.showMsg(message);
  },
  addSpinner: function() {
    $('#afdb_msg').addClass('spinner');
  },
  removeSpinner: function() {
    $('#afdb_msg').removeClass('spinner');
  }
});
