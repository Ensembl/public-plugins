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

/*
 * Base form for all tools forms
 */

Ensembl.Panel.ToolsForm = Ensembl.Panel.ContentTools.extend({

  constructor: function() {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('toolsToggleForm', this, this.toggleForm);
    Ensembl.EventManager.register('toolsEditTicket', this, this.loadTicket);

    this.loadTicketURL  = '';
    this.submitDisabled = false;
  },

  init: function() {

    var panel = this;

    this.base();

    // 'Add new' button (make link visible by default)
    this.elLk.buttonDiv = this.el.find('._tool_new').show().on('click', 'a', function(e) {
      e.preventDefault();
      panel.toggleForm(true, true);
    });

    // Actual form div
    this.elLk.formDiv = this.el.find('._tool_form_div');

    // Form submit event
    this.elLk.form = this.elLk.formDiv.find('form._tool_form').on({
      'submit': function(e) {
        e.preventDefault();
        var form = $(this).data('valid', true).trigger('validate'); // add a 'validate' event handler in the form and set 'valid' data as false if it fails validation
        if (form.data('valid')) {
          panel.ajax($.extend({
            'url'       : this.action,
            'method'    : 'post',
            'spinner'   : true
          }, window.FormData === undefined ? {
            'iframe'      : true,
            'form'        : $(this)
          } : {
            'data'        : new FormData(this),
            'cache'       : false,
            'contentType' : false,
            'processData' : false
          }));
        }
      }
    });

    // URL to load a ticket
    this.loadTicketURL = this.elLk.form.find('input[name=load_ticket_url]').remove().val();

    // Reset & Cancel form buttons
    this.elLk.cancelButton = this.elLk.form.find('a._tools_form_reset, a._tools_form_cancel').on('click', function(e) {
      var isCancel = !!this.className.match(/cancel/);
      e.preventDefault();
      panel.toggleSpinner(true);
      window.setTimeout(function() {
        if (!isCancel) {
          panel.reset();
        } else {
          panel.toggleForm(false, true);
        }
        panel.toggleSpinner(false);
      }, 100); // :(
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
    var editingJobsData       = [];
    try {
      editingJobsData         = $.parseJSON(this.elLk.form.find('input[name=edit_jobs]').remove().val());
    } catch (ex) {}
    if (editingJobsData.length) {
      this.populateForm(editingJobsData, noReset);
      return true;
    }
    return false;
  },

  populateForm: function(jobsData, noReset) {
  /*
   * Populate the input form from the given map of param name to value
   */
    if (jobsData) {
      if (!noReset) {
        this.reset();
      }
      for (var paramName in jobsData) {
        var vals  = $.isArray(jobsData[paramName]) ? jobsData[paramName] : [ jobsData[paramName] ];
        var flag  = function() { return $.inArray(this.value, vals) >= 0; }

        this.elLk.form.find('[name=' + paramName + ']')
          .filter('input[type=text], textarea').val(vals[0]).end()
          .filter('[type=checkbox], [type=radio]').prop('checked', flag).end()
          .filter('select').find('option').prop('selected', flag);

        this.toggleForm(true, true);
      }
      this.resetSelectToToggle();
    }
  },

  ticketSubmitted: function() {
  /*
   * Method called once ticket is successfully submitted via AJAX
   */
    Ensembl.EventManager.trigger('toolsRefreshActivitySummary', true, true, false);
    this.toggleForm(false, true);
  },

  toggleForm: function(flag, showCancel) {
  /*
   * Shows/hides the form, and does the opposite to the 'add new' link
   */
    if (!flag) {
      this.reset();
    }
    this.elLk.buttonDiv.toggle(!flag);
    this.elLk.formDiv.clearQueue()[flag ? 'slideDown' : 'slideUp'](200);
    if (typeof showCancel === 'boolean') {
      this.elLk.cancelButton.toggle(showCancel);
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
    this.resetSelectToToggle();
  },

  resetSelectToToggle: function() {
  /*
   * Shows/hides the html blocks according to the selectToToggle elements (only needed if values changed via JS)
   */
    this.elLk.form.find('._stt').selectToToggle('trigger');
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

Ensembl.Panel.ToolsForm.SubElement = Base.extend({
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

Ensembl.Panel.ToolsForm.Dropdown = Ensembl.Panel.ToolsForm.SubElement.extend({ // TODO - modify the selectToToggle jQuery plugin to support this behaviour by default
/*
 *  No browser other than firefox allows to hide an option,
 *  so this class makes it easy to remove the options from a dropdown,
 *  and put them back in if needed.
 */
  constructor: function(el, panel) {
    this.el       = el;
    this.panel    = panel;
    this.children = this.el.children().clone();
  },

  reset: function() {
    var selectedValue = this.el.find('option:selected').val();
    this.el.empty().append(this.children.clone()).find('[value="' + selectedValue + '"]').prop('selected', true);
  },

  triggerSelectToToggle: function() {
    if (this.el.hasClass('_stt')) {
      this.el.selectToToggle('trigger');
      this.panel.adjustDivsHeight();
    }
  },

  removeDisabledOptions: function() {
    this.el.find('option:not(:enabled)').remove().end().find('optgroup:empty').remove();
  }
});

Ensembl.Panel.ToolsForm.SpeciesTag = Ensembl.Panel.ToolsForm.SubElement.extend({
  constructor: function(el, panel, existingTag, species) {
    var self = this;
    this.panel = panel;
    if (!el) {
      el = existingTag.el.clone().appendTo(existingTag.el.parent()).find('span').first().html(species.caption).end().end().find('input').val(species.value).end();
      el.css('backgroundImage', el.css('backgroundImage').replace(/[^\/]+\.png/, species.value + '.png'));
      this.species = species.value;
    } else {
      this.species = el.find('input').val();
    }
    this.el = el.find('span').last().on('click', function() {
      panel.elLk.speciesDropdown.find('input[value="' + self.species + '"]').prop('checked', false);
      panel.refreshSpecies();
    }).end().end();
  },

  disable: function(flag) {
    this.disabled = flag;
    this.el.toggleClass('disabled', flag);
  },

  remove: function() {
    this.el.remove();
    this.el = this.disabled = null;
  },

  setRemovable: function(flag) {
    this.el.find('span').last().toggle(flag);
  }
});
