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

Ensembl.Panel.DataSlicerForm = Ensembl.Panel.ThousandGenome.extend({

  init: function() {
    var panel = this;
    
    this.base.apply(this, arguments);
    
    this.elLk.vcf_filters_radio = this.elLk.form.find('input[name=vcf_filters]');
    this.elLk.individuals       = this.elLk.form.find('div._individuals');    
    
    panel.elLk.vcf_filters_radio.on('change', function () {
      if (panel.elLk.form.find('input[name=vcf_filters]:checked').val() === 'individuals') {
        if(!panel.elLk.region.val()) {          
          panel.showError('Please choose a region first', 'Missing region');
          panel.elLk.form.find('input[name=vcf_filters][value=null]').prop('checked',true);
          panel.elLk.form.find('div._stt_individuals').hide();
          return;
        } else {
          panel.updateIndividuals();
        }
      }
    });
    
    panel.elLk.form.find('input[name=custom_file_url]').on('change', function () {      
      //TODO update choose individuals box
    });
  },
  
  reset: function() {
    this.base.apply(this, arguments);

    this.elLk.form.find('div._stt_populations').hide();
    this.elLk.form.find('div._stt_individuals').hide();
    this.elLk.form.find('select[name=file_format]').find('option[value=vcf]').prop('selected', true).end().selectToToggle('trigger');
    this.elLk.form.find('span._span_url').html('Genotype file URL: ').show();
    this.elLk.form.find('input[name=generated_file_url]').val("");
  },
  
  updateIndividuals: function(selected_value) {
    var panel = this;

    $.ajax({
      'comet'       : true,
      'type'        : 'POST',
      'dataType'    : 'json',
      'url'         : panel.getIndividuals,
      'beforeSend'  : function () { panel.toggleSpinner(true); },
      'data'        : { file_url: panel.elLk.form.find('input[name=custom_file_url]:visible').val() || panel.elLk.form.find('input[name=generated_file_url]').val(), region: panel.elLk.region.val() },      
      'success'     : function(json) {
        var listbox  ="";

        if(json.error) {
          panel.showError('The file url is either invalid or not reachable', 'Invalid genotype file URL');
          panel.elLk.form.find('div._individuals select').html(''); //Hiding population dropdown if its already there before by inputing a valid sample url
          $(panel.elLk.form).data('valid', false);
          panel.toggleSpinner(false);           
        } else if (json.vcf_error) {
          panel.showError(json.vcf_error, 'VCF file ERROR');
          panel.elLk.form.find('div._individuals select').html(''); //Hiding population dropdown if its already there before by inputing a valid sample url
          $(panel.elLk.form).data('valid', false);
          panel.toggleSpinner(false);         
        } else {
          $.each (json.individuals, function (index,el) {
            if(el.value) {           
              listbox += '<option value="' + el.value + '">' + el.value + '</option>';
            }
          });
          panel.elLk.form.find('div._individuals').show();
          panel.elLk.form.find('div._individuals select').html('').append(listbox);

          if(selected_value) {            
            $.each(selected_value.split(","), function(i,e){              
              panel.elLk.form.find('div._individuals select').find('option[value=' + e + ']').prop('selected', true);
            });
          }
        }
      },
      'complete' :  function (json) { panel.toggleSpinner(false); }
    });
  }    
});
