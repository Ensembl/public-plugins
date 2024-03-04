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

Ensembl.Panel.ThousandGenome = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    var panel = this;
    
    this.base.apply(this, arguments);

    this.elLk.speciesDropdown = this.elLk.form.find('._sdd');
    this.elLk.collection      = this.elLk.form.find('select[name=collection_format]');
    this.elLk.region          = this.elLk.form.find('input[name=region]');
    this.elLk.sample_url      = this.elLk.form.find('input[name=custom_sample_url]');
    this.elLk.file_url        = this.elLk.form.find('input[name=custom_file_url]');
    this.readSampleFile       = this.params['read_sample_file'];
    this.fileRestURL          = this.params['genome_file_rest_url'];
    this.filesLocation        = this.params['files_location_regex'];
    this.getIndividuals       = this.params['get_individuals']; //for dataslicer

    //this.resetSpecies(this.defaultSpecies);
    this.editExisting();


    panel.elLk.region.on('blur', function (e) {
      //imitating change event (used blur because of safari autocomplete doesn't trigger change event)
      $(this).data("old", $(this).data("new") || "");
      $(this).data("new", $(this).val());

      if($(this).data("old") === $(this).data("new")) { return; } //do not do anything if value hasn't change

      var collection_value = panel.elLk.collection.val();      
      var r = panel.elLk.region.val().replace(/\s/g,'').match(/^([^:]+):\s?([0-9\,]+)(-|_|\.\.)([0-9\,]+)$/);

      if (!r || r.length !== 5 || r[4] - r[2] < 0) {
//don't do anything here, error message is in validation

      } else { //only if it is a valid region then do the below      
        //The region size restriction is only available on some tool (allele frequency)
        if(panel.elLk.form.find('input[name=region_check]').length && ((parseFloat(r[4].replace(/,/gi,"")) - parseFloat(r[2].replace(/,/gi,""))) + 1) > parseInt(panel.elLk.form.find('input[name=region_check]').val())) {
          panel.showError('The region size is too big, maximum region size allowed is '+parseInt(panel.elLk.form.find('input[name=region_check]').val()), 'Large region size');
          $(panel.elLk.form).data('valid', false);
          return;
        } else {
          $(panel.elLk.form).data('valid', true);
        }

        //getting the file url from 1KG rest if user input region and data collection is either phase1 or phase3, do not retrieve any files for bam files in data slicer
        if(collection_value != 'custom' && !panel.elLk.form.find('input[name=bam_file_url]').is(":visible")) { 
          panel.getFileURL(r[1],collection_value);
        }
        
        //show sample population file url based on data collection selection (we have a specific file for human chrY)
        if(panel.elLk.region.val().match(/y:/gi) && collection_value === 'phase3') {
          if(!panel.elLk.form.find('input[name=no_population]').val()) { panel.updatePopulation("","_stt_phase3_male"); }
          panel.elLk.form.find('[class^="_sample_url_"]').hide();
          panel.elLk.form.find('span._sample_url_phase3_male').show();
        } else {
          panel.elLk.form.find('span._stt_phase3_male').hide();
          if(collection_value != 'custom') {
            panel.elLk.form.find('span._stt_'+collection_value).show();
            panel.elLk.form.find('span._sample_url_phase3_male').hide();
          }
        }
      }
    });

    
    panel.elLk.collection.on('change', function () {      
      var r = panel.elLk.region.val().replace(/\s/g,'').match(/^([^:]+):\s?([0-9\,]+)(-|_|\.\.)([0-9\,]+)$/);      

        if(panel.elLk.collection.val() != 'custom') {
          panel.elLk.form.find('div.custom_population').hide();
        }
       
        if(panel.elLk.collection.val() === 'custom' && panel.elLk.sample_url.val()) {
          panel.elLk.form.find('div.custom_population').show();
        }
        
        if(panel.elLk.collection.val() != 'custom' && panel.elLk.region.val()) {
          panel.getFileURL(r[1],panel.elLk.collection.val());        
        }
        
  //      if(panel.elLk.speciesDropdown.find('input[name=species]:checked').val() === "Homo_sapiens") { //commenting this out for now as we only have human as species
        if(panel.elLk.collection.val() === 'phase3' && panel.elLk.region.val().match(/y:/gi)) {
          if(!panel.elLk.form.find('input[name=no_population]').val()) { panel.updatePopulation("","_stt_phase3_male"); }
          panel.elLk.form.find('[class^="_sample_url_"]').hide();
          panel.elLk.form.find('span._sample_url_phase3_male').show();
        } else {
          panel.elLk.form.find('div._stt_phase3_male').hide();
          panel.elLk.form.find('span._sample_url_phase3_male').hide();
        }        
//      }
    });
    
    panel.elLk.sample_url.on('change', function () {
      var el = $(this);
      //validating for empty value before updating population url
      if (!panel.elLk.sample_url.val()) {
        panel.showError('Please provide a sample population URL', 'No sample population URL');
        $(panel.elLk.form).data('valid', false);
        return;
      }

      el.parents('form').validate(); //trigger the generic validate here because of the delay in 00_jquery_validate.js which was causing other event to happen before validation
    
      if(!el.data('valid')) {
        panel.elLk.form.find('div.custom_population select').html(''); //precautionary measure in case a user entered a valid sample url first and then reenter a not valid one
        panel.elLk.form.find('div.population').hide();
      } else {        
        if(!panel.elLk.form.find('input[name=no_population]').val()) {
          panel.updatePopulation(panel.elLk.sample_url.val().replace(/^\s+|\s+$/g, ''),"custom_populations");
        }
      }
    });

    
    // Add validate event to the form which gets triggered before submitting it
    this.elLk.form.on('validate', function(e) {
      if (!panel.elLk.region.val()) {
        panel.showError('Please enter a region', 'No region entered');
        $(this).data('valid', false);
        return;
      } else {
        var r = panel.elLk.region.val().replace(/\s/g,'').match(/^([^:]+):\s?([0-9\,]+)(-|_|\.\.)([0-9\,]+)$/);

        if (!r || r.length !== 5 || r[4] - r[2] < 0) {
          panel.showError('Please enter a valid region e.g: 1:1-50000', 'Invalid Region Lookup');
          $(panel.elLk.form).data('valid', false);
          return;
        }
        
        if(panel.elLk.form.find('input[name=region_check]').length) { //The region size restriction is only available on some tool (allele frequency)        
          if(((parseFloat(r[4].replace(/,/gi,"")) - parseFloat(r[2].replace(/,/gi,""))) + 1) > parseInt(panel.elLk.form.find('input[name=region_check]').val())) {
            panel.showError('The region size is too big, maximum region size allowed is '+parseInt(panel.elLk.form.find('input[name=region_check]').val()), 'Large region size');
            $(panel.elLk.form).data('valid', false);
            return;
          }
        }
      }

      
      if(!panel.elLk.form.find('input[name=generated_file_url]').val().match(/^ftp|^http/gi) && panel.elLk.form.find('span._span_url').is(":visible")) {
          panel.showError('Genotype file URL missing, Please make sure you entered the correct region', 'Genotype file URL missing');
          $(panel.elLk.form).data('valid', false);
          return;
      }

      if(panel.elLk.collection.is(":visible") && panel.elLk.collection.val() === "custom") {
        if (!panel.elLk.file_url.val()) {
          panel.showError('Please provide a file URL', 'No file URL');
          $(this).data('valid', false);
          return;
        }
        
        if (panel.elLk.sample_url.is(":visible") && !panel.elLk.sample_url.val()) {
          panel.showError('Please provide a sample population URL', 'No sample population URL');
          $(this).data('valid', false);
          return;
        }
      }
      
      if(panel.elLk.form.find('select.tools_listbox').is(":visible") && !panel.elLk.form.find('select.tools_listbox:visible').val()){
          panel.showError('Please choose at least one population', 'No population');
          $(this).data('valid', false);
          return;       
      }
      
      if(panel.elLk.form.find('input[name=bam_file_url]').is(":visible") && !panel.elLk.form.find('input[name=bam_file_url]').val()){
          panel.showError('Please provide a BAM file url', 'No file URL');
          $(this).data('valid', false);
          return;       
      }      
      
      // individuals selection box available in data slicer
      if(panel.elLk.form.find('select.individuals_listbox').is(":visible") && !panel.elLk.form.find('select.individuals_listbox').val() && panel.elLk.form.find('input[name=ind_list]').is(":visible") && !panel.elLk.form.find('input[name=ind_list]').val()){
          panel.showError('Please choose at least one inidividuals', 'No individuals');
          $(this).data('valid', false);
          return;       
      }
      
      // after all validation is done and just before submitting the tool do this for data slicer only (this is because the population dropdown values are not useful)
      // TODO: Make this more generic if it is used elsewhere; if dropdown values have comma then use caption instead but need to make sure backend isn't confused
      if(panel.elLk.form.find('input[name=which_tool]').val() === "data_slicer" && panel.elLk.form.find('select.tools_listbox').is(":visible")) {
        var populations_caption = panel.elLk.form.find('select.tools_listbox:visible option:selected').map(function () { return $(this).text(); }).get().join();
        panel.elLk.form.find('input[name=pop_caption]').val(populations_caption);
        return;
      }
    });
  },
  
  getFileURL: function(region, collection) {
    var panel = this;     
    var url;

    region = region.match(/^chr/gi) ?  region : "chr"+region;
    collection = "1000 Genomes phase "+collection.replace("phase","")+" release";

    function handleEmptyResponse () {
      var subjectLine = "Data slicer unable to retrieve genotype file from 1000G FTP site";
      var linkToContactForm = '<a href="/Help/Contact?subject=' + encodeURIComponent(subjectLine) + '">contact us</a>';
      var errorMessage = 'We are currently unable to retrieve the genotype data. Please try again and if the problem persists please ' + linkToContactForm;
      panel.elLk.form
        .find('span._span_url')
        .html('<label class="invalid" style="display: inline;">' + errorMessage + '</label>');
      panel.elLk.form.find('input[name=generated_file_url]').val("");
    }

    $.ajax({
      'type'    : "POST",      
      'url'     : panel.fileRestURL,
      'data'    : JSON.stringify({'query':{'regexp':{'url':panel.filesLocation}}, 'size': '-1', '_source': ['url']}), //need to remove the size once returning all is supported by the rest
      'beforeSend' : function() { panel.toggleSpinner(true); },
      'success' : function(data) {
        if(!data.hits || !data.hits.total) {
          handleEmptyResponse();
        } else {
          $.each (data.hits.hits, function (index,el) {
            //Matching the specific region file, Grch37 files have a . after region whereas grch38 have an _ after region
            if(el._source.url && !el._source.url.match(/tbi$/gi) && (el._source.url.match(new RegExp(region+"\\.", 'i')) || el._source.url.match(new RegExp(region+"_", 'i')))) {
              url = el._source.url;
            }
          });
          panel.elLk.form.find('span._span_url').html("Genotype file URL: "+url);
          panel.elLk.form.find('input[name=generated_file_url]').val(url);
        }
      },
      'complete' :  function () { 
        panel.toggleSpinner(false);
        
        //updating individuals listbox for data slicer
        if(panel.elLk.form.find('select.individuals_listbox').is(":visible")) {
          if('updateIndividuals' in panel) {
            panel.updateIndividuals();
          }          
        }        
      },
      'error'     : function () {
        panel.toggleSpinner(false);
        handleEmptyResponse();
      }
    });
  },  
  
  populateForm: function(jobsData) {
    var panel = this;
    
    if (jobsData && jobsData.length) {
      this.base(jobsData);
      //this.resetSpecies(jobsData[0]['species']);
      var upload_type = jobsData[0].upload_type;
      var file_format = jobsData[0].file_format;
      var vcf_filters = jobsData[0].vcf_filters;
      
      if(jobsData[0].job_desc) {
        this.elLk.form.find('input[name=name]').val(jobsData[0].job_desc);
      }
      
      if(file_format) { //for data slicer, form is different depending on file format
        this.elLk.form.find('select[name=file_format]').find('option[value=' + file_format + ']').prop('selected', true).end().selectToToggle('trigger');
        
        if(file_format === 'bam') {
          this.elLk.form.find('input[name=bam_file_url]').val(jobsData[0].file_url);

          if(jobsData[0].bai_file) {
            panel.elLk.form.find('input[name=bai_file]').prop('checked',true);
          }
        }
      }
      
      if(file_format && file_format === 'vcf'){
        if(vcf_filters === 'populations') {
          panel.populatePopulations(jobsData);
        }else if(vcf_filters === 'individuals') {
          panel.elLk.form.find('select[name=collection_format] option').removeAttr("selected");
          panel.elLk.form.find('select[name=collection_format]').find('option[value=' + upload_type + ']').prop('selected', true).end().selectToToggle('trigger');
          panel.elLk.form.find('span._span_url').html("Genotype file URL: " + jobsData[0].file_url);
          panel.elLk.form.find('input[name=generated_file_url]').val(jobsData[0].file_url);
          panel.updateIndividuals(jobsData[0].individuals_box ? jobsData[0].individuals_box : '');
          panel.elLk.form.find('input[name=ind_list]').val(jobsData[0].individuals_text);          
        } else {
          panel.elLk.form.find('select[name=collection_format] option').removeAttr("selected");
          panel.elLk.form.find('select[name=collection_format]').find('option[value=' + upload_type + ']').prop('selected', true).end().selectToToggle('trigger');
          panel.elLk.form.find('span._span_url').html("Genotype file URL: " + jobsData[0].file_url);
          panel.elLk.form.find('input[name=generated_file_url]').val(jobsData[0].file_url);          
        }
        
      } else{       
        panel.populatePopulations(jobsData);
      }
      // Base format radio buttons are not available on all tool (only vcf to ped)
      if(panel.elLk.form.find('input[name=base]').length && jobsData[0].base){
        panel.elLk.form.find('input[name=base][value=' + jobsData[0].base + ']').prop('checked',true);
      }
    }
  },
  
  populatePopulations: function (jobsData) {
    //update population listbox when editing job
    var panel       = this;
    var upload_type = jobsData[0].upload_type;
    
    if (upload_type === 'custom') {
      this.elLk.form.find('select[name=collection_format] option').removeAttr("selected");
      this.elLk.form.find('select[name=collection_format]').find('option[value=custom]').prop('selected', true).end().selectToToggle('trigger');
      this.elLk.form.find('input[name=custom_file_url]').val(jobsData[0].file_url);
      this.elLk.form.find('input[name=custom_sample_url]').val(jobsData[0].sample_panel);
      if(jobsData[0].population) {
        this.updatePopulation(jobsData[0].sample_panel,"custom_population", jobsData[0].population); //show population listbox
      }
    } else {
      var population = this.elLk.form.find('input[name=region]').val().match(/y:/gi) && upload_type === "phase3" ? "phase3_male" : upload_type;
      this.elLk.form.find('select[name=collection_format] option').removeAttr("selected");
      this.elLk.form.find('select[name=collection_format]').find('option[value=' + upload_type + ']').prop('selected', true).end().selectToToggle('trigger');
      this.elLk.form.find('span._span_url').html("Genotype file URL: " + jobsData[0].file_url);
      this.elLk.form.find('input[name=generated_file_url]').val(jobsData[0].file_url);
      this.elLk.form.find('[class^="_sample_url_"]').hide(); //just a sanity check to hide everything first so that nothing is shown by mistake
      this.elLk.form.find('span._sample_url_'+population).show();
      if(jobsData[0].population) { this.updatePopulation("","_stt_"+population,jobsData[0].population); }
    }    
  },
  
  reset: function() {
    this.base.apply(this, arguments);

    this.elLk.form.find('div.population').hide();
    this.elLk.form.find('select[name=collection_format]').find('option[value=phase3]').prop('selected', true).end().selectToToggle('trigger');
    this.elLk.form.find('select[name=phase3_populations]').find('option[value=ALL]').prop('selected', true);
    this.elLk.form.find('span._span_url').html('Genotype file URL: ').show();
    this.elLk.form.find('input[name=generated_file_url]').val("");
  },
  
  updatePopulation: function(panel_url, panel_name, selected_value) {
  //create population listbox from panel file url or show hidden population listbox
    var panel = this;
 
    var diff_pop_value = panel.elLk.form.find('input[name=which_tool]').val() === "data_slicer" ? 1 : 0;

    //this is when the population box has already been generated in the backend and hidden
    if(!panel_url) {
      this.elLk.form.find('div.population').hide();
      this.elLk.form.find('div.'+panel_name).show();
      if(selected_value) {
        var population_listbox = panel_name.replace("_stt_","") + "_populations";        
        this.elLk.form.find('select[name=' + population_listbox + '] option').removeAttr("selected");
        $.each(selected_value.split(","), function(i,e){
          diff_pop_value ? panel.elLk.form.find('select[name=' + population_listbox + ']').find('option:contains(' + e + ')').prop('selected', true) : panel.elLk.form.find('select[name=' + population_listbox + ']').find('option[value=' + e + ']').prop('selected', true); //either select dropdown by text or value
        });
      }
    } else {
      //when creating the population box based on the panel url submitted by user
      $.ajax({
        'comet'       : true,
        'type'        : 'POST',
        'url'         : panel.readSampleFile,
        'dataType'    : 'json',
        'data'        : { population_url: panel_url, pop_value: diff_pop_value },
        'beforeSend'  : function () { panel.toggleSpinner(true); },
        'success' : function(json) {
          var listbox  ="";
          
          if(json.error) {
            panel.showError('The sample population url is either invalid or not reachable', 'Invalid sample population URL');
            panel.elLk.form.find('div.custom_population select').html(''); //Hiding population dropdown if its already there before by inputing a valid sample url
            panel.elLk.form.find('div.population').hide();
            $(panel.elLk.form).data('valid', false);
            panel.ajax.spinner = 'false';
          } else if (json.format_error) {
            panel.showError(json.format_error, 'Wrong sample population file content');
            panel.elLk.form.find('div.custom_population select').html(''); //Hiding population dropdown if its already there before by inputing a valid sample url
            panel.elLk.form.find('div.population').hide();
            $(panel.elLk.form).data('valid', false);
            panel.ajax.spinner = 'false';
          } else {
            $.each (json.populations, function (index,el) {
              if(el.value) {
                if(el.value.match(/sample/gi)) { next; } //skip if  there is a header          
                listbox += '<option value="' + el.value + '">' + el.caption + '</option>';
              }
            });
            panel.elLk.form.find('div.custom_population').show();
            panel.elLk.form.find('div.custom_population select').html('').append(listbox);
            if(selected_value) {
              $.each(selected_value.split(","), function(i,e){
                diff_pop_value ? panel.elLk.form.find('div.custom_population select').find('option:contains(' + e + ')').prop('selected', true) : panel.elLk.form.find('div.custom_population select').find('option[value=' + e + ']').prop('selected', true);
              });
            }            
          }          
        },
        'complete' :  function () { panel.toggleSpinner(false); }
      });
    }
  }
});
