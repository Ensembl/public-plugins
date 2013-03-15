// $Revision$

Ensembl.Panel.Genoverse = Ensembl.Panel.ImageMap.extend({
  init: function () {
    this.prevHighlight = {};
    
    this.base();
    
    if (this.genoverse.failed) {
      return;
    }
    
    this.elLk.img         = this.genoverse.container;
    this.elLk.boundaries  = this.genoverse.labelContainer;
    this.elLk.canvas      = $('.canvas',             this.el);
    this.elLk.controls    = $('.genoverse_controls', this.el).each(function () { $(this).prev().append(this); });
    this.elLk.autoHeight  = $('.auto_height',        this.elLk.controls);
    this.elLk.resetHeight = $('.reset_height',       this.elLk.controls)
    this.elLk.dragging    = $('.dragging',           this.elLk.controls);
    this.elLk.wheelZoom   = $('.wheel_zoom',         this.elLk.controls);
    
    this.initControls();
    
    Ensembl.EventManager.register('changeTrackOrder',  this, this.sortUpdate);
    Ensembl.EventManager.register('updatePanel',       this, this.update);
    Ensembl.EventManager.register('imageResize',       this, this.resize);
    Ensembl.EventManager.register('changeWidth',       this, this.resize);
    Ensembl.EventManager.register('resetTrackHeights', this, function () { this.elLk.resetHeight.trigger('click'); });
  },
  
  makeImageMap: function () {
    var panel  = this;
    var tracks = $.extend(true, [], Ensembl.genoverseConfig.tracks);
    var parent = this.el.parents('.image_panel')[0];
    
    $('.image_panel').each(function (i) {
      if (this === parent) {
        panel.imageNumber = i + 1;
        Ensembl.images[panel.imageNumber] = { 0: [ panel.imageNumber, 0, Ensembl.genoverseConfig.start, Ensembl.genoverseConfig.end ] };
      }
    });
    
    delete Ensembl.genoverseConfig.tracks;
    
    this.genoverse = new Ensembl.Genoverse($.extend({
      id        : this.id + 'Browser',
      panel     : this,
      container : $('.canvas_container', this.el),
      width     : Ensembl.width,
      tracks    : tracks
    }, Ensembl.genoverseConfig));
    
    if (this.genoverse.failed) {
      return;
    }
    
    this.genoverse.labelContainer.data('updateURL', '/' + Ensembl.species + '/Ajax/track_order').sortable('option', 'handle', '.handle').bind('sortupdate', function (e, ui) {
      var order  = panel.sortUpdate(ui.item);
      var track  = ui.item[0].className.replace(' ', '.');
      
      $.ajax({
        url  : $(this).data('updateURL'),
        type : 'post',
        data : {
          image_config : panel.imageConfig,
          track        : track,
          order        : order
        }
      });
      
      Ensembl.EventManager.triggerSpecific('changeTrackOrder', 'modal_config_' + panel.id.toLowerCase(), track, order);
    });
    
    if (this.genoverse.wheelAction === false) {
      this.genoverse.selectorControls.prepend('<button class="jumpHere">Jump here</button>');
    }
    
    Ensembl.EventManager.trigger('highlightAllImages');
    
    Ensembl._maxRegionLength = Ensembl.maxRegionLength;
    Ensembl.maxRegionLength  = this.genoverse.chromosomeSize;
    
    parent = null;
  },
  
  initControls: function () {
    var panel     = this;
    var genoverse = this.genoverse;  
    
    $('button.scroll', this.elLk.controls).on({
      mousedown : function () { genoverse.startDragScroll(); },
      mouseup   : function () { genoverse.stopDragScroll();  }
    });
    
    $('button.scroll_right', this.elLk.controls).mousehold(50, function () { genoverse.move(false, -100); });
    $('button.scroll_left',  this.elLk.controls).mousehold(50, function () { genoverse.move(false,  100); });
    
    $('button.zoom_in',  this.elLk.controls).on('click', function () { genoverse.zoomIn();  });
    $('button.zoom_out', this.elLk.controls).on('click', function () { genoverse.zoomOut(); });
    
    this.elLk.dragging.on('click', function () {
      genoverse.setDragAction(panel.elLk.dragging.toggleClass('on off').hasClass('on') ? 'scroll' : 'select');
      panel.changeControlTitle('dragging');
    });
    
    this.elLk.wheelZoom.on('click', function () {
      genoverse.setWheelAction(panel.elLk.wheelZoom.toggleClass('on off').hasClass('on') ? 'zoom' : 'off');
      panel.changeControlTitle('wheelZoom');
    });
    
    this.elLk.resetHeight.on('click', function () {
      if (!panel.resetTrackHeights) {
        panel.resetTrackHeights = $.ajax({
          url      : this.value,
          context  : panel.genoverse,
          success  : panel.genoverse.resetTrackHeights,
          complete : function () { panel.resetTrackHeights = false; }
        });
      }
      
      panel.elLk.autoHeight.removeClass('off');
      panel.changeControlTitle('autoHeight');
    });
    
    this.elLk.autoHeight.on('click', function () {
      if (!panel.toggleAutoHeight) {
        panel.toggleAutoHeight = $.ajax({
          url      : this.value,
          data     : { auto_height: panel.genoverse.autoHeight ? 0 : 1 },
          dataType : 'json',
          context  : panel.genoverse,
          success  : panel.genoverse.toggleAutoHeight,
          complete : function () { panel.toggleAutoHeight = false; }
        });
        
        panel.elLk.autoHeight[panel.genoverse.autoHeight ? 'removeClass' : 'addClass']('off');
        panel.changeControlTitle('autoHeight');
      }
    });
    
    this.elLk.imageResize = $('a.image_resize', this.elLk.resizeMenu).off().on('click', function () {
      if (!$(this).has('.current').length) {
        panel.resize(parseInt($(this).text(), 10) || Ensembl.imageWidth());
      }
      
      return false;
    }).not(':first').children(); 
  },
  
  changeControlTitle: function (el) {
    var title = {
      dragging   : [ 'Scroll to a new region',           'Select a portion of this region' ],
      wheelZoom  : [ 'Zoom in or out',                   'Scroll the browser window'       ],
      autoHeight : [ 'Set tracks to auto-adjust height', 'Set tracks to fixed height'      ]
    };
    
    this.elLk[el].attr('title', title[el][this.elLk[el].hasClass('off') ? 1 : 0]);
  },
  
  hashChange: function () {
    this.params.updateURL = Ensembl.urlFromHash(this.params.updateURL);
    
    if (this.genoverse.updatingURL) {
      return this.genoverse.updatingURL = false;
    }
    
    var coords = this.genoverse.getCoords();
    
    if (coords.chr !== this.genoverse.chr) {
      this.hashChangeReload = true;
      return this.base.apply(this, arguments); // TODO: do a complete reset without having to go get HTML again (currently, reset doesn't care about chr change)
    }
    
    var start  = Math.max(this.genoverse.dataRegion.start, 1);
    var end    = Math.min(this.genoverse.dataRegion.end,   this.genoverse.chromosomeSize);
    var length = coords.end - coords.start + 1
    
    if (
      (length === this.genoverse.length || length <= this.genoverse.minSize) &&
      ((coords.start >= start && coords.end <= end) || (coords.start < start && coords.end >= start) || (coords.start <= end && coords.end > end))
    ) {
      this.genoverse.moveTo(coords);
    } else {
      this.genoverse.setRange(coords.start, coords.end, true, true);
    }
  },
  
  highlightImage: function (imageNumber, speciesNumber, start, end) {
    // Make sure each image is highlighted based only on the next image on the page
    if (!this.genoverse || imageNumber - this.imageNumber !== 1) {
      return;
    }
    
    var left  = Math.round((start * this.genoverse.scale) - this.genoverse.scaledStart);
    var width = Math.round((end - start) * this.genoverse.scale);
    
    if (left === 0) {
      left++;
    }
    
    if (width === this.genoverse.width) {
      width--;
    }
    
    if (this.prevHighlight.start !== start || this.prevHighlight.end !== end) {
      this.genoverse.selector.hide();
      this.prevHighlight = { start: start, end: end };
    }
    
    this.genoverse.highlightRegion.css({ left: left, width: width, display: 'block' });
  },
  
  sortUpdate: function (track, order) {
    var tracks = this.genoverse.labelContainer.children(':not(.unsortable)');
    var i, p, n, o;
    
    if (typeof track === 'string') {
      i     = tracks.length;
      track = tracks.filter('.' + track).detach();
      
      if (!track.length) {
        return;
      }
      
      while (i--) {
        if ($(tracks[i]).data('order') < order && tracks[i] !== track[0]) {
          track.insertAfter(tracks[i]);
          break;
        }
      }
      
      if (i === -1) {
        track.insertBefore(tracks[0]);
      }
      
      this.genoverse.tracks[track.data('index')].container[track[0].previousSibling ? 'insertAfter' : 'insertBefore'](this.genoverse.tracks[$(track[0].previousSibling || track[0].nextSibling).data('index')].container);
    } else {
      p = track.prev().data('order') || 0;
      n = track.next().data('order') || 0;
      o = p || n;
      
      if (Math.floor(n) === Math.floor(p)) {
        order = p + (n - p) / 2;
      } else {
        order = o + (p ? 1 : -1) * (Math.round(o) - o || 1) / 2;
      }
    }
    
    track.data('order', order);
    this.genoverse.tracks[track.data('index')].order = order;
    
    this.removeShare();
    
    tracks = track = null;
    
    return order;
  },
  
  makeHoverLabels: function () {
    var panel = this;
    
    if (this.genoverse.failed) {
      return;
    }
    
    this.base();
    
    this.elLk.drag.off();
    
    $.each(this.genoverse.tracks, function () {
      var track = this;
      
      if (this.label.find('.name').length) {
        this.hoverLabel = panel.elLk.hoverLabels.filter('.' + Ensembl.species + '_' + this.id);
        
        if (this.heightToggler) {
          this.hoverLabel.find('img.height').on('click', function () {
            track.heightToggler.trigger('click');
            track.updateHeightToggler();
          });
          
          if (this.autoHeight) {
            this.updateHeightToggler();
          }
        } else {
          this.hoverLabel.find('img.height').hide();
        }
        
        this.label.find('.name').on({
          mouseover: function () {
            var offset   = panel.genoverse.container.offset();
            var position = $(this.parentNode).position();
            
            position.left += offset.left + $(this).position().left;
            position.top  += offset.top  + panel.genoverse.labelContainer.position().top;
            
            if (!track.hoverLabel.hasClass('active')) {
              panel.elLk.hoverLabels.filter('.active').removeClass('active');
              track.hoverLabel.addClass('active');
            }
            
            clearTimeout(panel.hoverTimeout);
            
            panel.hoverTimeout = setTimeout(function () {
              panel.elLk.hoverLabels.filter(':visible').hide().end().filter('.active').css({
                left    : position.left,
                top     : position.top,
                display : 'block'
              });
            }, 100);
          },
          mouseleave: function (e) {
            if (e.relatedTarget) {
              var active = panel.elLk.hoverLabels.filter('.active');
              
              if (!active.has(e.relatedTarget).length) {
                active.removeClass('active').hide();
              }
              
              active = null;
            }
          }
        });
      }
    });
    
    $('a.config', this.elLk.hoverLabels).off().on('click', function () {
      var config = this.rel;
      var update = this.href.split(';').reverse()[0].split('='); // update = [ trackName, renderer ]
      var fav    = '';
      
      if ($(this).hasClass('favourite')) {
        fav = $(this).hasClass('selected') ? 'off' : 'on';
        Ensembl.EventManager.trigger('changeFavourite', update[0], fav === 'on');
      } else {
        $(this).parents('.hover_label').width(function (i, value) {
          return value > 100 ? value : 100;
        }).find('.spinner').show().siblings('div').hide();
      }
      
      $.ajax({
        url      : this.href + fav,
        dataType : 'json',
        context  : this,
        success  : function (json) {
          if (json.updated) {
            Ensembl.EventManager.trigger('hideHoverLabels'); // Hide labels and z menus on other ImageMap panels
            Ensembl.EventManager.triggerSpecific('changeConfiguration', 'modal_config_' + config, update[0], update[1]);
            
            panel.updateTrackRenderer(update[0], update[1]);
          }
        }
      });
      
      return false;
    });
  },
  
  updateTrackRenderer: function (trackName, renderer) {
    var track = this.genoverse.tracksById[trackName];
    
    if (renderer === 'off') {
      this.genoverse.removeTracks([ track ]); // must call removeTracks rather than track.remove() to get the functionality of removing background colours
    } else {
      track.setRenderer(renderer, true);
    }
    
    this.removeShare();
  },
  
  update: function () {
    var genoverse = this.genoverse;
    
    $.ajax({
      url      : '/' + Ensembl.species + '/Genoverse/update',
      data     : { existing: $.map(genoverse.tracksById, function (track, id) { return id + '=' + (track.renderer || 1); }).join(','), config: this.id },
      dataType : 'json',
      context  : this,
      success  : function (json) {
        var flanking = typeof json.viewConfig.flanking === 'undefined' ? false : parseInt(json.viewConfig.flanking, 10);
        var reorder  = false;
        
        if (json.remove.length) {
          genoverse.removeTracks($.map(json.remove, function (id) { return genoverse.tracksById[id]; }));
        }
        
        if (json.add.length) {
          genoverse.addTracks(json.add);
          this.elLk.hoverLabels = this.elLk.hoverLabels.add($(json.labels).appendTo('body'));
          this.makeHoverLabels();
        }
        
        if (json.change.length) {
          $.each(json.change, function () { genoverse.tracksById[this[0]].setRenderer(this[1], true); });
        }
        
        $.each(json.order, function () {
          var track        = genoverse.tracksById[this[0]];
          var order        = this[1];
          var orderReverse = this[2];
          
          if (track && track.unsortable !== true) {
            if (track.strand === -1 && orderReverse) {
              track.order = orderReverse;
              track.label.data('order', orderReverse);
              
              track = track.forwardTrack;
            }
            
            if (track.order !== order) {
              track.order = order;
              track.label.data('order', order);
              
              reorder = true;
            }
          }
        });
        
        if (reorder) {
          genoverse.sortTracks();
        }
        
        if (typeof flanking === 'number' && this.genoverse.flanking !== flanking) {
          this.genoverse.flanking = flanking;
          this.genoverse.setRange(this.start, this.end, true);
        }
        
        this.el[json.viewConfig.show_panel === 'no' ? 'hide' : 'show']();
        this.removeShare();
      }
    });
  },
  
  resize: function (width) {
    width = width || Ensembl.width;
    
    this.elLk.exportMenu.add(this.elLk.resizeMenu).hide();
    this.elLk.imageResize.html(function (i) { var w = (i - 3) * 100 + width; $(this.parentNode.parentNode)[w < 500 ? 'hide' : 'show'](); return w + ' px'; });
    this.elLk.controls[width < 800 ? 'addClass' : 'removeClass']('narrow');
    this.elLk.canvas.width(width);
    this.genoverse.setWidth(width);
  }
});
