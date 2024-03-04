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
    
    this.params.mr_menu ? this.showMarkRegionMenu() :
      this[this.drag ? 'populateRegion' : this.href ? 'populateAjax' : this.mr_menu ? 'show_mr_menu' : 'populate']();

    if (this.drag) {
      this.el.find('a').on('click', function (e) {
        e.preventDefault();
        panel.menuLinkClick(this, e);
      });
    }
  },

  menuLinkClick: function (link, e) {

    var action = (link.className.match(/_action_(\w+)/) || ['']).pop();

    switch (action) {
      case '':
        break;

      case 'mark':

        Ensembl.markLocation(link.href);
        break;

      case 'center':
      case 'jumpHere':

        var browser  = this.params.browser;
        var position = browser.getSelectorPosition();
        var padding  = action === 'center' ? Math.round(Ensembl.location.length / 2) : 0;

        position.start -= padding;
        position.end   += padding;

        browser.updateURL(position);
        browser.moveTo(position.start, position.end);

        Ensembl.EventManager.trigger('highlightImage', browser.panel.imageNumber + 1, 0, position.start, position.end);

        browser.cancelSelect();
        browser.moveSelector(e);
        break;

      default:

        $('#' + this.imageId).find('.selector_controls .' + action).trigger('click');
        break;
    }

    this.el.hide();
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
    var action  = this.params.browser.wheelAction === false ? 'Jump' : 'Zoom';
    var cssCls  = action === 'Jump' ? 'loc-change' : 'loc-zoom';
    var bps     = this.drag.end - this.drag.start + 1;
    var url     = this.baseURL.replace(/%s/, this.drag.chr + ':' + this.drag.start + '-' + this.drag.end);
    var mUrl    = Ensembl.updateURL({mr: this.drag.chr + ':' + this.drag.start + '-' + this.drag.end}, window.location.href);

    this.buildMenu(this.drag.end === this.drag.start
      ? [ '<a class="loc-icon-a constant _action_center" href="#"><span class="loc-icon loc-pin"></span>Centre here</a>' ]
      : [ '<a class="loc-icon-a constant _action_mark" href="' + mUrl + '"><span class="loc-icon loc-mark"></span>Mark region (' + bps + ' bp)</a>',
          '<a class="loc-icon-a constant _action_' + action.toLowerCase() + 'Here" href="' + url + '"><span class="loc-icon ' + cssCls + '"></span>' + action + ' to region (' + bps + ' bp)</a>' ],
      'Region: ' + this.drag.chr + ':' + this.drag.start + '-' + this.drag.end
    );
  }
});
