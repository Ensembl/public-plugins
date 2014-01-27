/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.Genoverse = Ensembl.Panel.ImageMap.extend({
  init: function () {
    this.prevHighlight = {};
    
    this.base();
    
    if (this.genoverse.failed) {
      return;
    }
    
    this.elLk.img         = this.genoverse.container;
    this.elLk.boundaries  = this.genoverse.labelContainer;
    this.elLk.controls    = $('.genoverse_controls', this.elLk.container).each(function () { $(this).prev().append(this); });
    this.elLk.autoHeight  = $('.auto_height',        this.elLk.controls);
    this.elLk.resetHeight = $('.reset_height',       this.elLk.controls);
    this.elLk.dragging    = $('.dragging',           this.elLk.controls);
    this.elLk.wheelZoom   = $('.wheel_zoom',         this.elLk.controls);
    
    this.initControls();
    
    Ensembl.EventManager.register('changeTrackOrder', this, this.sortUpdate);
    Ensembl.EventManager.register('updatePanel',      this, this.update);
    Ensembl.EventManager.register('imageResize',      this, this.resize);
    Ensembl.EventManager.register('changeWidth',      this, this.resize);
    Ensembl.EventManager.register('resetGenoverse',   this, function () { this.genoverse.resetConfig(); });
  },
  
  makeImageMap: function () {
    var tracks = $.extend(true, [], Ensembl.genoverseConfig.tracks);
    
    this.setImageNumber();
    
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
    
    this.genoverse.labelContainer.sortable('option', 'handle', '.handle');
    
    if (this.genoverse.wheelAction === false) {
      this.genoverse.selectorControls.prepend('<button class="jumpHere">Jump here</button>');
    }
  },
  
  setImageNumber: function () {
    var panel  = this;
    var parent = this.el.parents('.image_panel')[0];
    
    $('.image_panel').each(function (i) {
      if (this === parent) {
        panel.imageNumber = i + 1;
        Ensembl.images[panel.imageNumber] = { 0: [ panel.imageNumber, 0, Ensembl.genoverseConfig.start, Ensembl.genoverseConfig.end ] };
      }
    });
    
    Ensembl.EventManager.trigger('highlightAllImages');
    
    parent = null;
  },
  
  initControls: function () {
    var panel     = this;
    var genoverse = this.genoverse;  
    var buttons   = $('button', this.elLk.controls).on('mousedown', function () { genoverse.hideMessages(); });
    
    buttons.filter('button.scroll').on({
      mousedown : function () { genoverse.startDragScroll(); },
      mouseup   : function () { genoverse.stopDragScroll();  }
    });
    
    buttons.filter('button.scroll_right').mousehold(50, function () { genoverse.move(-genoverse.scrollDelta); });
    buttons.filter('button.scroll_left' ).mousehold(50, function () { genoverse.move(genoverse.scrollDelta);  });
    
    buttons.filter('button.zoom_in' ).on('click', function () { genoverse.zoomIn();  });
    buttons.filter('button.zoom_out').on('click', function () { genoverse.zoomOut(); });
    
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
          data     : { auto_height: panel.genoverse.trackAutoHeight ? 0 : 1 },
          dataType : 'json',
          context  : panel.genoverse,
          success  : panel.genoverse.toggleAutoHeight,
          complete : function () { panel.toggleAutoHeight = false; }
        });
        
        panel.elLk.autoHeight[panel.genoverse.trackAutoHeight ? 'removeClass' : 'addClass']('off');
        panel.changeControlTitle('autoHeight');
      }
    });
    
    this.elLk.imageResize = $('a.image_resize', this.elLk.resizeMenu).off().on('click', function () {
      if (!$(this).has('.current').length) {
        panel.resize(parseInt($(this).text(), 10) || Ensembl.imageWidth());
      }
      
      return false;
    }).not(':first').children();
    
    buttons = null;
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
    
    var coords = this.genoverse.getURLCoords();
    
    if (coords.chr !== this.genoverse.chr) {
      this.hashChangeReload = true;
      return this.base.apply(this, arguments); // TODO: do a complete reset without having to go get HTML again (currently, reset doesn't care about chr change)
    }
    
    this.genoverse.popState();
    this.genoverse.updatingURL = false;
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
      this.prevHighlight = { start: start, end: end };
    }
    
    this.genoverse.highlightRegion.css({ left: left, width: width, display: 'block' });
  },
  
  sortUpdate: function (label, order) {
    var labels = this.genoverse.labelContainer.children(':not(.unsortable)');
    
    label = labels.filter('.' + label).detach();
    
    if (!label.length) {
      return;
    }
    
    var track = label.data('track');
    var i     = labels.length;
    
    while (i--) {
      if ($(labels[i]).data('track').order < order && labels[i] !== label[0]) {
        label.insertAfter(labels[i]);
        break;
      }
    }
    
    if (i === -1) {
      label.insertBefore(labels[0]);
    }
    
    track.order = order;
    
    this.genoverse.sortTracks();
    this.removeShare();
    
    labels = label = null;
    
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
      var label = this.prop('label');
      
      if (label.find('.name').length) {
        this.hoverLabel = panel.elLk.hoverLabels.filter('.' + Ensembl.species + '_' + this.id);
        
        if (this.resizable === true) {
          this.hoverLabel.find('img.height').on('click', function () {
            var height;
            
            if ((track.autoHeight = !track.autoHeight)) {
              track.heightBeforeToggle = track.height;
              height = track.prop('fullVisibleHeight');
            } else {
              height = track.heightBeforeToggle || track.initialHeight;
            }
            
            $(this).toggleClass('auto_height').children(':visible').hide().siblings().show();
            
            track.controller.resize(height, true);
            track.updateHeightToggler();
          });
          
          if (this.autoHeight) {
            this.updateHeightToggler();
          }
        } else {
          this.hoverLabel.find('img.height').hide();
        }
        
        label.find('.name').on({
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
    var track      = this.genoverse.tracksById[trackName];
    var otherTrack = track.prop('reverseTrack') || track.prop('forwardTrack');
    
    if (renderer === 'off') {
      this.genoverse.removeTrack(track); // must call removeTrack rather than track.remove() to get the functionality of removing background colours
    } else {
      track.setRenderer(renderer);
      
      if (otherTrack) {
        otherTrack.track.setRenderer(renderer);
      }
    }
    
    this.removeShare();
  },
  
  update: function () {
    var panel     = this;
    var genoverse = this.genoverse;
    
    $.ajax({
      url      : '/' + Ensembl.species + '/Genoverse/update',
      data     : { existing: $.map(genoverse.tracksById, function (track, id) { return id + '=' + (track.prop('renderer') || 1); }).join(','), config: this.id },
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
          this.elLk.hoverLabels = this.elLk.hoverLabels.add($(json.labels.trim()).appendTo('body'));
          this.makeHoverLabels();
        }
        
        if (json.change.length) {
          $.each(json.change, function () { panel.updateTrackRenderer(this[0], this[1]); });
        }
        
        $.each(json.order, function () {
          var track        = genoverse.tracksById[this[0]];
          var order        = this[1];
          var orderReverse = this[2];
          
          if (track && track.prop('unsortable') !== true) {
            if (track.prop('strand') === -1 && orderReverse) {
              track.prop('order') = orderReverse;
              track.prop('label').data('order', orderReverse);
              
              track = track.prop('forwardTrack');
            }
            
            if (track.prop('order') !== order) {
              track.prop('order', order);
              track.prop('label').data('order', order);
              
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
        Ensembl.EventManager.trigger('ajaxLoaded');
        
        if (json.viewConfig.show_panel === 'no') {
          delete Ensembl.images[this.imageNumber];
          Ensembl.EventManager.trigger('highlightAllImages');
        } else {
          this.setImageNumber();
        }
      }
    });
  },
  
  resize: function (width) {
    width = width || Ensembl.width;
    
    this.elLk.exportMenu.add(this.elLk.resizeMenu).hide();
    this.elLk.imageResize.html(function (i) { var w = (i - 3) * 100 + width; $(this.parentNode.parentNode)[w < 500 ? 'hide' : 'show'](); return w + ' px'; });
    this.elLk.controls[width < 800 ? 'addClass' : 'removeClass']('narrow');
    this.elLk.container.css({ width: width, height: '' }).resizable('option', 'maxWidth', $(window).width() - this.el.offset().left);
    this.genoverse.setWidth(width);
  }
});
