/* JavaScript for DbFrontend page
 * Script overrides the standard actions of links and form submit buttons, to make use of AJAX to get html and submit forms
 * For any DbFrontend page using this javascript, check the following things to make if work properly:
 *  1. That the SiteDefs::OBJECT_TO_SCRIPT values for the page is 'Modal'
 *  2. Javascript classes are being added to the html elements properly
 *  3. The page which displays all the records return a single record if its 'id' is specified in GET params
 */

Ensembl.DbFrontendRow = Ensembl.DbFrontend.extend({

  // @override
  createForm: function() {
    return $('<div>').attr('class', 'dbf-inline-form').hide().insertAfter(this.el);
  },
  
  // @override
  getResponseNode: function(json) {
    return this.base(json).attr('class', '_dbf_form_wrap');
  },

  // @override
  buttonClick: function(button) {
    this.initForm();
    this.makeRequest(button, this.form, {
      success: function(json) {
        var self = this;
        this.form.append(this.getResponseNode(json));
        $('input[type="text"], input[type="password"], input[type="file"], textarea, select', this.form).first().focus();
        this.validateForms(this.form);
        window.setTimeout(function() {
          self.scrollIn({margin: 5});
        }, 0);
      }
    });
  },
  
  // @override
  previewFormSubmit: function(form) {
    this.scrollIn({margin: 5});
    var previewForm = this.form.children(':first').hide().next();
    this.makeRequest(form, previewForm.length ? previewForm : $('<div>').appendTo(this.form), {
      success: function(json) {
        this.form.children(':last').replaceWith(this.getResponseNode(json));
      }
    });
  },
    
  // @override
  cancelButtonClick: function(button) {
    var previous = $(button).parents('._dbf_form_wrap').prev()[0];
    if (previous) {
      $(previous).show().next().remove();
    }
    else {
      this.form.slideUp(function() {
        $(this).empty();
      });
    }
    this.scrollIn({margin: 5});
  },
  
  // @override
  deleteButtonClick: function(button) {
    this.makeRequest(button, this.form, {
      success: function(json) {
        if (json.redirectURL) {
          if (json.redirectURL.match(/Problem/)) {
            this.makeRequest({}, this.form, {
              async: false,
              url: json.redirectURL,
              success: function(json) {
                this.form.html(this.getResponseNode(json).html());
              }
            });
          } 
          else {
            this.form.slideUp('slow', function() {$(this).remove(); });
            this.el.slideUp('slow',   function() {$(this).remove(); });
            for (var i in this) {
              delete this[i];
            }
          }
        }
      }
    });
  },
  
  // @override
  formSubmit: function(form) {
    this.action = form.className.match(/_dbf_add/) ? 'add' : 'edit';
    this.target = this.el;
    this.makeRequest(form, this.form.children(':last'), {
      success: function(json) {
        if (json.redirectURL) {
          var url     = json.redirectURL;
          var problem = url.match(/Problem/);
          if (problem) {
            this.target = this.form.children().show().last();
          }
          else {
            this.form.empty().hide();
            if (this.action === 'add') {
              this.target = this.el.clone().empty().removeAttr('id').insertAfter(this.form);
            }
            var id = (url.match(/(\?|&|;)id\=([0-9]+)/) || []).pop() || 0;
            if (id) {
              url = window.location.href.split('#')[0];
              url = url + (url.match(/\?/) ? '&' : '?') + 'id=' + id;
            }
          }
          this.makeRequest({}, this.target, {
            async: false,
            url: url,
            success: function(json) {
              if (this.action === 'edit') {
                this.target.html(this.getResponseNode(json).html());
                if (!problem) {
                  this.target.children().effect('highlight', {'color': '#ddddff'}, 1000);
                }
              }
              else {
                this.panel.initRow(this.target.html(this.getResponseNode(json).html()));
              }
              this.afterResponse(!problem);
            }
          });
        }
      }
    });
  },

  // @override
  afterResponse: function(success) {
    this.scrollIn({margin: 5});
  },
  
  //method to scroll page to the record
  scrollIn: function(options) {
  
    var position   = 0;
    var formHeight = this.form.outerHeight();
    var formTop    = this.form.offset().top;
    var elHeight   = this.el.outerHeight();
    var elTop      = this.el.offset().top;
    var scrollTop  = $(document).scrollTop();
    var winHeight  = $(window).height();

    //if el hidden above scroll
    if (elTop - options.margin < scrollTop) {

      position = elTop - options.margin;

    //if form hidden below scroll
    }
    else if (formTop + formHeight + options.margin > scrollTop + winHeight) {

      //if el + form larger than window size
      if (elHeight + formHeight + options.margin * 2 > winHeight) {
        position = elTop - options.margin;
      }
      else {
        position = formTop + formHeight + options.margin -winHeight;
      }
    }
    
    if (position) {
      $('html,body').animate({ scrollTop: position}, options.speed);
    }
  }
});

Ensembl.Panel.DbFrontendRow = Ensembl.Panel.DbFrontend.extend({

  initRow: function(row) {
    new Ensembl.DbFrontendRow(row, this);
  }
});