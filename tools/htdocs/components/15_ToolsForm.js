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

/*
 * Base form for all tools forms
 */

Ensembl.Panel.ToolsForm = Ensembl.Panel.ContentTools.extend({

  constructor: function() {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('toolsToggleForm', this, this.toggleForm);
    Ensembl.EventManager.register('toolsEditTicket', this, this.loadTicket);
    Ensembl.EventManager.register('resetSelectToToggle', this, this.resetSelectToToggle);
  },

  init: function() {

    var panel = this;

    this.base.apply(this, arguments);

    this.loadTicketURL  = this.params['load_ticket_url'];    // URL to load a ticket
    this.defaultSpecies = this.params['species'];

    // 'Add new' button
    this.elLk.buttonDiv = this.el.find('._tool_new').on('click', 'a', function(e) {
      e.preventDefault();
      Ensembl.EventManager.trigger('toolsHideTicket');
      panel.toggleForm(true, true);
    });

    // Actual form div
    this.elLk.formDiv = this.el.find('._tool_form_div');

    // Form submit event
    this.elLk.form = this.elLk.formDiv.find('form._tool_form').on({
      'submit': function(e) {

        // Fixing empty filename issue (in safari, but not checking if browser is safari because it doesn't do any harm in general)
        // Disable it before form submit and then enable it.
        $('input[type="file"]', this)
        .filter(function() {
            return !this.value;
        }).prop("disabled", true);

        e.preventDefault();
        var form = $(this).data('valid', true).trigger('validate'); // add a 'validate' event handler in the form and set 'valid' data as false if it fails validation

        if (form.data('valid')) {
          if(window.FormData) { // WebKit #184490
            panel.ajax($.extend({
              'url'       : this.action,
              'method'    : 'post',
              'spinner'   : true
            },{
              'data'        : new FormData(this),
              'cache'       : false,
              'contentType' : false,
              'processData' : false
            }));
          } else {
            panel.ajax($.extend({
              'url'       : this.action,
              'method'    : 'post',
              'spinner'   : true
            },{
              'iframe'      : true,
              'form'        : $(this)
            }));
          }
        }
        $('input[type="file"]', this)
        .filter(function() {
            return !this.value;
        }).prop("disabled", false);

      }
    });

    // Reset & Cancel form buttons
    this.elLk.cancelButton = this.el.find('a._tools_form_reset, a._tools_form_cancel').on('click', function(e) {
      var isCancel = !!this.className.match(/cancel/);
      e.preventDefault();
      panel.toggleSpinner(true);

      if(isCancel) {
        panel.toggleForm(false);
        panel.toggleSpinner(false);
      } else {
        window.setTimeout(function() {
          panel.reset();
          panel.toggleSpinner(false);
        }, 100);
      }
    }).filter('._tools_form_cancel');

    // Height adjustable divs
    this.elLk.adjustableDivs = this.elLk.form.find('div._adjustable_height').css('minHeight', function() { return $(this).height(); });

    // if there is no job in the ticket list, then show the form
    Ensembl.EventManager.trigger('toolsToggleEmptyTable');
  },

  editExisting: function(noReset) {
  /*
   * Checks and populates the form with existing job if job data present as a hidden input
   * @return true if existing job present, false otherwise
   */
    var editingJobsData = this.params['edit_jobs'];
    if (editingJobsData && editingJobsData.length) {
      this.populateForm(editingJobsData, noReset);
      return true;
    }
    return false;
  },

  populateForm: function(jobsData, noReset) {
  /*
   * Populate the input form from the given map of param name to value
   */
    if (jobsData && jobsData.length) {
      if (!noReset) {
        this.reset();
      }
      for (var paramName in jobsData[0]) {
        var vals  = $.isArray(jobsData[0][paramName]) ? jobsData[0][paramName] : [ jobsData[0][paramName] ];
        var flag  = function() { return $.inArray(this.value, vals) >= 0; }

        this.elLk.form.find('[name=' + paramName + ']')
          .filter('input[type=text], textarea').val(vals[0]).end()
          .filter('[type=checkbox], [type=radio]').prop('checked', flag).end()
          .filter('select').find('option').prop('selected', flag);

        this.toggleForm(true);
      }
      this.resetSelectToToggle();
    }
  },

  getSelectedSpecies: function() {
  /*
   * Returns an array of species with checked checkboxes
   */
    if (this.elLk.form.find('input[name=species]').length > 0) {
      // for new species selector
      return this.elLk.form.find('input[name=species]').filter(':checked').map(function() { return this.value; } ).toArray();
    }
    else if (this.elLk.form.find('select[name=species]').length > 0) {
      // This is for bacteria which uses ajax select dropdown
      return this.elLk.form.find('select[name=species] option:selected').val();
    }
    return [];
  },

  ticketSubmitted: function() {
  /*
   * Method called once ticket is successfully submitted via AJAX
   */
    Ensembl.EventManager.trigger('toolsRefreshActivitySummary', true, true, false);
    this.toggleForm(false, true);
  },

  ticketNotSubmitted: function (error) {
  /*
   * Method called if ticket submission fails
   */
    this.showError(error.message, error.heading);
    if (error.stage === 'dispatcher') {
      Ensembl.EventManager.trigger('toolsRefreshActivitySummary', true, true, false);
    }
  },

  toggleForm: function(flag, toggleCloseButton) {
  /*
   * Shows/hides the form, and does the opposite to the 'add new' link
   */
    if (!flag) {
      this.reset();
    }
    this.elLk.buttonDiv.toggle(!flag);
    this.el.find('div.tool-header').toggle(flag);
    this.elLk.formDiv[flag ? 'slideDown' : 'slideUp'](200);
    if (typeof toggleCloseButton === 'boolean') {
      this.elLk.cancelButton.toggle(toggleCloseButton);
      this.el.find('div.tool-header span.right-button').toggle(toggleCloseButton);
    }
  },

  loadTicket: function(ticketName) {
  /*
   * Load a ticket by doing an AJAX request
   */
    this.ajax({
      'url'       : this.loadTicketURL.replace('TICKET_NAME', ticketName),
      'spinner'   : true
    });

    this.scrollIn();

    return true;
  },

  reset: function() {
  /*
   * Reset the form
   */
    this.elLk.form[0].reset();
  },

  resetSelectToToggle: function(tMap) {
  /*
   * Shows/hides the html blocks according to the selectToToggle elements (only needed if values changed via JS)
   */
    this.elLk.form.find('._stt').selectToToggle(tMap||{}, this.el);
  },

  adjustDivsHeight: function() {
  /*
   * Adjusts heights of the selected divs according to the height of their current contents
   */
    this.elLk.adjustableDivs.clearQueue().each(function() {
      $(this).css({'minHeight': $(this).height()}).animate({'minHeight': 0}, '1000', 'easeInExpo', function() {
        $(this).css({'minHeight': $(this).height()});
      });
    });
  }
});

Ensembl.Class.ToolsFormSubElement = Base.extend({
/*
 * Base class for all sub elements
 */
  constructor: function() {
    this.elLk = {};
  },
  destructor: function() {
    var i;
    for (i in this.elLk) {
      this.elLk[i].remove();
      this.elLk[i] = null;
    }
    for (i in this) {
      this[i] = null;
    }
  }
});
