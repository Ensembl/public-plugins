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

// FIXME: history isn't working properly when zooming in/out with slider - genoverse.length changes and everything is reset
// FIXME: occasional off-by-one error due to Math.round in getLocation - breaks history (and anything else that requires an x.start === y.start type comparison)
// TODO:  hide highlightRegion when new images are being made, and in other scenarios where it looks bad

Ensembl.Genoverse = Genoverse.extend({
  constructor: function () {
    this.base.apply(this, arguments);

    this.on('afterMoveTo', function () {
      this.saveState();
    });

    this.on('afterSetRange afterPopState', function () {
      this.updateEnsembl();
    });

    this.on('beforeResetTrackHeights beforeToggleAutoHeight beforeCheckTrackSize', function () {
      this.resizingTracks = true;
    });

    this.on('afterResetTrackHeights afterToggleAutoHeight afterCheckTrackSize', function () {
      this.resizingTracks = false;
      this.updateSelectorHeight();
    });

    this.on('afterAddTracks afterRemoveTracks', function () {
      Ensembl.EventManager.trigger('resetImageOffset');
      this.updateSelectorHeight();
    });
  },

  init: function () {
    this.base.apply(this, arguments);

    this.selectorStalled = true;
    this.trackAutoHeight = false;

    this.saveState();

    Ensembl.EventManager.register('genoverseUndoScroll', this, this.undoScroll);
    Ensembl.EventManager.register('genoverseSaveState', this, this.saveState);

    // Ensure that the popState function from Genoverse fires before the one from Ensembl, so that nothing happens when hashChange is triggered from using browser forward/back buttons
    $(window).off('hashchange.ensembl popstate.ensembl').on('hashchange.ensembl popstate.ensembl', $.proxy(Ensembl.LayoutManager.popState, Ensembl.LayoutManager));
    this.container.off('dblclick');
  },

  undoScroll: function () {
    this.move((this.start - this.lastScroll.start) * this.scale);
    this.updateURL(this.lastScroll.location);
    this.updateEnsembl(this.lastScroll.location);
  },

  saveState: function () {
    this.lastScroll = {
      offset:   Ensembl.location.start - this.start,
      location: $.extend({}, Ensembl.location),
      start:    this.start
    };
  },

  updateEnsembl: function (location) {
    Ensembl.images[this.panel.imageNumber][0][2] = this.start;
    Ensembl.images[this.panel.imageNumber][0][3] = this.end;

    if (this.dragging || location) {
      location = location || this.getLocation(this.start, this.end, Ensembl.location.length);
      var text = Ensembl.thousandify(location.start) + '-' + Ensembl.thousandify(location.end);

      (this.updateEnsemblText = this.updateEnsemblText || $('h1.summary-heading, #masthead .location.long_tab a')).html(function (i, html) {
        return html.replace(/^(.+:\s?).+/, '$1' + text);
      });
      if (Ensembl.images[this.panel.imageNumber+1]) {
        Ensembl.images[this.panel.imageNumber+1][0][2] = location.start;
        Ensembl.images[this.panel.imageNumber+1][0][3] = location.end;
      }
    }

    if (this.panel.genoverse) { // panel.genoverse may not exist if it gets called while the call it made through Genoverse's constructor
      this.panel.initLocationMarking();
      this.panel.markLocation(Ensembl.markedLocation);
    }

    Ensembl.EventManager.trigger('highlightAllImages');
  },

  updateURL: function (location) {
    location = location || (this.prev.scale === this.scale ? this.getLocation(this.start, this.end, Ensembl.location.length) : this);

    if (Ensembl.location.start === location.start && Ensembl.location.end === location.end) {
      return;
    }

    this.updatingURL = true;

    Ensembl.updateLocation(this.urlParamTemplate
      .replace('r=',        '')
      .replace('__CHR__',   this.chr)
      .replace('__START__', location.start)
      .replace('__END__',   location.end)
    );
  },

  popState: function () {
    this.updatingURL     = true;
    Ensembl.historyReady = true;
    this.base();
  },

  setRange: function (start, end, update, keepLength) {
    var location = this.getLocation(start, end); // Ensures that minSize is observed
    this.base(location.start, location.end, update, keepLength);
  },

  getLocation: function (s, e, l) {
    // pick l bases somewhere within the range s-e (usually middle)
    var browser     = this;
    var start       = Math.floor(s || this.start);
    var end         = Math.floor(e || this.end);
    var length      = end - start + 1;
    var flankLength = this.flanking ? Ensembl.location.length + (2 * this.flanking) : 0;

    // make the region be the length of newLength
    function resize(newLength, preserveOffset) {
      if (length === newLength) {
        return;
      }

      start = preserveOffset ? start + browser.lastScroll.offset : Math.max(Math.round(start + (length - newLength) / 2), 1);
      end   = start + newLength - 1;

      if (end > browser.chromosomeSize) {
        end   = browser.chromosomeSize;
        start = end - browser.minSize + 1;
      }
    }

    if (l) {
      resize(l, true);
    } else if (flankLength && flankLength <= this.minSize && flankLength <= this.chromosomeSize) {
      // expand the region by flanking amount on each side
      resize(flankLength);
    } else if (this.minSize && length < this.minSize) {
      if (this.chromosomeSize < this.minSize) {
        // get whole chromosome
        start = 1;
        end   = this.chromosomeSize;
      } else {
        resize(this.minSize);
      }
    }

    return { start: start, end: end, length: end - start + 1 };
  },

  stopDragScroll: function () {
    Ensembl.genoverseScroll = true;
    this.base.apply(this, arguments);
    Ensembl.genoverseScroll = false;
  },

  setLabels: function (tracks) {
    var label, id, strand;

    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i] instanceof Genoverse.Track === false) {
        continue;
      }

      label = tracks[i].prop('label');
      id    = tracks[i].prop('urlParams').id;

      if (label.hasClass(id)) {
        continue;
      }

      label.data({ order: tracks[i].prop('order') || 0 }).addClass(id);

      if (tracks[i].prop('unsortable') !== true) {
        strand = tracks[i].prop('strand');

        if (strand) {
          label.addClass(strand === 1 ? 'f' : 'r');
        }
      }
    }
  },

  addTracks: function (tracks, index) {
    tracks = tracks || this.tracks;

    for (var i = 0; i < tracks.length; i++) {
      tracks[i] = typeof tracks[i] === 'function' ? tracks[i] : tracks[i].type ? Genoverse.Track[tracks[i].type].extend(tracks[i]) : Genoverse.Track.extend(tracks[i]);
    }

    tracks = this.base.apply(this, arguments);

    this.setLabels(tracks);
    return tracks;
  },

  removeTracks: function (tracks) {
    var hover = $.map(tracks, function (track) { return (track.prop('hoverLabel') || [])[0]; });
    this.panel.elLk.hoverLabels = this.panel.elLk.hoverLabels.not($(hover).remove());
    this.base(tracks);
  },

  updateTrackOrder: function (e, ui) {

    var track = ui.item.data('track');
    var prev  = ui.item.prev().data('track');

    this.base(e, ui);

    track = track.prop('id') + (track.prop('strand') ? track.prop('strand') > 0 ? '.f' : '.r' : '');
    prev  = prev.prop('id') + (prev.prop('strand') ? prev.prop('strand') > 0 ? '.f' : '.r' : '');

    Ensembl.EventManager.triggerSpecific('changeTrackOrder', 'modal_config_' + this.panel.id.toLowerCase(), track, prev);

    this.panel.saveSort(Ensembl.species, track, prev);
  },

  resetConfig: function () {
    this.resetTrackHeights();

    for (var i = 0; i < this.tracks.length; i++) {
      this.tracks[i].prop('messageContainer').attr('class', 'gv-message-container');
    }
  },

  resetTrackHeights: function () {
    var track;

    this.trackAutoHeight = false;

    this.base();

    this.panel.updateTrackHeightControl(true);

    for (var i = 0; i < this.tracks.length; i++) {
      track = this.tracks[i];

      if (track.resizable === true) {
        track.updateHeightToggler();
      }
    }
  },

  toggleAutoHeight: function (json) {
    var i = this.tracks.length;
    var track, config, height;

    this.trackAutoHeight = !this.trackAutoHeight;

    while (i--) {
      track  = this.tracks[i];
      config = json[track.id] || {};

      if (track.resizable === true) {
        track.autoHeight = !!config.autoHeight || this.trackAutoHeight;

        if (track.autoHeight) {
          track.heightBeforeToggle = track.prop('height');
          height = track.prop('fullVisibleHeight');
        } else {
          height = config.height || track.heightBeforeToggle || track.initialHeight;
        }

        if (config.height) {
          track.heightBeforeToggle = config.height;
        }

        track.controller.resize(height);
        track.updateHeightToggler();
      }
    }
  },

  updateSelectorHeight: function () {
    if (this.resizingTracks || this.dragging) {
      return;
    }

    var height = 0;
    var i      = this.tracks.length;

    while (i--) {
      if (this.tracks[i] instanceof Genoverse.Track && !(this.tracks[i] instanceof Genoverse.Track.Legend)) {
        height += this.tracks[i].prop('height') || 0;
      }
    }

    this.selector.add(this.panel.elLk.highlightRegion).add(this.panel.elLk.markedLocation).css('height', height); // Do not use .height(height), because the box-sizing: border-box style causes height(height) to sets the height to be 2px too large
  },

  makeMenu: function (feature, event, track) {
    if (feature.menu || feature.title) {
      this.makeZMenu({ event: event, feature: feature, imageId: track.name }, [ 'zmenu', track.name, feature.id ].join('_').replace(/\W/g, '_'), track); // TODO: check track/name is ok
      event.originalEvent.hasFeature = true;
    }
  },

  stopDragSelect: function (e) {
    if (this.base(e) !== false && !e.originalEvent.hasFeature) {
      this.makeRegionZmenu(e, {left: this.selector.position().left, width: this.selector.outerWidth(true)});
      this.selectorStalled = true;
    }
  },

  makeRegionZmenu: function(e, coords, params) {
    var start = Math.round(coords.left / this.scale) + this.start;
    var end   = Math.round((coords.left + coords.width) / this.scale) + this.start - 1;
        end   = end <= start ? start : end;

    var mr_menu = params && params.mr_menu ? params.mr_menu : 0;

    this.makeZMenu({ event: e, feature: {}, drag: { chr: this.chr, start: start, end: end, browser: this }, imageId: this.panel.id, onClose: function(e) {
      this.cancelSelect();
      this.moveSelector(e);
    }, 'mr_menu' : mr_menu }, mr_menu ? 'mr_menu_region_select' : 'zmenu_region_select');
  },

  makeZMenu: function (params, id, track) {
    params.browser = this;
    params.coords  = {};
    params.group   = params.feature.group || (track && track.prop('depth') === 1);

    if ((params.event.shiftKey || params.group) && params.event.pageX && !params.drag) {
      var x         = (params.event.pageX - this.wrapper.offset().left + this.scaledStart) / this.scale;
      var fuzziness = this.scale > 1 ? 0 : 2 / this.scale;

      params.coords.clickChr   = this.chr;
      params.coords.clickStart = Math.max(Math.floor(x - fuzziness), this.start);
      params.coords.clickEnd   = fuzziness ? Math.min(Math.ceil(x + fuzziness), this.end) : params.coords.clickStart;

      id += '_multi';
    }

    var menu = $('#' + id);

    if (!menu.length) {
      menu = Ensembl.Panel.ZMenu.template.clone().attr('id', id).addClass('menu').appendTo('body');
    }

    Ensembl.EventManager.trigger('addPanel', id, 'GenoverseMenu', undefined, undefined, params, 'showExistingZMenu');

    this.panel.zMenus[id] = 1;
    this.menus = this.menus.add(menu);

    if (track) {
      track.prop('menus', track.prop('menus').add(menu));
    }

    if (params.onClose) {
      menu.find('span.close').off('.genoverse').on('click.genoverse', function(e) {
        params.onClose.call(params.browser, e);
      });
    }

    menu = null;
  },

  toggleSelect: function (on) {
    this.base(on);
    this.panel.updateToggleSelectControl(on);
  },

  keydown: function (e) {
    return e.which === 27 ? false : this.base(e); // Don't do anything on escape key press
  },

  saveConfig: function () {
    var track = arguments[arguments.length - 1];

    if (track instanceof Genoverse.Track === false || !track.id) {
      return;
    }

    var config = {};

    if (typeof arguments[0] === 'string') {
      config[arguments[0]] = arguments[1];
    } else {
      config = arguments[0];
    }

    $.ajax({
      url  : '/' + Ensembl.species + '/Genoverse/save_config',
      type : 'post',
      data : { config: JSON.stringify(config), image_config: this.panel.imageConfig, track: track.id }
    });
  },

  addDomElements: function () {
  /*
   * Remove default genoverse selector controls (we have our zmenu for that)
   */
    this.base.apply(this, arguments);
    $(this.selectorControls).remove();
  },

  moveCrosshair: function (rStart) {
    if (this.dragAction === 'select' && this.selector.hasClass('gv-crosshair')) {
      this.selectorStalled = true; // prevent document.mousemove to change selector poisition to current mouse pageX
      this.selector.css('left', (rStart - this.start) * this.scale);
    }
  },

  addUserEventHandlers: function() {
    var browser = this;

    this.base.apply(this, arguments);

    this.container.on('mouseenter mouseleave', function (e) {
      browser.selectorStalled = e.type === 'mouseleave' || !browser.selector.hasClass('gv-crosshair');
    });
  },

  die: function (error, el) {
    return this.base(error, el.parents('.js_panel:first'));
  }
});
