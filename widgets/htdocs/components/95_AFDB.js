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

  init: function() {
    this.base.apply(this, arguments);
    this.loadScript();
  },

  loadScript: function () {
    this.addSpinner();

    var script = document.createElement('script');
    script.setAttribute('src', '/alphafold/index.js'); // <-- all fun is happening here
    script.setAttribute('type', 'module');
    script.onload = this.onScriptLoaded.bind(this);
    script.onerror = function () { console.log('error') }; // FIXME?
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
    ensemblAlphafoldElement.setAttribute('data-species', Ensembl.species);
    ensemblAlphafoldElement.setAttribute('data-rest-url-root', rest_url_root);
    ensemblAlphafoldElement.setAttribute('data-afdb-url-root', afdb_url_root); // FIXME: delete
    ensemblAlphafoldElement.setAttribute('data-ensp-id', enspIdElement.value);
    ensemblAlphafoldElement.style.visibility = 'hidden';
    ensemblAlphafoldElement.addEventListener('loaded', this.onWidgetReady.bind(this));
    container.appendChild(ensemblAlphafoldElement);
  },

  onWidgetReady: function () {
    this.removeSpinner();
    const ensemblAlphafoldElement = document.querySelector('ensembl-alphafold-viewer');
    ensemblAlphafoldElement.style.visibility = 'visible';
  },

  //-------------------//
  //  Generic methods  //
  //-------------------//

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
