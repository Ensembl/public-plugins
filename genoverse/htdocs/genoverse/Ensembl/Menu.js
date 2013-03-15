// $Revision$

Ensembl.Panel.GenoverseMenu = Ensembl.Panel.ZMenu.extend({
  constructor: function (id, data) {
    this.id          = id;
    this.params      = data;
    this.initialised = false;
    this.href        = data.feature.menu;
    this.title       = data.feature.title;
    this.position    = data.position;
    this.imageId     = data.imageId;
    this.drag        = data.drag;
    
    Ensembl.EventManager.register('showExistingZMenu', this, this.showExisting);
    Ensembl.EventManager.register('hideZMenu',         this, this.hide);
  },
  
  getContent: function () {
    var panel = this;
    
    this.populated = false;
    
    clearTimeout(this.timeout);
    
    this.timeout = setTimeout(function () {
      if (panel.populated === false) {
        panel.elLk.caption.html('Loading component');
        panel.elLk.tbody.hide();
        panel.elLk.loading.show();
        panel.show(true);
      }
    }, 300);
    
    this[this.drag ? 'populateRegion' : this.href ? 'populateAjax' : 'populate']();
    
    if (this.drag) {
      $('a', this.el).on('click', function () {
        var cls = this.className.replace(' constant', '');
        
        if (cls === 'jumpHere' || cls === 'center') {
          var browser  = panel.params.browser;
          var position = browser.getSelectorPosition();
          
          panel.el.hide();
          
          browser.moveTo(position, cls === 'jumpHere' ? position : true);
        } else {
          $('.' + cls, '.selector_controls').trigger('click');
        }
        
        return false;
      });
    }
  },
  
  show: function (loading) {
    this.base(loading);
    
    var margin = parseInt(this.el.css('marginTop'), 10);
    var height = this.el.outerHeight() + this.el.position().top + margin + 10;
    
    this.el.css({
      top        : function (i, top) { return parseInt(top, 10) - margin; },
      marginLeft : 0
    }).parent().height(function (i, h) { return Math.max(h, height); });
  },
  
  showExisting: function (data) {
    if (data.drag) {
      this.drag = data.drag;
    }
    
    this.base(data);
  }, 
  
  populateRegion: function () {
    var zoom = this.params.browser.wheelAction === false ? 'Jump' : 'Zoom';
    
    this.buildMenu(
      [ '<a class="' + zoom.toLowerCase() + 'Here constant" href="#">' + zoom + ' to region (' + (this.drag.end - this.drag.start + 1) + ' bp)</a>', '<a class="center constant" href="#">Centre here</a>' ],
      'Region: ' + this.drag.chr + ':' + this.drag.start + '-' + this.drag.end
    );
  }
});
