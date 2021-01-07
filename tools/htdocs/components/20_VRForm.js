/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

Ensembl.Panel.VRForm = Ensembl.Panel.ToolsForm.extend({

  init: function() {
    this.base();

    this.resetSpecies(this.defaultSpecies);

    this.exampleData = this.params['example_data'];
    delete this.params['example_data'];

    var panel = this;

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
    // Needed to resubmit job
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
        //panel.dataFieldInteraction(e.type);
      }
    });

    // move preview button after the textarea
    this.elLk.previewButton.appendTo(this.elLk.dataField.parent());

    this.editExisting();

    // initialise the selectToToggle fields ie. show or hide the ones as needed
    this.resetSelectToToggle();
  },

  /*dataFieldInteraction: function(eventType) {
   *
   * Acts according to the event occurred on the textare input
   *
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
  },*/

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

      if (!this.elLk.speciesDropdown.find('input:checked').length) {
        this.elLk.speciesDropdown.find('input[type=radio]').first().click();
      }

      this.resetSpecies(jobsData['species']);

      this.elLk.dataField.trigger('change');
    }
  },

  /*reset: function() {
   *
   * Resets the form, ready to accept next job input
   *
    this.base.apply(this, arguments);
    this.elLk.form.find('._download_link').remove();
    this.elLk.dataField.removeClass('focused');
    this.elLk.previewDiv.empty().removeClass('active loading');
    this.elLk.previewButton.hide();
    this.resetSpecies(this.defaultSpecies);
    this.resetSelectToToggle();
  },*/

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