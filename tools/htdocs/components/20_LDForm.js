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

Ensembl.Panel.LDForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base();

    this.resetSpecies(this.defaultSpecies);

    this.exampleData = this.params['example_data'];
    delete this.params['example_data'];

    var panel = this;

    // show hide preview button acc to the text in the input field
    this.elLk.dataField = this.elLk.form.find('textarea[name=text]').on({
      'paste keyup click change focus scroll': function(e) {
        panel.dataFieldInteraction(e.type);
      }
    });

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

    this.elLk.form.find('.plugin_enable').change(function() {
      panel.elLk.form.find('.plugin-highlight').removeClass('plugin-highlight');

      // find any sub-fields enabling this plugin shows
      panel.elLk.form.find('._stt_' + this.name).addClass('plugin-highlight', 100, 'linear');
    });

    // also remove highlighting when option changes
    this.elLk.form.find('.plugin_enable').each(function() {
      panel.elLk.form.find('._stt_' + this.name).find(':input').change(function() {
        panel.elLk.form.find('.plugin-highlight').removeClass('plugin-highlight');
      });
    });

    this.editExisting();

    // initialise the selectToToggle fields ie. show or hide the ones as needed
    this.resetSelectToToggle();
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

      if (!this.elLk.speciesDropdown.find('input:checked').length) {
        this.elLk.speciesDropdown.find('input[type=radio]').first().click();
      }

      this.resetSpecies(jobsData['species']);

      this.elLk.dataField.trigger('change');
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
   * Resets the species dropdown to select the given species or simply refresh the dropdown
   */
    if (!this.elLk.speciesDropdown) {
      this.elLk.speciesDropdown = this.elLk.form.find('._sdd');
    }

    this.elLk.speciesDropdown.find('input[value=' + species + ']').first().click();
    this.elLk.speciesDropdown.speciesDropdown({refresh: true});
  }
});