/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.VEPForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base();
    this.resetSpecies(this.elLk.form.find('input[name=default_species]').remove().val());
    this.editExisting();
    
    this.elLk.form.find('a._example_input').on('click', function() {
      $('[name=text]').val(this.rel);
      $('[name=preview]').show();
    });
    
    this.elLk.form.find('textarea[name=text]')
      .on('keyup',  {panel: this}, this.showHidePreviewButton)
      .on('change', {panel: this}, this.showHidePreviewButton)
      .on('click',  {panel: this}, this.showHidePreviewButton);
    
    this.elLk.form.find('input[name=preview]').on('click', {panel: this}, this.preview);
  },
  
  showHidePreviewButton: function(e) {
    var panel = e.data.panel;
    
    if($(this).val().length > 0) {
      panel.elLk.form.find('[name=preview]').show();
    }
    else {
      panel.elLk.form.find('[name=preview]').hide();
    }
  },
  
  preview: function(e) {
    
    var panel = e.data.panel;

    // reset preview div
    var div = panel.elLk.form.find('#vep_preview');
    if(div.length === 0) {
      panel.elLk.form.find('input[name=preview]').parent().append('<div id="vep_preview" style="margin-top:10px"></div>');
      div = panel.elLk.form.find('#vep_preview');
    }
    div.show().empty();
  
    // get input
    var field = panel.elLk.form.find('textarea[name=text]');
    if(typeof field === 'undefined' || typeof field[0] === 'undefined') return;
    var input = field.val().split(/\r\n|\r|\n/)[0];
    
    // detect format
    var format = panel.detectFormat(input.split(/\s+/));
    
    // get species
    var species = panel.elLk.form.find('input[name=species]:checked').val();
    var assembly = '';
    
    // get assembly
    if(species === 'Homo_sapiens') {
      var assembly = $('._stt_' + species).html().toLowerCase() + '.';
    }
    
    // construct the URL
    var baseURL = 'http://' + assembly + 'rest.ensembl.org/vep/' + species;
    var url;
    
    switch(format) {
      case "id":
        url = baseURL + '/id/' + input;
        break;
        
      case "ensembl":
        var arr = input.split(/\s+/);
        var strand = 1;
        if(arr[4] && arr[4].match(/\-/)) strand = -1
        url = baseURL + '/region/' + arr[0] + ':' + arr[1] + '-' + arr[2] + ':' + strand + '/' + arr[3].replace(/[ACGTN-]\//, '');
        break;
        
      case "vcf":
        var arr = input.split(/\s+/);
        var c = arr[0];
        var r = arr[3];
        var a = arr[4].split(',')[0];
        
        // we can't do e.g. structural variants
        if(!a.match(/[ACGTN]+/i)) {
          div.empty().append('<img src="/i/16/alert.png" style="vertical-align:top;"/> <b>Unable to generate preview:</b> allele must be [ACGT]');
          return;
        }
        
        var s = parseInt(arr[1]);
        var e = s + (r.length - 1);
        
        // adjust coordinates for mismatched substitutions
        if(r.length != a.length) {
          s = s + 1;
          a = a.length === 1 ? '-' : a.substring(1);
        }
        
        url = baseURL + '/region/' + c + ':' + s + '-' + e + ':' + 1 + '/' + a[0];
        break;
        
      default:
        div.empty().append('<img src="/i/16/alert.png" style="vertical-align:top;"/> <b>Unable to generate preview for ' + format + ' format</b>');
        return;
    }
    
    div.append('<img src="/i/ajax-loader.gif"/>');
    
    console.log(url);
  
    // do the AJAX request
    $.ajax({
      url: url,
      type: "GET",
      dataType: 'json',
      
      // pass in some data from the current namespace
      myData: {
        species: species,
        input: input,
        panel: panel,
      },
      
      // success function renders preview
      success: function( results ) {
        var res = results[0];
        
        // get data passed from this.myData
        var species = this.myData.species;
        var input = this.myData.input;
        var panel = this.myData.panel;
        
        // get data passed from Perl
        var previewData = JSON.parse(panel.params['preview_data']);//.replace(/\'/g, '"'));
        
        // function to render consequence type with colour and description HT
        var renderConsequence = function(consData, con) {
          var html =
            '<nobr><span class="colour" style="background-color:' +
            consData[con].colour +
            '">&nbsp;</span> <span class="_ht ht" title="' +
            consData[con].description +
            '">' +
            con + 
            '</span></nobr>';
            
          return html;
        }
        
        // function to render link as ZMenu link
        var renderZmenuLink = function(species, type, id, label) {
          var t = type.substring(0,1).toLowerCase();
          var html =
            '<a class="zmenu" href="/' + species +
            '/ZMenu/' + type + '?' + t + '=' + id +
            '">' + label + '</a>';
          return html;
        }
        
        var table =
          '<style>tr:nth-child(odd) {background-color: #eaeeff;}</style>' +
          '<div class="hint"><h3><img src="/i/close.png" alt="Hide" class="close_button" title="">Results preview for ' + input + '</h3>' +
          '<div class="message-box" style="padding: 10px; background-color: white;">' +
          '<b>Most severe consequence:</b> ' + renderConsequence(previewData, res.most_severe_consequence) + '<br/>' +
          (
            res.hasOwnProperty('colocated_variants') ?
            '<b>Colocated variants:</b> ' + res.colocated_variants.map(function(a) {
              var ret =
                renderZmenuLink(species, 'Variation', a.id, a.id) +
                (a.hasOwnProperty('minor_allele_freq') ? ' <i>(MAF: ' + a.minor_allele_freq + ')</i>' : '');
              return ret;
            }).join(", ") + '<br/>' :
            ''
          ) +
          '<br/><table class="ss" style="margin-bottom:0px;" id="vep_preview_table"><tbody>' +
          '<tr><th>Gene/Feature/Type</th><th>Consequence</th><th>Details</th></tr>';
        
        // get data from transcript consequences
        $(res.transcript_consequences).each(function() {
          table = table +
            '<tr><td>' +
              '<b>' + renderZmenuLink(species, 'Gene', this.gene_id, this.gene_symbol) + '</b>: ' +
              renderZmenuLink(species, 'Transcript', this.transcript_id, this.transcript_id) +
              '<br/><span class="small"><b>Type: </b>' + this.biotype + '</span>' +
            '</td><td>' +
              this.consequence_terms.map(function(a) { return renderConsequence(previewData, a) }).join(", ") +
            '</td>';
          
          // add details column
          var details = '';
          if(this.hasOwnProperty('amino_acids')) {
            details = details + '<b>Amino acids:</b> ' + this.amino_acids + '<br/>';
          }
          if(this.hasOwnProperty('sift_prediction')) {
            details = details + '<b>SIFT:</b> ' + this.sift_prediction + '<br/>';
          }
          if(this.hasOwnProperty('polyphen_prediction')) {
            details = details + '<b>PolyPhen:</b> ' + this.polyphen_prediction + '<br/>';
          }
          if(this.hasOwnProperty('distance')) {
            details = details + '<b>Distance to transcript:</b> ' + this.distance + 'bp<br/>';
          }
          if(details.length === 0) details = '-';
          
          table = table + '<td>' + details + '</td></tr>';
        });
        
        // get data from regulatory consequences
        $(res.regulatory_feature_consequences).each(function() {
          table = table +
            '<tr><td>' +
              '<b>' + renderZmenuLink(species, 'RegulatoryFeature', this.regulatory_feature_id, this.regulatory_feature_id) + '</b>' +
              '<br/><span class="small"><b>Type: </b>' + this.biotype + '</span>' +
            '</td><td>' +
              this.consequence_terms.map(function(a) { return renderConsequence(previewData, a) }).join(", ") +
            '</td>';
          
          table = table + '<td>-</td></tr>';
        });

        var div = panel.elLk.form.find('#vep_preview').empty().append(table + '</div></div>');
        
        // these need listeners adding as they are rendered after page load
        div.find('a.zmenu').on('click', panel.zmenu);
        div.find('.ht').helptip();
        div.find('.close_button').on('click', {div: div}, function(e) { e.data.div.hide(); });
        return;
      },
      error: function(jqXHR, textStatus, errorThrown) {
       console.log(JSON.stringify(jqXHR));
       console.log("AJAX error: " + textStatus + ' : ' + errorThrown);
       
       var error = jqXHR.responseJSON.error;
       
       this.myData.panel.elLk.form.find('#vep_preview').empty()
         .append('<img src="/i/16/alert.png" style="vertical-align:top;"/> <b>Unable to generate preview:</b> ' + error);
       return;
      }
    });
  },
  
  // this detects input format
  // copied from Bio::EnsEMBL::Variation::Utils::VEP::detect_format  
  detectFormat: function(data) {
    
    // HGVS: ENST00000285667.3:c.1047_1048insC
    if (
      data.length === 1 &&
      data[0].match(/^([^\:]+)\:.*?([cgmrp]?)\.?([\*\-0-9]+.*)$/i)
    ) {
      return 'hgvs';
    }
  
    // variant identifier: rs123456
    else if (data.length === 1) {
      return 'id';
    }
  
    // VCF: 20  14370  rs6054257  G  A  29  0  NS=58;DP=258;AF=0.786;DB;H2  GT:GQ:DP:HQ
    else if (
      data[0].match(/(chr)?\w+/) &&
      data[1].match(/^\d+$/) &&
      data[3].match(/^[ACGTN\-\.]+$/i) &&
      typeof data[4] != 'undefined' && data[4].match(/^([\.ACGTN\-]+\,?)+$|^(\<[A-Z]+\>)$/i)
    ) {
      return 'vcf';
    }
  
    // pileup: chr1  60  T  A
    else if (
      data[0].match(/(chr)?\w+/) &&
      data[1].match(/^\d+$/) &&
      data[2].match(/^[\*ACGTN-]+$/i) &&
      data[3].match(/^[\*ACGTNRYSWKM\+\/-]+$/i)
    ) {
      return 'pileup';
    }
  
    // ensembl: 20  14370  14370  A/G  +
    else if (
      data[0].match(/\w+/) &&
      data[1].match(/^\d+$/) &&
      data[2].match(/^\d+$/) &&
      data[3].match(/(ins|dup|del)|([ACGTN-]+\/[ACGTN-]+)/i)
    ) {
      return 'ensembl';
    }
    
    else {
      return 'unknown';
    }
  },
  
  zmenu: function(e){
    var el = $(this);
    Ensembl.EventManager.trigger('makeZMenu', el.text().replace(/\W/g, '_'), { event: e, area: {a: el}});
    return false;
  },

  populateForm: function(jobsData) {
  /*
   * Populates the form according to the provided ticket data
   */
    if (jobsData && jobsData.length) {
      jobsData = $.extend({}, jobsData[0].config, jobsData[0]);
      this.base(jobsData);

      if (jobsData['input_file_type']) {
        this.elLk.form.find('input[name=file]').parent().append('<p class="_download_link">' + ( jobsData['input_file_type'] === 'text'
          ? 'Click <a href="' + jobsData['input_file_url'] + '">here</a> to download the previously uploaded file.'
          : 'You previously uploaded a compressed file to run this job.'
        ) + '</p>');
      }

      if (!this.elLk.speciesDropdown.find('input:checked').length) {
        this.elLk.speciesDropdown.find('input[type=radio]').first().click();
      }

      this.resetSpecies();
    }
  },

  reset: function() {
  /*
   * Resets the form, ready to accept next job input
   */
    this.base.apply(this, arguments);
    this.elLk.form.find('._download_link').remove();
    this.resetSpecies();
    this.resetSelectToToggle();
  },

  resetSpecies: function (species) {
  /*
   * Resets the species dropdown to select the given species or simply refresh the dropdown
   */
    if (!this.elLk.speciesDropdown) {
      this.elLk.speciesDropdown = this.elLk.form.find('._sdd');
    }

    if (species) {
      this.elLk.speciesDropdown.find('input[value=' + species + ']').first().click();
    }

    this.elLk.speciesDropdown.speciesDropdown({refresh: true});
  }
});
