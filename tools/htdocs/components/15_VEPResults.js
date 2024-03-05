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

Ensembl.Panel.VEPResults = Ensembl.Panel.ContentTools.extend({
  init: function () {
    var panel = this;

    this.base();

    // Initialise ZMenus on table links
    this.el.find('a._zmenu').zMenuLink();

    // Edit icon and Cancel link for editing a filter
    this.el.find('a.filter_toggle').on('click', function(e) {
      e.preventDefault();
      panel.el.find('.' + this.rel).toggle();
    });

    // Autocomplete input box
    this.el.find('input.autocomplete').on('focus', function() {
      var fieldNum    = this.name.replace('field', '').replace('value', '');
      var fieldName   = panel.el.find('select[name=field' + fieldNum + '] option:selected').val();
      var fieldInp    = panel.el.find('input[name=value' + fieldNum + ']');
      var autoValues  = $.parseJSON(panel.params['auto_values']);

      if (autoValues[fieldName] && autoValues[fieldName].length) {

        fieldInp.autocomplete({
          minLength : 0,
          source    : autoValues[fieldName]
        });

      } else if (fieldInp.hasClass('ui-autocomplete-input')) {
        fieldInp.autocomplete('destroy');
      }

      fieldInp.attr('placeholder', fieldName === 'Location' ? 'chr:start-end' : 'defined');

      fieldInp = null;
    });

    // refresh panel on form submit
    this.el.find('form._apply_filter').on('submit', function(e) {
      e.preventDefault();

      var form      = $(this);
      var ajaxUrl   = form.find('input[name=ajax_url]').remove().val();
      var urlParams = $.map(form.serializeArray(), function(field) { return field.name + '=' + field.value; }).sort().join(';');

      panel.reload(window.location.href.split('?')[0] + '?' + urlParams, ajaxUrl + (ajaxUrl.match(/\?/) ? ';' : '?') + urlParams);
    });

    // links to display n number of results in the table
    this.el.find('a._reload').on('click', function(e) {
      e.preventDefault();
      panel.reload(this.href, $(this).find('input').val());
    });

    // switch textbox to dropdown for "in file" operator
    this.el.find('select._operator_dd').on('change', function(e) {
      $(this).parent().find('input._value_switcher').toggle(this.value !== 'in');
      $(this).parent().find('span._value_switcher').toggle(this.value === 'in');
    });

    // activate horizontal scrolling on the table
    this.el.find('.data_table').scrollyTable();
  },

  reload: function(url, ajaxUrl) {
    this.toggleSpinner(true);
    this.updateLocation(url);
    this.getContent(ajaxUrl, this.el.addClass('no-spinner'), null, true, { background: true }); // since we have our own spinner, we add this class to hide the Content panel's spinner
  },

  destructor: function() {
    this.toggleSpinner(false);
    this.base.apply(this, arguments);
  }
});
