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

Ensembl.genoverseSupported = function () {
  if (!('_genoverseSupported' in this)) {
    this._genoverseSupported = (function () { var c = document.createElement('canvas');  return !!(c.getContext && c.getContext('2d') && Ensembl.locationURL === 'search'); })();
  }
  return this._genoverseSupported;
}

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({
  init: function () {
    this.base();
    
    if (this.el.parent().hasClass('image_panel') && this.panelType !== 'ImageMap') {
      this.imagePanel = true; // Panels which would be image maps if the region wasn't too large
    }
  },
  
  hashChange: function () {
    if (this.imagePanel && Ensembl.location.length > Ensembl.maxRegionLength) {
      return;
    }
    
    this.base.apply(this, arguments);
  }
});

Ensembl.Panel.ImageMap = Ensembl.Panel.ImageMap.extend({
  init: function () {
    var panel = this;

    this.base();
    this.el.css('position', 'relative');

    this.isViewTop    = this.id === 'ViewTop';
    this.isGenoverse  = this.isViewTop && this.panelType === 'Genoverse';

    if (this.isViewTop && Ensembl.genoverseSupported()) {
      this.addGenoverseSwitch();
    }

    Ensembl.EventManager.register('resetImageOffset', this, function () { delete this.imgOffset; });
  },

  addGenoverseSwitch: function () {
    var panel = this;

    $('<div class="genoverse_switch">Switch image</div>').appendTo(this.elLk.toolbars).on('click', function () {
      panel.params.updateURL = Ensembl.updateURL({ genoverse: panel.isGenoverse ? 1 : 0 }, panel.params.updateURL);
      panel.toggleLoading(true);

      $.ajax({
        url       : '/' + Ensembl.species + '/Genoverse/switch_image',
        data      : { 'static' : panel.isGenoverse ? 1 : 0, id : panel.id },
        complete  : function () { panel.getContent(); }
      });
    }).helptip({ content: 'Switch to ' + (panel.isGenoverse ? 'static' : 'scrollable') + ' image' });
  },

  toggleOverlayButtons: function (flag) {
    var panel = this;

    if (this.isViewTop) {
      return;
    }

    if (!this.elLk.overlay) {
      if (!flag) {
        return;
      }

      this.elLk.overlay       = $('<div class="image_update_overlay">');
      this.elLk.updateButtons = $('<div class="image_update_buttons">');

      $('<input class="fbutton update" type="button" value="Update this image" /><input class="fbutton reset" type="button" value="Reset scrollable image" />').appendTo(this.elLk.updateButtons).on('click', function () {

        panel.toggleOverlayButtons(false);

        if ($(this).hasClass('update')) {
          panel.params.updateURL = Ensembl.urlFromHash(panel.params.updateURL);
          panel.getContent();

          Ensembl.EventManager.trigger('genoverseSaveState');

        } else {
          panel.resetGenoverse = true;

          Ensembl.EventManager.trigger('genoverseUndoScroll');
          panel.elLk.container.resizable('enable');
        }
      });
    }

    if (flag) {
      this.elLk.container.append(this.elLk.overlay, this.elLk.updateButtons);
    } else {
      this.elLk.overlay.add(this.elLk.updateButtons).detach();
    }
  },

  toggleLoading: function () {
    this.toggleOverlayButtons(false);
    this.base.apply(this, arguments);
  },

  makeImageMap: function () {
    var panel = this;

    this.base.apply(this, arguments);

    if (this.draggables && this.draggables[0]) {

      this.elLk.drag.on('mousemove.genoverseCrosshair', function(e) {

        if (panel.dragging !== false) {
          return;
        }

        var coords    = panel.getMapCoords(e);
        var dragArea  = panel.getArea(coords, true);

        if (!dragArea) {
          return;
        }

        Ensembl.EventManager.trigger('updateCrosshair', dragArea.range.start + (coords.x - dragArea.l) * dragArea.range.scale);
      });
    }
  },

  hashChange: function () {
    if (this.resetGenoverse) {
      this.resetGenoverse = false;
    } else if (Ensembl.genoverseScroll) {
      var range = this.highlightRegions[0][0].region.range;
      
      if (range.start > Ensembl.location.start || range.end < Ensembl.location.end) {
        this.elLk.container.resizable('disable');
        this.toggleOverlayButtons(true);
        this.selectArea(false);
        this.removeZMenus();
      }
    } else {
      this.base.apply(this, arguments);
    }
  }
});

Ensembl.Panel.Configurator = Ensembl.Panel.Configurator.extend({
  updateConfiguration: function () {
    if (this.params.reset && this.params.reset !== 'track_order') {
      Ensembl.EventManager.triggerSpecific('resetGenoverse', this.component);
    }
    
    return this.base.apply(this, arguments);
  }
});

