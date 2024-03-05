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

Ensembl.Panel.IDMapperForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base.apply(this, arguments);

    this.elLk.speciesDropdown = this.elLk.form.find('._sdd');

    this.resetSpecies(this.defaultSpecies);
    this.editExisting();
  },

  reset: function() {
    this.base.apply(this, arguments);
    this.resetSpecies(this.defaultSpecies);
    this.elLk.form.find('._previous_file').remove();
  },

  populateForm: function(jobsData) {
    if (jobsData && jobsData.length) {
      this.base(jobsData);
      this.resetSpecies(jobsData[0]['species']);
      if (jobsData[0].file) {
        this.elLk.form.find('input[name=file]').parent().append($('<p class="_previous_file">').html('You previously uploaded a file named ' + jobsData[0].file + ' to run this job.'));
      }
    }
  },

  resetSpecies: function (species) {
  /*
   * Resets the species dropdown to select the given species or simply refresh the dropdown
   */
    this.elLk.speciesDropdown.find('input[value="' + species + '"]').first().click();
    this.elLk.speciesDropdown.speciesDropdown({refresh: true});
  }
});
