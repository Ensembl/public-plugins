/*
 * DbFrontend base class for all the JS classes that share similar structure with in-line editing features
 */

Ensembl.DbFrontend = Base.extend({

  // constructor initialises the el by manipulating the events on the buttons inside it
  constructor: function(el, panel) {
    var self   = this;
    this.panel = panel;
    this.el = $(el);
    $('._dbf_button', this.el).die('click').live('click', function(event) {
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
      error     : function() { self.showError(responseTarget, '', this.el); },
      complete  : function() { self.showLoading(responseTarget, false); }
    }, options, { //any value provided in options overrides the default ones above
      data      : typeof(data) === 'string' ? data + '&_ajax=1' : $.extend(data, {_ajax: 1})
    }));
  },

  //method to show/hide a 'Loading' message
  showLoading: function(target, flag) {
    if (flag === false) {
      $(target).removeClass('spinner');
    }
    else {
      $(target).empty().show().addClass('spinner');
    }
  },

  //method to parse the response json and return the required html node (jquery object)
  getResponseNode: function(json) {
    return $('._dbf_response', $('<div>').html(json.content));
  },
  
  //method to force the newly loaded forms to be validated before being submitted
  validateForms: function(formWrapper) {
    Ensembl.EventManager.trigger('validateForms', formWrapper);
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
    return $('<div>').insertAfter(this.el).hide();
  },

  // initialises the form and binds live events to the form and its buttons
  initForm: function() {
    var self = this;
    if (this.form) {
      return;
    }
    this.form = this.createForm();
    
    var eventMapper = [
      ['._dbf_cancel',                  'click',  'cancelButtonClick'],
      ['form._dbf_preview',             'submit', 'previewFormSubmit'],
      ['form._dbf_save, form._dbf_add', 'submit', 'formSubmit'],
      ['._dbf_delete',                  'click',  'deleteButtonClick']
    ];
    
    $.each(eventMapper, function() {
      var eventMap = this;
      $(eventMap[0], self.form).live(eventMap[1], function (event) {
        event.preventDefault();
        self[eventMap[2]](this);
      });
    });
  },

  buttonClick: function(button) {},         // Edit/Delete/Duplicate link's click event
  cancelButtonClick: function(button) {},   // Cancel button's click event
  previewFormSubmit: function(form) {},     // Submit event of the form for previewing changes
  formSubmit: function(form) {},            // Submit event for the form
  afterResponse: function(success) {}       // method to do some modification just after the ajax response processed
});


Ensembl.Panel.DbFrontend = Ensembl.Panel.extend({

  init: function() {
    this.base();
    var self = this;
    $('._dbf_record', this.el).each(function() {
      self.initRow(this);
    })
  },
  
  initRow: function(row) {}                     // method to initialise a row
});
