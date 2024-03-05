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

Ensembl.Panel.FileChameleonForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    var panel = this;
    
    this.base.apply(this, arguments);

    this.elLk.speciesDropdown = this.elLk.form.find('._sdd');
    this.elLk.formatRadio     = this.elLk.form.find('input[name=format]');
    this.elLk.fileList        = this.elLk.form.find('select[name=files_list]');
    this.elLk.chr_filter      = this.elLk.form.find('input[name=chr_filter]');
    this.elLk.add_transcript  = this.elLk.form.find('input[name=add_transcript]');
    this.elLk.remap_patch     = this.elLk.form.find('input[name=remap_patch]');
    
    this.release_version = this.params['release_version']; //not being used anymore (was used to determine the default file for gff3 and gtf) but keeping it in case it will be needed
    this.ftp_url         = this.params['ftp_url'];
    this.speciesname_map = this.params['speciesname_mapping']; //species web name to production name hash map

    this.resetSpecies(this.defaultSpecies);
    this.editExisting();
    this.populateFileListing();
    
    this.elLk.speciesDropdown.on('change',function(){
      panel.elLk.form.find('p.nofilter_note').hide();
      panel.elLk.form.find('div._remap').hide();
      
      //if after choosing the format, user decide to change species, need to repopulate the file list
      if(panel.elLk.formatRadio.is(":checked")) {
        panel.elLk.fileList.hide();        
        panel.populateFileListing();
        //show no filters note only if format is selected
        if(!panel.elLk.form.find('div._filters').is(":visible")) {
          panel.elLk.form.find('p.nofilter_note').show();
        }
      } else {
        panel.elLk.form.find('div._stt_fasta').hide(); //because whenever the species changes and if the format is not chosen, the chr_filter dropdown appears
      }    
    });

    this.elLk.formatRadio.on('change',function(){
      panel.elLk.fileList.hide();
      panel.elLk.form.find('p.nofilter_note').hide();
      panel.elLk.form.find('div._remap').hide();
      panel.populateFileListing();
      
      if(!panel.elLk.speciesDropdown.find('input:checked').hasClass('_stt__chr_filter')) {  //because the chr_filter toggle needs to work on both species and format fasta
        panel.elLk.form.find('div._stt_fasta').hide();
      }
      
      //if no filters is available then show this note
      if(!panel.elLk.form.find('div._filters').is(":visible")) {
        panel.elLk.form.find('p.nofilter_note').show();
      }
    });
 
 //show/hide file list dropdown by clicking on the link select a different file
    this.elLk.form.find('span.file_link a').on('click', function(e){
      e.preventDefault();
      panel.elLk.form.find('span._file_text').hide();
      panel.elLk.fileList.show().trigger('focus');
      panel.elLk.form.find('span.file_link').hide();
    });
    
    this.elLk.fileList.on('change', function(){ 
      panel.elLk.fileList.hide();      
      panel.elLk.fileList.find('option[value="' + this.value + '"]').prop('selected', true);
      panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();
      panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());
      panel.elLk.form.find('span.file_link').show();
    });
    
//if user just clicks on link to change dropdown value but then decided not to
    if(this.elLk.form.find('select[name=files_list]:visible')) {
      panel.elLk.fileList.on('focusout', function(){
        panel.elLk.fileList.hide();
        panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();
        panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());
        panel.elLk.form.find('span.file_link').show();
      });
    }    
    
    // Add validate event to the form which gets triggered before submitting it
    this.elLk.form.on('validate', function(e) {
      if (!(panel.elLk.formatRadio.is(':checked'))) {
        panel.showError('Please choose a file format', 'No format choosen');
        $(this).data('valid', false);
        return;
      }
    });
    
    if(!panel.elLk.formatRadio.is(":checked")) {
      this.elLk.form.find('div._stt_fasta').hide(); //this is to hide all the filters on new job (chr_filter dropdown is shown because human is selected by default)
    }
    
  },
  
  populateForm: function(jobsData) {
    var panel = this;
    
    if (jobsData && jobsData.length) {
      this.base(jobsData);
      this.resetSpecies(jobsData[0]['species']);
      if (jobsData[0].file_url) {        
        this.elLk.formatRadio.filter('[value=' + jobsData[0].format + ']').prop('checked',true);
        panel.populateFileListing(jobsData[0].file_url);
      }

      //check whether to show chromosome naming style dropdown for species
      if(!panel.elLk.speciesDropdown.find('input:checked').hasClass('_stt__chr_filter')) {
        panel.elLk.form.find('div._stt_chr_filter').hide();
      }
      
      if (jobsData[0].chr_filter) {        
        this.elLk.form.find('select[name=chr_filter]').show().find('option[value=' + jobsData[0].chr_filter + ']').prop('selected', true);
      }
      
      if (jobsData[0].long_genes) {
        this.elLk.form.find('select[name=long_genes]').find('option[value=' + jobsData[0].long_genes + ']').prop('selected', true);
      }      
      
      if (jobsData[0].add_transcript) {
        this.elLk.form.find('[name=add_transcript][value=' + jobsData[0].add_transcript + ']').prop('checked', true);        
      }
      
      if (jobsData[0].remap_patch) {
        //panel.elLk.find('div._remap').show();
        this.elLk.form.find('[name=remap_patch][value=' + jobsData[0].remap_patch + ']').prop('checked', true);        
      }      
    }
  },
  
//Creating the FTP path url to retrieve the species files
  populateFileListing: function(selected_file,format,species) {
    var panel = this;

    var file_select      = panel.elLk.fileList.val();
    var format           = format ? format : this.elLk.form.find("input[name=format]:checked").val().toLowerCase();
    var file_extension   = format;
    var species          = species ? species : panel.speciesname_map[panel.elLk.speciesDropdown.find('input:checked').val()]; //mapping species web name to production name for ftp dir listing
    
    //replace full path if selected_file is full path, we only need file name
    selected_file = selected_file && selected_file.match(/(^http:\/\/.*\/)/gi) ? selected_file.replace(/(^http:\/\/.*\/)/gi,"") : selected_file; 

    var default_name;
    var long_filename;
    
    //different directory structure and file extension for fasta (current_fasta/species/dna/file.fa.gz)
    if(format === 'fasta') {
      species         += "/dna";
      file_extension  = "fa";
      default_name    = panel.elLk.speciesDropdown.find('input:checked').parent().find('label').html().replace(/\(.*\)/,"")+"genome assembly";
      selected_file   = selected_file ? selected_file : "dna\\.toplevel\\.";
    } else {      
      default_name    = panel.elLk.speciesDropdown.find('input:checked').parent().find('label').html().replace(/\(.*\)/,"")+"gene set";      
      selected_file   = selected_file ? selected_file : "(\\d+)\\."+format;
    }

    var ftp_url = panel.ftp_url + format + "/" + species + "/";
    $.ajax({
      'url': ftp_url,
      'dataType': "html",
      'beforeSend': function () { panel.toggleSpinner(true); },
      'success': function(data){
        var a_tag = data.replace(/<img(.*?)>/g); //removing img tag so that it doesnt complain about images not found
        var all_files="";
        
        $(a_tag).find("a:contains(."+file_extension+")").each(function(){
          var file_name = $(this).attr("href");
          //Because human and mouse fasta main toplevel are different (should be the primary assembly file)
          selected_file = format === 'fasta' && file_name.match(new RegExp("dna\\.primary_assembly", 'i')) && !selected_file.match(new RegExp("http", 'i'))? "dna\\.primary_assembly" : selected_file; //the last end is if it is not coming from database for edited job(selected_file will have http)

          selected      = selected_file && file_name.match(new RegExp(selected_file, 'i')) ? 'selected="selected"' : '';
          long_filename = selected ? default_name + " (" + file_name + ")" : file_name.match(/chr_patch_hapl_scaff/i) ? default_name + " with patches (" + file_name + ")" : file_name;
          all_files     += '<option value="' + ftp_url + file_name + '"' + selected +'>' + long_filename + '</option>';
        });
        
        panel.elLk.fileList.html('').append(all_files);
        panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();
        panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());
        panel.elLk.form.find('span.file_link').show();

        //And show/hide remap patches filter if patch file is present (mainly for human and mouse); can apply this filter on both chr_patch* or abinitio* file and is only available for gff3.
        //LEAVE this here because the check can only happen after the dropdown is populated        
        if(panel.elLk.fileList.find('option[value*="chr_patch_hapl_scaff"]').length && format === 'gff3') {
          panel.elLk.form.find('div._remap').show();
        } else {
          panel.elLk.form.find('div._remap').hide();
        }
        
        if(panel.elLk.form.find('div._remap').is(":visible") && panel.elLk.remap_patch.is(":checked")) {
          panel.elLk.fileList.find('option[value*="chr_patch_hapl_scaff"]').prop('selected', true);
          panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();
          panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());
        }         
        //select default file to *chr_patch_hapl_scaff* if remap patch filter is ticked (small bug: doing the below twice)        
        panel.elLk.remap_patch.on('change', function (){
          if(panel.elLk.form.find('div._remap').is(":visible") && panel.elLk.remap_patch.is(":checked")) {
            panel.elLk.fileList.find('option[value*="chr_patch_hapl_scaff"]').prop('selected', true);
            panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();            
            panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());            
          } else {
            var rollback_value = "(\\d+)\\."+format
            panel.elLk.fileList.find('option[value*="' + rollback_value + '"]').prop('selected', true);
            panel.elLk.form.find('span._file_text').html(panel.elLk.form.find('select[name=files_list] option:selected').text()).show();            
            panel.elLk.form.find('input[name=file_text]').val(panel.elLk.form.find('select[name=files_list] option:selected').text());            
          }
        })
      },
      'complete' :  function () { panel.toggleSpinner(false); },
      'error': function (jqXHR, status, err) {
        panel.showError('The files you requested are currently unavailable for download. Please try again later and <a href="/Help/Contact" class="popup">contact us</a> if you are still having problems.', 'Files unavailable');
        $(panel.elLk.form).data('valid', false);        
        panel.toggleSpinner(false, '', '');
      }
    })
  },
  
  reset: function() {
    this.base.apply(this, arguments);
    this.resetSpecies(this.defaultSpecies);
    this.elLk.form.find('input[name="format"]').selectToToggle('trigger');
    this.elLk.form.find('p.nofilter_note').hide(); // we hide some filters and text for new job
  },
  
  resetSpecies: function (species) {
  /*
   * Resets the species dropdown to select the given species or simply refresh the dropdown
   */
    this.elLk.speciesDropdown.find('input[value=' + species + ']').first().click();
    this.elLk.speciesDropdown.speciesDropdown({refresh: true});
  }
});
