/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2022] EMBL-European Bioinformatics Institute
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

    this.resetSpecies(this.defaultSpecies);

    this.consequencesData = this.params['consequences_data'];
    delete this.params['consequences_data'];
    
    this.exampleData = this.params['example_data'];
    delete this.params['example_data'];

    // this.autocompleteData = this.params['plugin_auto_values'];
    // delete this.params['plugin_auto_values'];

    var panel = this;
    this.speciesname_map = this.params['speciesname_mapping'];

    // Only display the gencode option for Human and Mouse
    var species_classes = '_stt_Homo_sapiens _stt_Mus_musculus';
    panel.elLk.form.find('input[name=core_type]').each(function(index) {
      if ($(this).val() == 'gencode_basic') {
        var radio_item = $(this).parent();
        radio_item.addClass(species_classes);
      }
      else {
        var updated_label = $(this).next().html().replace('Ensembl ', 'Ensembl<span class="'+species_classes+'">/GENCODE</span> ');
        $(this).next().html(updated_label);
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

    // Preview button
    this.elLk.previewButton = panel.elLk.form.find('[name=preview]').hide().on('click', function(e) {
      e.preventDefault();
      panel.enablePreviewButton(false);
      panel.preview($(this).data('currentVal'), { left : e.pageX, top : e.pageY });
    });

    // Preview div
    this.elLk.previewDiv = $('<div class="vep-preview-div">').appendTo($(document.body));

    // show hide preview button acc to the text in the input field
    this.elLk.dataField = this.elLk.form.find('textarea[name=text]').on({
      'paste keyup click change focus scroll': function(e) {
        panel.dataFieldInteraction(e.type);
      }
    });

    // move preview button after the textarea
    this.elLk.previewButton.appendTo(this.elLk.dataField.parent());

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

    // finally add a validate event to the form which gets triggered before submitting it
    this.elLk.form.on('validate', function(e) {
      if (!panel.getSelectedSpecies().length) {
        panel.showError('Please select a species to run VEP against.', 'No species selected');
        $(this).data('valid', false);
        return;
      }
      if ($.trim($(this).find('.vep-input').val()) == "" && $(this).find('.ffile').val() == "" && $(this).find('.ftext.url ').val() == "" ) {
        panel.showError('Please provide an input.', 'No input found');
        $(this).data('valid', false);
        return;
      }
    });
  },

  dataFieldInteraction: function(eventType) {
  /*
   * Acts according to the event occurred on the textare input
   */
    var panel = this;
    var value = this.elLk.dataField[0].value;
    var bgPos = Ensembl.browser.webkit ? 13 : 15;

    this.elLk.dataField.removeClass('focused');
    this.elLk.previewButton.hide();

    if (this.elLk.dataField.data('previousValue') !== value) {
      this.elLk.dataField.data('previousValue', value);
      this.elLk.dataField.data('inputFormat', (function(value) {
        var format = panel.detectFormat(value.split(/[\r\n]+/)[0]);
        if (format === 'id' || format === 'vcf' || format === 'ensembl' || format === 'hgvs' || format === 'spdi') {
          return format;
        }
        return false;
      })(value));
    }

    if (!this.dataFieldHeight) {
      this.dataFieldHeight = this.elLk.dataField.height();
    }


    if (value.length) {
      var format = this.elLk.dataField.data('inputFormat');

      if (format) {
        if (!this.elLk.fakeDataField) {
          this.elLk.fakeDataField = $('<div class="vep-input-div">').appendTo(this.elLk.form);
        }
        var pos   = this.elLk.dataField.prop('selectionStart');
        var curr  = value.substr(0, pos).replace(/.+[\r\n]/g, '') + value.substr(pos).replace(/[\r\n].+/g, '');

        if (curr.length) {
          var height = this.elLk.fakeDataField.html(value.substr(0, pos) + 'x').show().height() - bgPos - this.elLk.dataField.scrollTop();
          this.elLk.fakeDataField.hide();
          this.elLk.dataField.addClass('focused').css('background-position', '0 ' + height + 'px');
          this.elLk.previewButton.show().css('margin-top', Math.max(Math.min(height, this.dataFieldHeight - bgPos), 0) + 1).data('currentVal', curr);
        }
      }
    }
  },

  preview: function(val, position) {
  /*
   * renders VEP results preview
   */
    if (!val) {
      return;
    }
    // Remove potential new line and carriage return characters
    val = val.replace(/[\r\n]/g, '');

    // reset preview div
    this.elLk.previewDiv.empty().removeClass('active').addClass('loading').css(position);

    // get input, format and species
    this.previewInp = {};
    this.previewInp.input   = val;
    this.previewInp.format  = this.detectFormat(val);
    this.previewInp.species = this.speciesname_map[this.elLk.form.find('input[name=species]').val()]; //Convert species_url to production_name before calling REST
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

        url = this.previewInp.baseURL + '/region/' + c + ':' + s + '-' + e + ':' + 1 + '/' + a;
        break;

      case "spdi":
        var arr = this.previewInp.input.split(/:/);
        var c = arr[0];
        var r = (arr[2] == '') ? '-' : arr[2];
        var a = (arr[3] == '') ? '-' : arr[3];

        // 0 based coordinate format
        var s = parseInt(arr[1])+1;
        var e = s + (r.length - 1);

        url = this.previewInp.baseURL + '/region/' + c + ':' + s + '-' + e + ':' + 1 + '/' + a;
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

    // region: chr21:10-10:1/A
    if (
      data.length === 1 &&
      data[0].match(/^([^:]+):(\d+)-(\d+)(:[-\+]?1)?[\/:]([a-z]{3,}|[ACGTN-]+)$/i)
    ) {
      return 'region';
    }

    // SPDI: 1:230710044:A:G
    else if (
      data.length === 1 &&
      data[0].match(/^(.*?\:){2}([^\:]+|)$/i)
    ) {
      return 'spdi';
    }

    // CAID: CA9985736
    else if (
      data.length === 1 &&
      data[0].match(/^CA\d{1,}$/i)
    ) {
      return 'spdi';
    }

    // HGVS: ENST00000285667.3:c.1047_1048insC
    else if (
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
      data[3].match(/^[ACGTN\-\.]+$/i)
    ) {
      return 'vcf';
    }

    // ensembl: 20  14370  14370  A/G  +
    else if (
      data.length >= 4 &&
      data[0].match(/\w+/) &&
      data[1].match(/^\d+$/) &&
      data[2].match(/^\d+$/) &&
      data[3].match(/([a-z]{2,})|([ACGTN-]+\/[ACGTN-]+)/i)
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
      return panel.consequencesData[con] ? $('<nobr>').append(
        $('<span>').addClass('colour').css('background-color', panel.consequencesData[con]['colour']).html('&nbsp'),
        $('<span>').html('&nbsp;'),
        $('<span>').attr({'class': '_ht ht margin-left', title: panel.consequencesData[con]['description']}).html(con)
      ).wrap('<div>').parent().html() : '';
    };

    // function to render link as ZMenu link
    var renderZmenuLink = function(species, type, id, label) {
      return $('<a>').attr({'class': 'zmenu', 'href': '/' + species + '/ZMenu/' + type + '?' + type.replace(/[a-z]/g, '').toLowerCase() + '=' + id}).html(label).wrap('<div>').parent().html();
    };

    // HTML for preview content
    this.elLk.previewDiv.removeClass('loading').html(
      '<div class="hint">' +
        '<h3><img src="/i/close.png" alt="Hide" class="_close_button" title="">Instant results for ' + this.previewInp.input + '</h3>' +
        '<div class="message-pad">' +
          '<div class="warning">' +
            '<h3>Instant VEP</h3>' +
            '<div class="message-pad">' +
              '<p>The below is a preview of results using the <i>' + this.previewInp.species.replace('_', ' ') +
              '</i> Ensembl transcript database and does not include all data fields present in the full results set. ' +
              'To obtain these please <b>close this preview window and submit the job using the <a class="button">Run</a> button below</b>.</p>' +
            '</div>' +
          '</div>' +
          '<p><b>Most severe consequence:</b> ' + renderConsequence(results['most_severe_consequence']) + '</p>' +
          ( results['colocated_variants']
            ? '<p><b>Colocated variants:</b> ' + $.map(results['colocated_variants'], function(variant) {
                return renderZmenuLink(panel.previewInp.species, 'Variation', variant.id, variant.id) + (variant['minor_allele_freq'] ? ' <i>(MAF: ' + variant['minor_allele_freq'] + ')</i>' : '');
              }).join(', ') + '</p>'
            : ''
          ) +
          '<div class="vep-preview-table _preview_table"></div>' +
        '</div>' +
      '</div>'
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
        return [[
          '<b>' + renderZmenuLink(panel.previewInp.species, 'RegulatoryFeature', cons.regulatory_feature_id, cons.regulatory_feature_id) + '</b>'
            + '<br/><span class="small"><b>Type: </b>' + cons.biotype + '</span>',
          cons.consequence_terms.map(function(a) { return renderConsequence(a) }).join(', '),
          '-'
        ]];
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
      .find('._close_button').on('click', function() {
        panel.elLk.previewDiv.empty();
        panel.enablePreviewButton();
      });

    // fix preview div's position and dimensions
    this.elLk.previewDiv.addClass('active');
  },

  previewError: function(message) {
  /*
   * Show error regarding the vep preview in an alert box
   */
    this.elLk.previewDiv.removeClass('active loading');
    this.enablePreviewButton();
    alert("Unable to generate preview:\n" + message);
  },

  enablePreviewButton: function(flag) {
  /*
   * Enable/disable preview button
   */
    if (flag === false) {
      this.elLk.previewButton.addClass('disabled').prop('disabled', true);
    } else {
      this.elLk.previewButton.removeClass('disabled').removeAttr('disabled');
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
    }
  },

  reset: function() {
  /*
   * Resets the form, ready to accept next job input
   */
    this.base.apply(this, arguments);
    this.elLk.form.find('._download_link').remove();
    this.elLk.dataField.removeClass('focused');
    this.elLk.previewDiv.empty().removeClass('active loading');
    this.elLk.previewButton.hide();
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
