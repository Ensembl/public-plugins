/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

    this.previewData = JSON.parse(this.params['preview_data']);
    delete this.params['preview_data'];
    
    this.exampleData = JSON.parse(this.params['example_data']);
    delete this.params['example_data'];

    this.autocompleteData = JSON.parse(this.params['plugin_auto_values']);
    delete this.params['plugin_auto_values'];

    var panel = this;

    // Change the input value on click of the examples link
    this.elLk.form.find('a._example_input').on('click', function(e) {
      e.preventDefault();

      var species = panel.elLk.form.find('input[name=species]:checked').val();
      var text = panel.exampleData[species][this.rel];
      if(typeof(text) === 'undefined' || !text.length) text = "";
      text = text.replace(/\\n/g, "\n");
    
      panel.elLk.dataField.val(text).trigger('change');
    });

    // Preview button
    this.elLk.previewButton = panel.elLk.form.find('[name=preview]').hide().on('click', function(e) {
      e.preventDefault();
      panel.preview();
    });

    // Preview div
    this.elLk.previewDiv = $('<div class="top-margin">').appendTo(this.elLk.previewButton.parent()).hide();

    // show hide preview button acc to the text in the input field
    this.elLk.dataField = this.elLk.form.find('textarea[name=text]').on({
      'input paste keyup click change': function(e) {

        panel.elLk.previewButton.toggle(!!this.value.length);

        if ($(this).data('previousValue') === this.value) {
          return;
        } else {
          $(this).data('previousValue', this.value);
        }

        if (!!this.value.length) {

          // check format
          var format      = panel.detectFormat(this.value.split(/[\r\n]+/)[0]);
          var enablePrev  = format === 'id' || format === 'vcf' || format === 'ensembl' || format === 'hgvs';

          panel.elLk.previewButton.toggleClass('disabled', !enablePrev).prop('disabled', !enablePrev);
        }
      }
    });

    // auto complete plugin stuff
    this.elLk.form.find('input:text.autocomplete-multi, textarea.autocomplete-multi').each(function() {
      $(this).tokenfield({
        autocomplete: {
          source: panel.autocompleteData.hasOwnProperty(this.name) ? panel.autocompleteData[this.name] : [],
          delay: 100
        },
        showAutocompleteOnFocus: true
      })

      // don't allow duplcates
      .on('tokenfield:createtoken', function (event) {
        var existingTokens = $(this).tokenfield('getTokens');
        $.each(existingTokens, function(index, token) {
          if (token.value === event.attrs.value) event.preventDefault();
        });
      });

      // function split( val ) {
      //   return val.split( /,\s*/ );
      // }
      // function extractLast( term ) {
      //   return split( term ).pop();
      // }
 
      // $(this)
      //   // don't navigate away from the field on tab when selecting an item
      //   .bind( "keydown", function( event ) {
      //     if ( event.keyCode === $.ui.keyCode.TAB &&
      //         $( this ).autocomplete( "instance" ).menu.active ) {
      //       event.preventDefault();
      //     }
      //   })
      //   .autocomplete({
      //     minLength: 0,
      //     source: function( request, response ) {
      //       // delegate back to autocomplete, but extract the last term
      //       response( $.ui.autocomplete.filter(
      //         acValues, extractLast( request.term ) ) );
      //     },
      //     focus: function() {
      //       // prevent value inserted on focus
      //       return false;
      //     },
      //     select: function( event, ui ) {
      //       var terms = split( this.value );
      //       // remove the current input
      //       terms.pop();
      //       // add the selected item
      //       terms.push( ui.item.value );
      //       // add placeholder to get the comma-and-space at the end
      //       terms.push( "" );
      //       this.value = terms.join( "," );
      //       return false;
      //     }
      //   });
        // .autocomplete( "instance" )._renderItem = function( ul, item ) {
        //   return $( "<li>" )
        //     .append( "<a>" + item.label + "<br>" + item.desc + "</a>" )
        //     .appendTo( ul );
        // };
    });
    
    this.elLk.form.find('.plugin_enable').change(function() {

      panel.elLk.form.find('.plugin-highlight').removeClass('plugin-highlight');

      // find any sub-fields enabling this plugin shows
      panel.elLk.form.find('._stt_' + this.name).addClass('plugin-highlight', 100, 'linear');
    });

    this.editExisting();
  },

  preview: function() {
  /*
   * renders VEP results preview
   */

    // reset preview div
    this.elLk.previewDiv.show().empty();

    // get input, format and species
    this.previewInp = {};
    this.previewInp.input   = this.elLk.dataField.val().split(/[\r\n]+/)[0];
    this.previewInp.format  = this.detectFormat(this.previewInp.input);
    this.previewInp.species = this.elLk.speciesDropdown.find('input:checked').val();
    this.previewInp.baseURL = this.params['rest_server_url'] + '/vep/' + this.previewInp.species;
    var url;

    // this switch formats the input into URL for REST API
    switch (this.previewInp.format) {
      case "id":
        url = this.previewInp.baseURL + '/id/' + this.previewInp.input;
        break;
        
      case "hgvs":
        url = this.previewInp.baseURL + '/hgvs/' + encodeURIComponent(this.previewInp.input);
        break;

      case "ensembl":
        var arr = this.previewInp.input.split(/\s+/);
        url = this.previewInp.baseURL + '/region/' + arr[0] + ':' + arr[1] + '-' + arr[2] + ':' + (arr[4] && arr[4].match(/\-/) ? -1 : 1) + '/' + arr[3].replace(/[ACGTN-]+\//, '');
        break;

      case "vcf":
        var arr = this.previewInp.input.split(/\s+/);
        var c = arr[0];
        var r = arr[3];
        var a = arr[4].split(',')[0];

        // we can't do e.g. structural variants
        if(!a.match(/[ACGTN]+/i)) {
          this.previewError('allele must be [ACGT]');
          return;
        }

        var s = parseInt(arr[1]);
        var e = s + (r.length - 1);

        // adjust coordinates for mismatched substitutions
        if(r.length != a.length) {
          s = s + 1;
          a = a.length === 1 ? '-' : a.substring(1);
        }

        url = this.previewInp.baseURL + '/region/' + c + ':' + s + '-' + e + ':' + 1 + '/' + a[0];
        break;

      default:
        this.previewError('Failed for ' + this.previewInp.format + ' format');
        return;
    }

    this.elLk.previewDiv.html('<p><img src="/i/ajax-loader.gif"/></p>');

    // do the AJAX request
    $.ajax({
      url       : url,
      type      : "GET",
      dataType  : 'json',
      context   : this,
      success   : function(results) { this.renderPreviewTable(results) },
      error     : function(jqXHR, textStatus, errorThrown) { this.previewError(jqXHR.responseJSON ? jqXHR.responseJSON.error : 'Unknown error'); }
    });
  },

  detectFormat: function(input) {
  /*
   * this detects input format from data pasted into VEP input form
   * code translated from Bio::EnsEMBL::Variation::Utils::VEP::detect_format
   */
    var data = input.split(/\s+/);

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
      data.length >= 5 &&
      data[0].match(/(chr)?\w+/) &&
      data[1].match(/^\d+$/) &&
      data[3].match(/^[ACGTN\-\.]+$/i) &&
      typeof data[4] != 'undefined' && data[4].match(/^([\.ACGTN\-]+\,?)+$|^(\<\w+\>)$/i)
    ) {
      return 'vcf';
    }

    // pileup: chr1  60  T  A
    else if (
      data.length === 4 &&
      data[0].match(/(chr)?\w+/) &&
      data[1].match(/^\d+$/) &&
      data[2].match(/^[\*ACGTN-]+$/i) &&
      data[3].match(/^[\*ACGTNRYSWKM\+\/-]+$/i)
    ) {
      return 'pileup';
    }

    // ensembl: 20  14370  14370  A/G  +
    else if (
      data.length >= 4 &&
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

  renderPreviewTable: function(results) {
    var panel = this;

    if (!results || !results.length) {
      this.previewError('Invalid response from ' + this.params['rest_server_url']);
      return;
    }

    results = results[0];

    // function render table
    var generateTable = function(headers, rows) {
      return $('<table class="ss">')
        .html('<thead><tr>' + $.map(headers, function(h) { return '<th>' + h + '</th>'; } ).join('') + '</tr></thead>')
        .append($.map(rows, function(row, i) {
          return $('<tr>').addClass(i % 2 ? 'bg2' : 'bg1').append($.map(row, function(col) { return $('<td>').html(col); }));
        }));
    };

    // function to render consequence type with colour and description HT
    var renderConsequence = function(con) {
      return $('<nobr>').append(
        $('<span>').addClass('colour').css('background-color', panel.previewData[con]['colour']).html('&nbsp'),
        $('<span>').html('&nbsp;'),
        $('<span>').attr({'class': '_ht ht margin-left', title: panel.previewData[con]['description']}).html(con)
      ).wrap('<div>').parent().html();
    };

    // function to render link as ZMenu link
    var renderZmenuLink = function(species, type, id, label) {
      return $('<a>').attr({'class': 'zmenu', 'href': '/' + species + '/ZMenu/' + type + '?' + type.replace(/[a-z]/g, '').toLowerCase() + '=' + id}).html(label).wrap('<div>').parent().html();
    };

    // HTML for preview content
    this.elLk.previewDiv.html(
      '<div class="hint">' +
        '<h3><img src="/i/close.png" alt="Hide" class="_close_button" title="">Instant results for ' + this.previewInp.input + '</h3>' +
        '<div class="message-pad _preview_table" style="background-color:white">' +
          '<p><b>Most severe consequence:</b> ' + renderConsequence(results['most_severe_consequence']) + '</p>' +
          ( results['colocated_variants']
            ? '<p><b>Colocated variants:</b> ' + $.map(results['colocated_variants'], function(variant) {
                return renderZmenuLink(panel.previewInp.species, 'Variation', variant.id, variant.id) + (variant['minor_allele_freq'] ? ' <i>(MAF: ' + variant['minor_allele_freq'] + ')</i>' : '');
              }).join(', ') + '</p>'
            : ''
          ) +
        '</div>' +
      '</div>' +
      '<p class="small"><b>Note:</b> the above is a preview of results using the <i>' +
        this.previewInp.species.replace('_', ' ') +
        '</i> Ensembl transcript database and does not include all data fields present in the full results set. Please submit the job using the Run button below to obtain these.</p>'
    );

    // beginnings of table row
    var tableRows = [];

    // add table columns from transcript consequences
    if (results['transcript_consequences']) {
      $.merge(tableRows, $.map(results['transcript_consequences'], function(cons) {
        var cols = [];
        cols.push('<p class="no-bottom-margin"><b>'
          + renderZmenuLink(panel.previewInp.species, 'Gene', cons.gene_id, cons.gene_symbol || cons.gene_id)
          + '</b>: '
          + renderZmenuLink(panel.previewInp.species, 'Transcript', cons.transcript_id, cons.transcript_id)
          + '</p>'
          + '<p class="small no-bottom-margin"><b>Type: </b>' + cons.biotype + '</p>'
        );
        cols.push(cons.consequence_terms.map(function(a) { return renderConsequence(a) }).join(', '));

        // add details column
        var details = [];
        if (cons['amino_acids']) {
          details.push('<b>Amino acids:</b> ' + cons.amino_acids);
        }
        if (cons['sift_prediction']) {
          details.push('<b>SIFT:</b> ' + cons.sift_prediction);
        }
        if (cons['polyphen_prediction']) {
          details.push('<b>PolyPhen:</b> ' + cons.polyphen_prediction);
        }
        if (cons['distance']) {
          details.push('<b>Distance to transcript:</b> ' + cons.distance + 'bp');
        }
        if (!details.length) {
          details = ['-'];
        }

        cols.push($.map(details, function(detail) { return '<p class="no-bottom-margin">' + detail + '</p>' }));

        return [ cols ];
      }));
    }

    // add table columns from regulatory consequences
    if (results['regulatory_feature_consequences']) {
      $.merge(tableRows, $.map(results['regulatory_feature_consequences'], function(cons) {
        return [
          '<b>' + renderZmenuLink(panel.previewInp.species, 'RegulatoryFeature', cons.regulatory_feature_id, cons.regulatory_feature_id) + '</b>'
            + '<br/><span class="small"><b>Type: </b>' + cons.biotype + '</span>',
          cons.consequence_terms.map(function(a) { return renderConsequence(a) }).join(', '),
          '-'
        ];
      }));
    }

    // add table, but only if there is data in it
    if (tableRows.length) {
      this.elLk.previewDiv.find('._preview_table').append(generateTable(['Gene/Feature/Type', 'Consequence', 'Details'], tableRows));
    }

    // add info telling user this is not the full result set
    this.elLk.previewDiv
      .find('a.zmenu').on('click', function(e) {
        e.preventDefault();
        Ensembl.EventManager.trigger('makeZMenu', this.innerHTML.replace(/\W/g, '_'), { event: e, area: {link: $(this)}});
      }).end()
      .find('._ht').helptip().end()
      .find('._close_button').on('click', function() { panel.elLk.previewDiv.empty(); });
  },

  previewError: function(message) {
    this.elLk.previewDiv.html('<p><img src="/i/16/alert.png" style="vertical-align:middle" alt="" />&nbsp;<b>Unable to generate preview:</b> ' + message + '</p>');
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

      this.elLk.dataField.trigger('change');
    }
  },

  reset: function() {
  /*
   * Resets the form, ready to accept next job input
   */
    this.base.apply(this, arguments);
    this.elLk.form.find('._download_link').remove();
    this.elLk.previewDiv.empty().hide();
    this.elLk.previewButton.hide();
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
