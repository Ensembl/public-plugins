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
 * DbFrontend base class for all the JS classes that share similar structure with in-line editing features
 */

Ensembl.DbFrontend = Base.extend({

  // constructor initialises the el by manipulating the events on the buttons inside it
  constructor: function(el, panel) {
    var self    = this;
    this.panel  = panel;
    this.el     = $(el);
    $(this.el).off('click').on('click', '._dbf_button, ._dbf_edit', function(event) {
      event.preventDefault();
      self.buttonClick(this);
    });
  },

  // wrapper method around ajax
  makeRequest: function(eventTarget, responseTarget, options) {
    var self = this;
    if (this.ajax) {
      this.ajax.abort();
      this.ajax = false;
    }
    this.showLoading(responseTarget);
    var isForm = eventTarget.nodeName === 'FORM';
    var data   = options.data || (isForm ? $(eventTarget).serialize() : {});
    this.ajax  = $.ajax($.extend({
      url       : eventTarget.action || eventTarget.href || '',
      type      : isForm ? 'POST' : 'GET',
      dataType  : 'json',
      context   : this,
      error     : function() { this.showError(responseTarget, '', this.el); },
      complete  : function() { this.showLoading(responseTarget, false); }
    }, options, { //any value provided in options overrides the default ones above
      data      : typeof(data) === 'string' ? data + '&_ajax=1' : $.extend(data, {_ajax: 1})
    }));
  },

  //method to show/hide a 'Loading' message
  showLoading: function(target, flag) {
    if (flag === false) {
      target.removeClass('spinner');
    } else {
      target.empty().show().addClass('spinner');
    }
  },

  //method to parse the response json and return the required html node (jquery object)
  getResponseNode: function(json) {
    return $('._dbf_response', $('<div>').html(json.content));
  },
  
  // method to show error
  showError: function(target, message, el) {
    if (target) {
      target.html('<p class="dbf-error">' + (message || 'An error occurred at the server. Please try again.') + '</p>');
    }
    if (el) {
      el.show();
    }
  },

  // method to create form's wrapping element
  createForm: function() {
    if (!this.form) {
      this.form = $('<div>').insertAfter(this.el).hide();
    }
  },

  // initialises the form and binds live events to the form and its buttons
  initForm: function() {

    if (!this.formInitialised) {

      this.createForm();
      this.formInitialised = true;
      
      var self = this;
      
      var eventMapper = [
        ['._dbf_cancel',                  'click',  'cancelButtonClick'],
        ['form._dbf_preview',             'submit', 'previewFormSubmit'],
        ['form._dbf_save, form._dbf_add', 'submit', 'formSubmit'       ],
        ['._dbf_delete',                  'click',  'deleteButtonClick']
      ];
      
      $.each(eventMapper, function() {
        var eventMap = this;
        $(self.form).on(eventMap[1], eventMap[0], function (event) {
          event.preventDefault();
          self[eventMap[2]](this);
        });
      });
    
    }

    Ensembl.EventManager.trigger('validateForms', this.form);
    this.initDataStructure(this.form);
  },
  
  //initialises any Datastructure element inside the given element
  initDataStructure: function(el) {
    el.find('._datastructure').datastructure();
  },

  buttonClick:        function(button)  {},   // Edit/Delete/Duplicate link's click event
  cancelButtonClick:  function(button)  {},   // Cancel button's click event
  previewFormSubmit:  function(form)    {},   // Submit event of the form for previewing changes
  formSubmit:         function(form)    {},   // Submit event for the form
  deleteButtonClick:  function()        {},   // Event for delete button click
  afterResponse:      function(success) {}    // method to do some modification just after the ajax response processed
});


Ensembl.Panel.DbFrontend = Ensembl.Panel.extend({

  init: function() {
    this.base();
    var self = this;
    
    this.el.find('._dbf_record').each(function() {
      self.initRow(this);
    })
  },
  
  initRow: function(row) {}                     // method to initialise a row
});
