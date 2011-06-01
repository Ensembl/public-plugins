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

    this.form = $(document.createElement('div')).attr({'class': 'dbf-inline-form'}).hide().insertAfter(this.el);

    // Button's event - Edit and Delete button
    $('._dbf_button', this.el).live('click', function(event) {
      event.preventDefault();
      self.makeRequest(this, self.form, {
        success: function(json) {
          this.form.append(this.getResponseNode(json));
          this.scrollIn({marginTop: 5});
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
      self.scrollIn({marginTop: 5, upOnly: true});
    });
  
    // Submit event of the form for previewing the data
    $('form._dbf_preview', this.form[0]).live('submit', function(event) {
      event.preventDefault();
      self.scrollIn({marginTop: 5, upOnly: true});
      self.form.children(':first').hide();
      self.makeRequest(this, $(document.createElement('div')).appendTo(self.form), {
        success: function(json) {
          this.form.children(':last').replaceWith(this.getResponseNode(json));
        }
      });
    });

    // Submit event of the form for saving the data
    $('form._dbf_save, form._dbf_add', this.form[0]).live('submit', function(event) {
      event.preventDefault();
      self.action = this.className.match(/_dbf_add/) ? 'add' : 'edit';
      self.target = $(self.el)
      self.makeRequest(this, self.form.children(':last'), {
        success: function(json) {
          if (json.redirectURL) {
            var url = json.redirectURL;
            if (url.match(/Display/)) {
              this.form.empty().hide();
              if (this.action == 'add') {
                this.target = $(this.el).clone().empty().removeAttr('id').insertAfter(this.el.previousSibling && this.el.previousSibling.previousSibling ? this.el.previousSibling : this.form);
              }
              var id = (url.match(/(\?|&|;)id\=([0-9]+)/) || []).pop() || 0;
              if (id) {
                url = window.location.href + (window.location.href.match(/\?/) ? '&' : '?') + 'id=' + id;
              }
            }
            else if (url.match(/Problem$/)) {
              this.target = this.form.children().show().last();
            }
            this.makeRequest({}, this.target, {
              async: false,
              url: url,
              success: function(json) {
                if (this.action == 'edit') {
                  this.target.html(this.getResponseNode(json).html());
                }
                else {
                  Ensembl.EventManager.trigger('addPanel', undefined, 'DbFrontendRow', this.getResponseNode(json).html(), this.target);
                }
                this.scrollIn({marginTop: 5, upOnly: true});
              }
            });
          }
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
              this.makeRequest({}, this.form, {
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
      this.ajax = false;
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
  scrollIn: function(options) {
    var top = $(this.el).offset().top - options.marginTop;
    if (!options.upOnly || top < $(document).scrollTop()) {
      $('html,body').animate({ scrollTop: top }, options.speed);
    }
  }
});