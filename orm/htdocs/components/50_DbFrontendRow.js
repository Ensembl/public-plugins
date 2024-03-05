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

/* JavaScript for DbFrontend page
 * Script overrides the standard actions of links and form submit buttons, to make use of AJAX to get html and submit forms
 * For any DbFrontend page using this javascript, check the following things to make if work properly:
 *  1. That the SiteDefs::OBJECT_TO_SCRIPT values for the page is 'Modal'
 *  2. Javascript classes are being added to the html elements properly
 *  3. The page which displays all the records return a single record if its 'id' is specified in GET params
 */

Ensembl.DbFrontendRow = Ensembl.DbFrontend.extend({

  ROW_HEIGHT_WHEN_EDITING : 100,

  // @override
  createForm: function() {
    if (!this.form) {
      this.form = $('<div>').attr('class', 'dbf-inline-form').hide().insertAfter(this.el);
    }
  },
  
  // @override
  getResponseNode: function(json) {
    return this.base(json).attr('class', '_dbf_form_wrap');
  },

  // @override
  buttonClick: function(button) {
    this.createForm();
    this.markAsEditing(!!button.className.match(/_dbf_edit/));
    this.makeRequest(button, this.form, {
      success: function(json) {
        var self = this;
        this.form.append(this.getResponseNode(json));
        $('input[type="text"], input[type="password"], input[type="file"], textarea, select', this.form).first().focus();
        this.initForm();
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
    var previous = $(button).parents('._dbf_form_wrap').prev();
    if (previous.length) {
      previous.show().next().remove();
    } else {
      this.form.slideUp(function() {
        $(this).empty();
      });
      this.markAsEditing(false);
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
          } else {
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
          } else {
            this.markAsEditing(false);
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
              } else {
                this.panel.initRow(this.target.html(this.getResponseNode(json).html()));
              }
              this.afterResponse(!problem, this.target);
            }
          });
        }
      }
    });
  },

  // @override
  afterResponse: function(success) {
    this.scrollIn({margin: 5});
    this.initDataStructure(this.target);
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
    } else if (formTop + formHeight + options.margin > scrollTop + winHeight) {

      //if el + form larger than window size
      if (elHeight + formHeight + options.margin * 2 > winHeight) {
        position = elTop - options.margin;
      } else {
        position = formTop + formHeight + options.margin -winHeight;
      }
    }
    
    if (position) {
      $('html,body').animate({ scrollTop: position}, options.speed);
    }
  },

  markAsEditing: function(flag) {
    var buttonsRow = this.el.find('._dbf_row_buttons');
    if (flag) {
      if (!this.editLayer) {
        var buttonsRowHeight = buttonsRow.outerHeight();
        var recordHeight = this.el.height();
        this.editLayer = $('<div class="dbf-row-layer">').appendTo(document.body).css($.extend({
          height: recordHeight - buttonsRowHeight,
          width:  this.el.width()
        }, this.el.offset())).html('Editing&#8230;').animate({height: this.ROW_HEIGHT_WHEN_EDITING - buttonsRowHeight});
        buttonsRow.addClass('dbf-row-buttons-editing').animate({top: this.ROW_HEIGHT_WHEN_EDITING - recordHeight});
        this.el.animate({height: this.ROW_HEIGHT_WHEN_EDITING});
      }
    } else {
      if (this.editLayer) {
        this.editLayer.remove();
        this.editLayer = null;
      }
      buttonsRow.removeClass('dbf-row-buttons-editing').css({top: 'auto'});
      this.el.css({height: 'auto'});
    }
  }
});

Ensembl.Panel.DbFrontendRow = Ensembl.Panel.DbFrontend.extend({

  initRow: function(row) {
    new Ensembl.DbFrontendRow(row, this);
  }
});