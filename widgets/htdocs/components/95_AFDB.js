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
    var panel = this;
    this.base.apply(this, arguments);
    panel.addSpinner(); // FIXME

    this.initializeMolstarPlugin();


    // use something like this: http://codon-login-01.ebi.ac.uk:3000/overlap/translation/AT5G48485.1?feature=protein_feature
  },

  initializeMolstarPlugin() {
    this.molstarInstance = new PDBeMolstarPlugin();
    this.testMolstar();
  },

  testMolstar() {
    var container = document.createElement('div');
    container.style.width = '800px';
    container.style.height = '600px';
    container.style.position = 'relative';
    this.el.append(container);

    var options = {
      customData: {
        url: 'https://alphafold.ebi.ac.uk/files/AF-O15552-F1-model_v1.cif',
        format: 'cif'
      },
      bgColor: {r:255, g:255, b:255},
      isAfView: true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo']
    };

    this.molstarInstance.render(container, options);
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

