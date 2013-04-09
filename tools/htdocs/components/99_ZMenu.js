// $Revision$

Ensembl.Panel.ZMenu = Ensembl.Panel.ZMenu.extend({
  populateAjax: function (url, expand) {
    var timeout = this.timeout;
    var caption = this.elLk.caption.html();
    
    url = url || this.href;
    
    if (this.group) {
      url += ';click_start=' + this.coords.clickStart + ';click_end=' + this.coords.clickEnd;
    }
    
    if (url && url.match(/\/ZMenu\//)) {
      $.ajax({
        url: url,
        dataType: 'json',
        context: this,
        success: function (json) {
          if (timeout === this.timeout) {
            this.populated = true;
            
            if (json.entries.length) {
              var body = '';
              var subheader, row;
              
              for (var i in json.entries) {
                if (json.entries[i].type === 'subheader') {
                  subheader = subheader || json.entries[i].link;
                  
                  if (json.entries[i].link !== caption) {
                    row = '<th class="subheader" colspan="2">' + json.entries[i].link + '</th>';
                  }
                } else if (json.entries[i].type) {
                  row = '<th>' + json.entries[i].type + '</th><td>' + json.entries[i].link + '</td>';
                } else {
                  row = '<td colspan="2">' + json.entries[i].link + '</td>';
                }
                
                body += '<tr>' + row + '</tr>';
              }
              
              if (expand) {
                expand.replaceWith(body);
                expand = null;
              } else {
                this.elLk.tbody.html(function (j, html) { return caption && caption === (subheader || json.caption) ? body : html + body; }).find('a.update_panel').attr('rel', this.imageId);
                this.elLk.caption.html(json.caption);
                
                this.show();
              }
              
              if (json.highlight) {
                if (this.relatedEl) {
                  this.relatedEl.removeClass('highlight');  
                }
                
                this.relatedEl = $('tr.' + json.highlight, this.el);
                this.relatedEl.addClass('highlight');    
              }
               
              if (json.pagination.position) {
                this.addPagination(json.pagination);
              }
            } else {
              this.populateNoAjax();
            }
          }
        },
        error: function () {
          this.populateNoAjax();
        }
      });
    } else {
      this.populateNoAjax();
    }
  },
  
  addPagination: function (pagination) {
    var panel = this;
    var index = pagination.position + 1;
    var total = pagination.total;  
    var p0    = pagination.position - 1;
    var p1    = pagination.position;
    var p2    = index;
    var p3    = index + 1;
    var p4    = index + 2;
    
    this.elLk.count = $('div.zmenu_paginate_info', this.el);
    this.elLk.nav   = $('div.zmenu_paginate',      this.el);
    this.elLk.p1    = $('span.p1',                 this.el); 
    this.elLk.p2    = $('span.p2',                 this.el);
    this.elLk.p3    = $('span.p3',                 this.el);
    
    this.buttons = $('span', this.elLk.nav).addClass('paginate_button').removeClass('paginate_active paginate_button_disabled').css('display', '').off('click').length;
    
    if (p2 === total) {
      this.elLk.p3.html(p2).removeClass('paginate_button').addClass('paginate_active');
      
      if (p1 >= 1) {
        this.elLk.p2.html(p1);  
      }
      
      if (p0 > 0) {
        this.elLk.p1.html(p0);
      } else {
        this.elLk.p1.hide();
      }
    } else if (p2 === 1) {
      this.elLk.p1.html(p2).removeClass('paginate_button').addClass('paginate_active');
      
      if (p3 <= total) {
        this.elLk.p2.html(p3);
      }
      
      if (p4 <= total) {
        this.elLk.p3.html(p4);
      } else {
        this.elLk.p3.hide();
      } 
    } else {
      this.elLk.p1.html(p1);
      this.elLk.p2.html(p2).removeClass('paginate_button').addClass('paginate_active');
      this.elLk.p3.html(p3);
    }
    
    // disable buttons that aren't valid
    if (p2 === 1) {
      $('span.first, span.previous', this.elLk.nav).addClass('paginate_button_disabled');
    } 
    
    if (p2 === total) {
      $('span.next, span.last', this.elLk.nav).addClass('paginate_button_disabled');
    }
    
    this.elLk.count.html('Showing ' + index + ' of ' + total + ' features');
    this.elLk.nav.show();
    
    $('span.paginate_button', this.elLk.nav).on('click', function () {
      var button = $(this).index();
      var newIndex;
      
      switch (button) {
        case 0                 : newIndex = 0;         break; // first
        case 1                 : newIndex = index;     break; // previous
        case panel.buttons - 1 : newIndex = index - 2; break; // next
        case panel.buttons     : newIndex = total - 1; break; // last
        default                : newIndex = parseInt(this.innerHTML, 10) - 1; break;
      }
      
      panel.populateAjax(Ensembl.updateURL({ idx: newIndex }, pagination.url_template));
    });
    
    $('span.paginate_button_disabled', this.elLk.nav).off('click');
  }
});
