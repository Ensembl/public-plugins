/* JavaScript for DbFrontend page
 * Script overrides the standard actions of links and form submit buttons, to make use of AJAX to get html and submit forms
 * For any DbFrontend page using this javascript, check the following things to make if work properly:
 *  1. That the SiteDefs::OBJECT_TO_SCRIPT values for the page is 'Modal'
 *  2. Javascript classes are being added to the html elements properly
 *  3. The page which displays all the records return a single record if its 'id' is specified in GET params
 */

Ensembl.Panel.DbFrontendRow = Ensembl.Panel.extend({

  init: function () {
    this.base();
    var self = this;

    this.id = (($('._dbf_button', this.el).attr('href') || '').match(/(\?|&|;)id\=([0-9]+)/) || []).pop();
    if (!this.id) {
      return;
    }
    this.form = $(document.createElement('div')).attr({'class': 'dbf-inline-form'}).hide().insertAfter(this.el);

    // Button's event - Edit and Delete button
    $('._dbf_button', this.el).live('click', function(event) {
      event.preventDefault();
      self.makeRequest(this, self.form, {
        success: function(json) {
          this.form.append(this.getResponseNode(json));
          this.bringToView({marginTop: 5});
          $('input[type="text"], input[type="password"], input[type="file"], textarea, select', this.form).first().focus();
          Ensembl.EventManager.trigger('validateForms', this.form);
        }
      });
    });
  
    // Cancel (or No) button's event
    $('._dbf_cancel', this.form[0]).live('click', function (event) {
      event.preventDefault();
      var previous = $(this).parents('._dbf_form_wrap').prev()[0];
      if (previous) {
        $(previous).show().next().remove();
      }
      else {
        self.form.slideUp(function() {
          $(this).empty();
        });
      }
      self.bringToView({marginTop: 5, downOnly: true});
    });

    // Submit event of the form for saving the data
    $('form._dbf_save', this.form[0]).live('submit', function(event) {
      event.preventDefault();
      self.makeRequest(this, self.form, {
        success: function(json) {
          if (json.redirectURL) {
            var url = json.redirectURL.match(/Display/) ? window.location + (window.location.href.match(/\?/) ? '&' : '?') + 'id=' + this.id : json.redirectURL;
            this.target = url.match(/Problem$/) ? this.form : $(this.el);
            if (this.target != this.form) {
              this.form.hide();
            }
            this.makeRequest(this, this.target, {
              async: false,
              url: url,
              success: function(json) {
                this.target.html(this.getResponseNode(json).html());
                this.bringToView({marginTop: 5, downOnly: true});
              }
            });
          }
        }
      });
    });
  
    // Submit event of the form for previewing the data
    $('form._dbf_preview', this.form[0]).live('submit', function(event) {
      event.preventDefault();
      self.form.children(':first').hide();
      self.makeRequest(this, $(document.createElement('div')).appendTo(self.form), {
        success: function(json) {
          this.form.children(':last').replaceWith(this.getResponseNode(json));
          this.bringToView({marginTop: 5, downOnly: true});
        }
      });
    });
  
    // 'Confirm Delete' button's event
    $('._dbf_delete', this.form[0]).live('click', function(event) {
      event.preventDefault();
      self.makeRequest(this, self.form, {
        success: function(json) {
          if (json.redirectURL) {
            if (json.redirectURL.match(/Problem$/)) {
              this.makeRequest(this, this.form, {
                async: false,
                url: json.redirectURL,
                success: function(json) {
                  this.form.html(this.getResponseNode(json).html());
                }
              });
            }
            else {
              this.form.slideUp('slow', function() {$(this).remove()});
              $(this.el).slideUp('slow',   function() {$(this).remove()});
              for (var i in this) {
                delete this[i];
              }
            }
          }
        }
      });
    });
  },

  // wrapper method for making an Ajax request
  makeRequest: function(eventTarget, target, options) {
    if (this.ajax) {
      this.ajax.abort();
    }
    $(target).empty().show().addClass('spinner');
    var isForm = eventTarget.nodeName == 'FORM';
    var url = options.url || eventTarget.action || eventTarget.href;
    url += (url.match(/\?/) ? '&' : '?') + 'inline=1';
    this.ajax = $.ajax({
      url: url,
      dataType: 'json',
      type: isForm ? 'POST' : 'GET',
      context: options.context || this,
      success: options.success,
      complete: function() {
        $(target).removeClass('spinner');
      },
      data: options.data || (isForm ? $(eventTarget).serialize() : '')
    });
  },
  
  // method gets the actualy response div from the response html
  getResponseNode: function(json) {
    return $('._dbf_response', $(document.createElement('div')).html(json.content)).attr('class', '_dbf_form_wrap');
  },
  
  //method to scroll page to the row
  bringToView: function(options) {
    var top = $(this.el).offset().top - options.marginTop;
    if (!options.downOnly || top < $(document).scrollTop()) {
      $('html,body').animate({ scrollTop: top }, options.speed);
    }
  }
});