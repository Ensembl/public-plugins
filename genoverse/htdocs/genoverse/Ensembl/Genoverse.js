// $Revision$

// FIXME: history isn't working properly when zooming in/out with slider - genoverse.length changes and everything is reset
// FIXME: occasional off-by-one error due to Math.round in getLocation - breaks history (and anything else that requires an x.start === y.start type comparison)
// TODO:  hide highlightRegion when new images are being made, and in other scenarios where it looks bad

Ensembl.Genoverse = Genoverse.extend({
  init: function () {
    this.tracksById = {};
    this.base();
    this.highlightRegion = $('<div class="selector highlight"></div>').appendTo(this.wrapper);
    
    Ensembl.EventManager.register('genoverseMove', this, this.moveTo);
    
    // Ensure that the popState function from Genoverse fires before the one from Ensembl, so that nothing happens when hashChange is triggered from using browser forward/back buttons
    $(window).off('hashchange.ensembl popstate.ensembl').on('hashchange.ensembl popstate.ensembl', $.proxy(Ensembl.LayoutManager.popState, Ensembl.LayoutManager));
  },
  
  updateEnsembl: function () {
    Ensembl.images[this.panel.imageNumber][0][2] = this.start;
    Ensembl.images[this.panel.imageNumber][0][3] = this.end;
    
    if (this.dragging) {
      var location = this.getLocation(this.start, this.end, Ensembl.location.length);
      var text     = Ensembl.thousandify(location.start) + '-' + Ensembl.thousandify(location.end); 
      
      (this.updateEnsemblText = this.updateEnsemblText || $('h1.summary-heading, #masthead .Location.long_tab a')).html(function (i, html) {
        return html.replace(/^(.+:\s?).+/, '$1' + text);
      });
    }
    
    Ensembl.EventManager.trigger('highlightAllImages');
  },
  
  updateURL: function (location) {
    location = location || (this.prev.scale === this.scale ? this.getLocation(this.start, this.end, Ensembl.location.length) : this);
    
    if (Ensembl.location.start === location.start && Ensembl.location.end === location.end) {
      return this.setHistory();
    }
    
    this.updatingURL = true;
    
    Ensembl.updateLocation(this.urlParamTemplate
      .replace('r=',        '')
      .replace('__CHR__',   this.chr)
      .replace('__START__', location.start)
      .replace('__END__',   location.end)
    );
    
    this.setHistory();
  },
  
  popState: function () {
    this.updatingURL     = true;
    Ensembl.historyReady = true;
    this.base();
  },
  
  setRange: function (start, end, update, force) {
    var location = this.getLocation(start, end); // Ensures that minSize is observed
    this.base(location.start, location.end, update, force);
  },
  
  getLocation: function (s, e, l) {
    var browser     = this;
    var start       = Math.floor(s || this.start);
    var end         = Math.floor(e || this.end);
    var length      = end - start + 1;
    var flankLength = this.flanking ? Ensembl.location.length + (2 * this.flanking) : 0;
    
    // make the region be the length of newLength
    function resize(newLength) {
      if (length === newLength) {
        return;
      }
      
      start = Math.max(Math.round(start + (length - newLength) / 2), 1);
      end   = start + newLength - 1;
      
      if (end > browser.chromosomeSize) {
        end   = browser.chromosomeSize;
        start = end - browser.minSize + 1;
      }
    }
    
    if (l) {
      resize(l);
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
  
  moveTo: function (location, urlLocation, showHighlight) {
    var browser = this;
    var start   = Math.max(typeof start === 'number' ? location.start : parseInt(location.start, 10), 1);
    var end     = Math.min(typeof end   === 'number' ? location.end   : parseInt(location.end,   10), this.chromosomeSize);
    var left    = Math.round((start - this.start) * this.scale);
    var width   = Math.round((end   - start + 1)  * this.scale);
    
    this.highlightRegion.css('visibility', 'hidden'); // scrolling causes the highlightRegion to be set to display: block, so hide it like this instead
    
    this.startDragScroll();
    this.dragging = false;
    
    this.move(null, (this.width - width) / 2 - left, 'fast', function () {
      browser.stopDragScroll(null, false);
      browser.checkTrackSize();
      
      browser.highlightRegion.css({ visibility: 'visible', display: showHighlight ? 'block' : 'none' });
      
      if (urlLocation) {
        browser.updateURL(urlLocation === true ? browser.getLocation(start, end, Ensembl.location.length) : urlLocation);
      }
    });
  },
  
  setLabels: function (tracks) {
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].label.hasClass(tracks[i].urlParams.id)) {
        continue;
      }
      
      tracks[i].label.data({ order: tracks[i].order || 0 }).addClass(tracks[i].urlParams.id);
      
      if (tracks[i].unsortable !== true) {
        if (tracks[i].strand) {
          tracks[i].label.addClass(tracks[i].strand === 1 ? 'f' : 'r');
        }
      }
    }
  },
  
  setTracks: function (tracks, index) {
    var browser = this;
    
    this.base(tracks, index);
    
    $.each(tracks || this.tracks, function () {
      if (this.id) {
        browser.tracksById[this.id] = this;
      }
      
      if (this.ensembl !== true) {
        this.extend(Genoverse.Track.Ensembl);
        this.ensemblInit();
      }
    });
    
    this.setLabels(tracks || this.tracks);
    
    return tracks;
  },
  
  removeTracks: function (tracks) {
    var hover = $.map(tracks, function (track) { return (track.hoverLabel || [])[0]; });
    this.panel.elLk.hoverLabels = this.panel.elLk.hoverLabels.not($(hover).remove());
    this.base(tracks);
  },
  
  resetTrackHeights: function () {
    var track;
    
    this.autoHeight = false;
    
    this.base();
    
    for (var i = 0; i < this.tracks.length; i++) {
      track = this.tracks[i];
      
      if (track.resizable) {
        track.updateHeightToggler();
      }
    }
  },
  
  toggleAutoHeight: function (json) {
    var i = this.tracks.length;
    var track, height;
    
    this.autoHeight = !this.autoHeight;
    
    while (i--) {
      track = this.tracks[i];
      
      if (track.resizable) {
        track.autoHeight = !!json[track.id].autoHeight || this.autoHeight;
        
        if (track.autoHeight) {
          track.heightBeforeToggle = track.height;
          height = track.fullVisibleHeight;
        } else {
          height = json[track.id].height || track.initialHeight;
        }
        
        if (json[track.id].height) {
          track.heightBeforeToggle = json[track.id].height;
        }
        
        track.resize(height);
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
      if (this.tracks[i].height && !(this.tracks[i] instanceof Genoverse.Track.Error || this.tracks[i] instanceof Genoverse.Track.Legend)) {
        height += this.tracks[i].height;
      }
    }
    
    this.selector.add(this.highlightRegion).height(height);
  },
  
  menuTemplate: $('                                                                                 \
    <div class="info_popup floating_popup menu">                                                    \
      <span class="top"></span>                                                                     \
      <span class="close"></span>                                                                   \
      <table class="zmenu" cellspacing="0">                                                         \
        <thead>                                                                                     \
          <tr class="header"><th class="caption" colspan="2"><span class="title"></span></th></tr>  \
        </thead>                                                                                    \
        <tbody class="loading">                                                                     \
          <tr><td><p class="spinner"></p></td></tr>                                                 \
        </tbody>                                                                                    \
        <tbody></tbody>                                                                             \
      </table>                                                                                      \
    </div>                                                                                          \
  '),
  
  makeMenu: function (track, feature, position) {
    if (feature.menu || feature.title) {
      this.makeZMenu({ position: position, feature: feature, imageId: track.name }, [ 'zmenu', track.name, feature.id ].join('_').replace(/\W/g, '_'), track, this.base);
    }
  },
  
  stopDragSelect: function (e) {
    if (this.base(e) !== false) {
      var id    = 'zmenu_region_select';
      var left  = this.selector.position().left;
      var start = Math.round(left / this.scale) + this.start;
      var end   = Math.round((left + this.selector.outerWidth(true)) / this.scale) + this.start - 1;
          end   = end <= start ? start : end;
      
      this.makeZMenu({ position: this.positionMenu({ left: e.pageX, top: e.pageY }, id), feature: {}, drag: { chr: this.chr, start: start, end: end, browser: this }, imageId: this.panel.id }, id);
    }
  },
  
  makeZMenu: function (params, id, track, func) {
    var menu = $('#' + id);
    
    if (menu.length) {
      this.positionMenu(params.position);
    } else {
      menu = func ? func.call(this, track, params.feature, params.position).hide() : this.menuTemplate.clone().addClass('drag').appendTo(this.menuContainer);
      menu.attr('id', id).draggable({ handle: 'thead', containment: 'parent' });
    }
    
    params.browser       = this;
    params.position.left = Math.min(params.position.left, this.width - menu.outerWidth() + parseInt($('.close', menu).css('right'), 10)); // adjust for close button set outside menu
    
    Ensembl.EventManager.trigger('addPanel', id, 'GenoverseMenu', undefined, undefined, params, 'showExistingZMenu');
    
    menu = null;
  },
  
  positionMenu: function (position, id) {
    if (!id || !$('#' + id).length) {
      var offset = this.menuContainer.offset();
      
      position.top  -= offset.top;
      position.left -= offset.left;
    }
    
    return position;
  },
  
  cancelSelect: function () {
    this.base();
    $('.drag', this.menuContainer).hide();
    return false;
  },
  
  toggleSelect: function (on) {
    this.base(on);
    this.panel.elLk.dragging.removeClass('on off').addClass(this.dragAction === 'select' ? 'off' : 'on')
    this.panel.changeControlTitle('dragging');
  },
  
  die: function (error, el) {
    return this.base(error, el.parents('.js_panel:first'));
  }
});

Genoverse.on('afterSetRange afterPopState', function () {
  this.updateEnsembl();
});

Genoverse.on('beforeResetTrackHeights beforeToggleAutoHeight beforeCheckTrackSize', function () {
  this.resizingTracks = true;
});

Genoverse.on('afterResetTrackHeights afterToggleAutoHeight afterCheckTrackSize', function () {
  this.resizingTracks = false;
  this.updateSelectorHeight();
});

Genoverse.on('afterAddTracks afterRemoveTracks', function () {
  Ensembl.EventManager.trigger('resetImageOffset');
  this.updateSelectorHeight();
});
