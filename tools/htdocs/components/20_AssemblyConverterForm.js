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

Ensembl.Panel.AssemblyConverterForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base.apply(this, arguments);

    this.elLk.speciesDropdown = this.elLk.form.find('select[name=species]');

    this.editExisting();
    this.resetSpecies();
  },

  populateForm: function(jobsData) {
  /*
   * Populates the form according to the provided ticket data
   */
    if (jobsData && jobsData.length) {
      this.base(jobsData);

      if (jobsData[0]['input_file_type']) {
        this.elLk.form.find('input[name=file]').parent().append('<p class="_download_link">' + ( jobsData[0]['input_file_type'] === 'text'
          ? 'Click <a href="' + jobsData[0]['input_file_url'] + '">here</a> to download the previously uploaded file.'
          : 'You previously uploaded a compressed file to run this job.'
        ) + '</p>');
      }
      if (jobsData[0]['mapping']) {
        this.elLk.form.find('select[name=mappings_for_'+jobsData[0]['species']+']').find('option[value=' + jobsData[0]['mapping'] + ']').prop('selected', true);
      }
    }
  },

  reset: function() {
    this.base.apply(this, arguments);
    this.resetSpecies();
    this.elLk.form.find('._download_link').remove();
  },

  resetSpecies: function () {
    this.elLk.speciesDropdown.find('option[value=' + this.defaultSpecies + ']').prop('selected', true).end().selectToToggle('trigger');
  }
});
