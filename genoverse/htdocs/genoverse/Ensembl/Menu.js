/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.GenoverseMenu = Ensembl.Panel.ZMenu.extend({
  constructor: function (id, data) {
    this.id          = id;
    this.params      = data;
    this.initialised = false;
    this.href        = data.feature.menu;
    this.title       = data.feature.title;
    this.event       = data.event;
    this.imageId     = data.imageId;
    this.drag        = data.drag;
    this.coords      = data.coords;
    this.group       = data.group;
    
    Ensembl.EventManager.register('showExistingZMenu', this, this.showExisting);
    Ensembl.EventManager.register('hideZMenu',         this, this.hide);
  },
  
  getContent: function () {
    var panel = this;
    
    this.populated = false;
    
    clearTimeout(this.timeout);
    
    this.timeout = setTimeout(function () {
      if (panel.populated === false) {
        panel.elLk.container.hide();
        panel.elLk.loading.show();
        panel.show(true);
      }
    }, 300);
    
    this[this.drag ? 'populateRegion' : this.href ? 'populateAjax' : 'populate']();
    
    if (this.drag) {
      $('a', this.el).on('click', function (e) {
        var cls = this.className.replace(' constant', '');
        
        if (cls === 'jumpHere') {
          var browser  = panel.params.browser;
          var position = browser.getSelectorPosition();
          
          browser.moveTo(position.start, position.end);
          
          Ensembl.EventManager.trigger('highlightImage', browser.panel.imageNumber + 1, 0, position.start, position.end);
          
          browser.updateURL(position);
          
          browser.cancelSelect();
          browser.moveSelector(e);
        } else {
          $('.selector_controls .' + cls, '#' + panel.imageId).trigger('click');
        }
        
        panel.el.hide();
        
        return false;
      });
    }
  },
  
  show: function (loading) {
    this.base(loading);
    
    if (!loading) {
      var height = this.el.outerHeight() + this.el.position().top + 10;
      this.el.parent().height(function (i, h) { return Math.max(h, height); });
    }
  },
  
  showExisting: function (data) {
    if (data.drag) {
      this.drag = data.drag;
    }
    
    this.base(data);
  }, 
  
  populateRegion: function () {
    var zoom = this.params.browser.wheelAction === false ? 'Jump' : 'Zoom';
    
    this.buildMenu(this.drag.end === this.drag.start
      ? [ '<a class="center constant" href="#">Centre here</a>' ]
      : [ '<a class="' + zoom.toLowerCase() + 'Here constant" href="#">' + zoom + ' to region (' + (this.drag.end - this.drag.start + 1) + ' bp)</a>' ],
      'Region: ' + this.drag.chr + ':' + this.drag.start + '-' + this.drag.end
    );
  }
});
