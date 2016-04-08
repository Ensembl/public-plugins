/*
 * Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.FileChameleonForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    var panel = this;
    
    this.base.apply(this, arguments);

    this.elLk.speciesDropdown = this.elLk.form.find('._sdd');
    this.elLk.formatDropdown  = this.elLk.form.find('select[name=format]');
    this.elLk.chr_filter      = this.elLk.form.find('[name=chr_filter]');
    this.elLk.add_transcript  = this.elLk.form.find('[name=add_transcript]')
    this.elLk.remap_patch     = this.elLk.form.find('[name=remap_patch]')

    this.resetSpecies(this.defaultSpecies);
    this.editExisting();
    
    // Add validate event to the form which gets triggered before submitting it
    this.elLk.form.on('validate', function(e) {
      if (panel.elLk.form.find('input[name=url]').val() && !(panel.elLk.chr_filter.is(':checked')) && !(panel.elLk.add_transcript.is(':checked')) && !(panel.elLk.remap_patch.is(':checked'))) {
        panel.showError('Please choose one of the filter', 'No filter applied');
        $(this).data('valid', false);
        return;
      }
      if(panel.elLk.chr_filter.is(':checked') && panel.elLk.form.find('[name=convert_to]').val() === 'null') {
        panel.showError('Please choose chromosome format', 'No chromosome format conversion');
        $(this).data('valid', false);
        return;        
      }
    });
    
  },

  populateForm: function(jobsData) {
    if (jobsData && jobsData.length) {
      this.base(jobsData);
      this.resetSpecies(jobsData[0]['species']);
      if (jobsData[0].url) {
        this.elLk.form.find('input[name=url]').html(jobsData[0].url);
        this.elLk.formatDropdown.find('input[value=' + jobsData[0].format + ']').first().click();
      }
      
      if (jobsData[0].chr_filter) {
        this.elLk.form.find('[name=chr_filter][value=' + jobsData[0].chr_filter + ']').prop('checked', true);
        this.elLk.form.find('select[name=convert_to]').find('input[value=' + jobsData[0].convert_to + ']').first().click();
      }
      
      if (jobsData[0].add_transcript) {
        this.elLk.form.find('[name=add_transcript][value=' + jobsData[0].add_transcript + ']').prop('checked', true);        
      }
      
      if (jobsData[0].remap_patch) {
        this.elLk.form.find('[name=remap_patch][value=' + jobsData[0].remap_patch + ']').prop('checked', true);        
      }      
    }
  },
  
  reset: function() {
    this.base.apply(this, arguments);
    this.resetSpecies(this.defaultSpecies);
    this.elLk.form.find('._previous_file').remove();
  },
  
  resetSpecies: function (species) {
  /*
   * Resets the species dropdown to select the given species or simply refresh the dropdown
   */
    this.elLk.speciesDropdown.find('input[value=' + species + ']').first().click();
    this.elLk.speciesDropdown.speciesDropdown({refresh: true});
  }
});
