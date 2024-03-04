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

Ensembl.Panel.VRForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base();

    this.resetSpecies(this.defaultSpecies);

    this.exampleData = this.params['example_data'];
    delete this.params['example_data'];

    var panel = this;

    // Change the input value on click of the examples link
    this.elLk.form.find('a._example_input').on('click', function(e) {
      e.preventDefault();

      var species = panel.elLk.form.find('input[name=species]:checked').val() || panel.elLk.form.find('input[name=species]').val();
      var text    = panel.exampleData[species][this.rel];
      if (typeof text === 'undefined' || !text.length) {
        text = '';
      }
      text = text.replace(/\\n/g, "\n");

      panel.elLk.dataField.val(text).trigger('focus');
    });

    // show hide preview button acc to the text in the input field
    this.elLk.dataField = this.elLk.form.find('textarea[name=text]').on({
      'paste keyup click change focus scroll': function(e) {
        panel.dataFieldInteraction(e.type);
      }
    });

    this.editExisting();

    // initialise the selectToToggle fields ie. show or hide the ones as needed
    this.resetSelectToToggle();
  },

   dataFieldInteraction: function(eventType) {
   /*
   * Acts according to the event occurred on the textare input
   */
    var panel = this;
    var value = this.elLk.dataField[0].value;
    var bgPos = Ensembl.browser.webkit ? 13 : 15;

    this.elLk.dataField.removeClass('focused');

    if (!this.dataFieldHeight) {
      this.dataFieldHeight = this.elLk.dataField.height();
    }
  },

  populateForm: function(jobsData) {
  /*
   * Populates the form according to the provided ticket data
   */
    if (jobsData && jobsData.length) {
      jobsData = $.extend({}, jobsData[0].config, jobsData[0]);
      this.base([jobsData]);

      if (jobsData['input_file_type']) {
        this.elLk.form.find('input[name=file]').parent().append('<p class="_download_link">' + ( jobsData['input_file_type'] === 'text'
          ? 'Click <a href="' + jobsData['input_file_url'] + '">here</a> to download the previously uploaded file.'
          : 'You previously uploaded a compressed file to run this job.'
        ) + '</p>');
      }

      this.resetSpecies(jobsData['species']);

      this.elLk.dataField.trigger('change');

      // Keep values unchecked
      if(this.elLk.form.find('input[name=id]').length && !jobsData.id){
        this.elLk.form.find('input[name=id]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=hgvsg]').length && !jobsData.hgvsg){
        this.elLk.form.find('input[name=hgvsg]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=hgvsc]').length && !jobsData.hgvsc){
        this.elLk.form.find('input[name=hgvsc]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=hgvsp]').length && !jobsData.hgvsp){
        this.elLk.form.find('input[name=hgvsp]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=spdi]').length && !jobsData.spdi){
        this.elLk.form.find('input[name=spdi]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=vcf_string]').length && !jobsData.vcf_string){
        this.elLk.form.find('input[name=vcf_string]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=var_synonyms]').length && !jobsData.var_synonyms){
        this.elLk.form.find('input[name=var_synonyms]').prop('checked',false);
      }
      if(this.elLk.form.find('input[name=mane_select]').length && !jobsData.mane_select){
        this.elLk.form.find('input[name=mane_select]').prop('checked',false);
      }

    }
  },

   reset: function() {
   /*
   * Resets the form, ready to accept next job input
   */
    this.base.apply(this, arguments);
    this.elLk.form.find('._download_link').remove();
    this.elLk.dataField.removeClass('focused');
    this.resetSpecies(this.defaultSpecies);
    this.resetSelectToToggle();
  },

  resetSpecies: function (species) {
    /*
     * Resets the species selector to select the given species
     */
      var items = [];
      items.push({
          key: species,
          title: species
      });
      Ensembl.EventManager.deferTrigger('updateTaxonSelection', items);
    }
});
