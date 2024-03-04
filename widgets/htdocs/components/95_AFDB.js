/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
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
    if (!this.areStaticImportsSupported()) {
      this.onUnsupportedBrowser();
      return;
    }

    this.addSpinner();

    var script = document.createElement('script');
    script.setAttribute('src', '/alphafold/index.js'); // <-- all the fun is happening here
    script.setAttribute('type', 'module');
    script.onload = this.onScriptLoaded.bind(this);
    script.onerror = this.onScriptLoadError.bind(this);
    document.body.appendChild(script);
  },

  onScriptLoaded: function() {
    var ensemblAlphafoldElement = [
      document.querySelector('ensembl-alphafold-protein'),
      document.querySelector('ensembl-alphafold-vep')
    ].filter(Boolean).pop(); // <-- a custom element will always be included in server response
    ensemblAlphafoldElement.addEventListener('loaded', function() {
      this.onWidgetReady(ensemblAlphafoldElement);
    }.bind(this));
    ensemblAlphafoldElement.addEventListener('load-error', this.onScriptLoadError.bind(this));
    ensemblAlphafoldElement.addEventListener('alphafold-model-missing', this.onAlphafoldModelMissing.bind(this));
  },

  onWidgetReady: function(element) {
    this.removeSpinner();
    element.style.visibility = 'visible';
  },

  onScriptLoadError: function() {
    var message = 'An error occurred while loading the 3D protein viewer';
    this.removeSpinner();
    this.showMsg(message);
  },

  onAlphafoldModelMissing: function() {
    var message = 'There is no Alphafold model for this molecule';
    this.removeSpinner();
    this.showMsg(message);
  },

  onUnsupportedBrowser: function() {
    var message = 'Sorry, it seems that the protein viewer is not supported by your browser. Try viewing this page in a recent version of Chrome, Firefox, Edge, or Safari.';
    this.showMsg(message);
  },

  areStaticImportsSupported: function () {
    var script = document.createElement('script');
    return 'noModule' in script; 
  },

  showMsg: function(message) {
    $('#afdb_msg').html('<span class="left-margin right-margin">'+message+'</span>');
  },

  addSpinner: function() {
    $('#afdb_msg').addClass('spinner');
  },

  removeSpinner: function() {
    $('#afdb_msg').removeClass('spinner');
  }

});
