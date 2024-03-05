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

Ensembl.Panel.Genoverse = Ensembl.Panel.ImageMap.extend({
  constructor: function() {

    this.base.apply(this, arguments);

    Ensembl.EventManager.register('changeTrackOrder', this, this.externalOrder);
    Ensembl.EventManager.register('updatePanel',      this, this.update);
    Ensembl.EventManager.register('imageResize',      this, this.resize);
    Ensembl.EventManager.register('changeWidth',      this, this.resize);
  },

  init: function () {
    this.prevHighlight = {};
    
    this.base.apply(this, arguments);
    
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
    this.genoverse.updateEnsembl();
    this.applyTrackHighlighting();

    Ensembl.EventManager.register('resetGenoverse',   this, function () { this.genoverse.resetConfig(); });
    Ensembl.EventManager.register('updateCrosshair',  this, function (s) { this.genoverse.moveCrosshair(s); });
  },
  
  applyTrackHighlighting: function () {
    var hl_tracks = $.map($(this.elLk.hoverLabels)
              .filter('.hover_label._hl_on').find('.hl-icon-highlight'),
              function(ele, i) {return $(ele).data('highlightTrack')} );

    this.toggleHighlight(hl_tracks, true);
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
    
    this.genoverse.labelContainer.sortable('option', 'handle', '.gv-handle');
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
    var buttons   = $('button', this.elLk.controls).on('mousedown', function () { genoverse.hideMessages(); }).helptip();
    
    buttons.filter('button.scroll').on({
      mousedown : function () { genoverse.startDragScroll(); },
      mouseup   : function () { genoverse.stopDragScroll();  }
    });
    
    buttons.filter('button.scroll_right').mousehold(50, function () { genoverse.move(-genoverse.scrollDelta); });
    buttons.filter('button.scroll_left' ).mousehold(50, function () { genoverse.move(genoverse.scrollDelta);  });
    
    buttons.filter('button.zoom_in' ).on('click', function () { genoverse.zoomIn();  });
    buttons.filter('button.zoom_out').on('click', function () { genoverse.zoomOut(); });
    
    this.elLk.dragging.on('click', function () {
      if (!$(this).parent().hasClass('selected')) {
        var on = $(this).hasClass('on');
        panel.updateToggleSelectControl(on);
        genoverse.setDragAction(on ? 'scroll' : 'select');
        Ensembl.cookie.set('ENSEMBL_GENOVERSE_SCROLL', on ? '1' : '0');
      }
    }).filter(Ensembl.cookie.get('ENSEMBL_GENOVERSE_SCROLL') === '1' ? '.on' : ':not(.on)').trigger('click');
    
    this.elLk.wheelZoom.on('click', function () {
      if (!$(this).parent().hasClass('selected')) {
        genoverse.setWheelAction(panel.elLk.wheelZoom.parent().toggleClass('selected').filter('.selected').find('button').hasClass('on') ? 'zoom' : 'off');
      }
    });
    
    this.elLk.resetHeight.on('click', function () {
      if (!panel.resetTrackHeights) {
        panel.resetTrackHeights = $.ajax({
          url      : this.value,
          context  : panel.genoverse,
          success  : panel.genoverse.resetTrackHeights,
          complete : function () {
            panel.resetTrackHeights = false;
            panel.updateTrackHeightControl(panel.genoverse.trackAutoHeight);
          }
        });
      }
    });
    
    this.elLk.autoHeight.on('click', function () {
      if (!$(this).parent().hasClass('selected') && !panel.toggleAutoHeight) { // ingore if button's already on, or ajax request already processing

        var isAuto = $(this).hasClass('on');
        panel.updateTrackHeightControl(isAuto);

        if (panel.genoverse.trackAutoHeight !== isAuto) {
          panel.toggleAutoHeight = $.ajax({
            url      : this.value,
            data     : { auto_height: isAuto ? 1 : 0 },
            dataType : 'json',
            context  : panel.genoverse,
            success  : panel.genoverse.toggleAutoHeight,
            complete : function () {
              panel.toggleAutoHeight = false;
              panel.updateTrackHeightControl(panel.genoverse.trackAutoHeight);
            }
          });
        }
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

  initSelector: function() {
    this.elLk.selector = this.genoverse.selector.append('<div class="left-border"></div><div class="right-border"></div>').addClass('selector');
    this.dragRegion = {l: 0, r: this.genoverse.width - 1, a: { klass: {} }}; // required by activateSelector to find out the limits for the selector
    this.activateSelector();
  },

  selectArea: function (arg) {
    if (arg === false && !this.genoverse.dragging) {
      this.genoverse.cancelSelect();
    }
  },

  initLocationMarking: function () {

    this.locationMarkingArea = {
      range : {
        chr   : this.genoverse.chr,
        end   : this.genoverse.end,
        start : this.genoverse.start,
        scale : 1 / this.genoverse.scale
      },
      l : 0,
      r : this.genoverse.wrapper.outerWidth(),
      t : 0,
      b : $(this.elLk.markedLocation).css('height') || 0 // height is updated by updateSelectorHeight method
    };
  },

  markLocation: function () {
    this.base.apply(this, arguments);
    this.genoverse.updateSelectorHeight();
  },

  makeZMenu: function(e, coords, params) { // this only gets called for region ZMenus
    this.genoverse.makeRegionZmenu(e, {left: coords.s, width: coords.r}, params);
  },

  updateTrackHeightControl: function(isAuto) {
    this.elLk.autoHeight.filter('.on').parent().toggleClass('selected', isAuto);
    this.elLk.autoHeight.filter(':not(.on)').parent().toggleClass('selected', !isAuto);
  },

  updateToggleSelectControl: function(on) {
    this.elLk.dragging.filter('.on').parent().toggleClass('selected', on);
    this.elLk.dragging.filter(':not(.on)').parent().toggleClass('selected', !on);
    this.removeZMenus();
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

      if (!this.elLk.highlightRegion) {
        this.elLk.highlightRegion = $('<div class="gv-selector gv-highlight">').prependTo(this.genoverse.wrapper);
      }

    }
    this.elLk.highlightRegion.css({ left: left, width: width, display: 'block' });
    this.genoverse.updateSelectorHeight();
  },
  
  externalOrder: function (label, order) {
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

    this.elLk.drag.off();
    
    $.each(this.genoverse.tracks, function () {
      var track = this;
      var label = this.prop('label');
      
      if (label.find('.gv-name:not(:empty)').length) {

        this.hoverLabel = panel.elLk.hoverLabels.filter(':not(.allocated).' + this.id).first().addClass('allocated').appendTo(label).css({ left : label.find('.gv-name').width(), top: 0 });

        var share_url = this.hoverLabel.find('.hl-content ._copy_url').val();
        // Create an href from <a> and get a valid url
        this.hoverLabel.find('.hl-content ._copy_url').val(($('<a/>', {'href': share_url})).prop('href'));

        label.addClass('_label_layer').children('.gv-name').removeAttr('title')
              .on('click', function (e) {
                e.stopPropagation();
                $(this).parent().find('.hover_label').first().trigger('open');
              }).end().children('.hover_label')
              .on({
                'open': function() {

                  $(document).on('click.gv-hover-label', {el: this}, function(e) {
                    $(e.data.el).trigger('close');
                  });

                  $(this).trigger('close');

                  // show label
                  $(this).show().find('._dyna_load').removeClass('_dyna_load').dynaLoad(); // dynaload any track description too
                },
                'close' : function() {
                  panel.elLk.hoverLabels.filter(function() {
                    return !$(this).closest('.pinned').length;
                  }).hide();
                  $(document).off('.gv-hover-label');
                },
                'click' : function (e) {
                  if (e.target.nodeName !== 'A') {
                    e.stopPropagation();
                  }
                }
              }).externalLinks()
              .find('.close').off().on({
                click: function(e) {
                  $(this).siblings('._hl_pin').removeClass('on')
                         .closest('._label_layer').removeClass('pinned');
                  $(this).parent().trigger('close');
                }
              }).end().find('.config').on('click', function() {
                $(this).closest('.hover_label').trigger('close');
              });

        if (this.resizable === true) {
          this.hoverLabel.find('a.height').on('click', function (e) {

            e.preventDefault();

            var height;

            if ((track.autoHeight = !track.autoHeight)) {
              track.heightBeforeToggle = track.height;
              height = track.prop('fullVisibleHeight');
            } else {
              height = track.heightBeforeToggle || track.initialHeight;
            }

            track.controller.resize(height, true);
            track.updateHeightToggler();
          });

          if (this.autoHeight) {
            this.updateHeightToggler();
          }
        } else {
          this.hoverLabel.find('._track_height').remove();
        }
      }
    });

    this.initHoverLabels();
  },

  toggleHighlight: function(track_ids, _on) {
    var panel = this;

    if (!Array.isArray(track_ids)) {
      track_ids = [track_ids];
    }

    $.each(track_ids, function(i, tr) {
      var track = tr && tr.split('.')[0];
      var tracks = $.grep(panel.genoverse.tracks, function(trk) {
                            return trk.id === track;
                          });
      track_element = (tracks.length > 0) ? tracks[0].controller.container : null;

      if (!track_element) {
        return;
      }

      var label = tracks[0].prop('label');

      if (_on) {
        $(track_element) && $(track_element, label).addClass('track_highlight');  
        $(label) && $(label).addClass('track_highlight');
      }
      else {
        if (_on !== '' && _on !== undefined) {
          $(track_element) && $(track_element, label).removeClass('track_highlight');
          $(label) && $(label).removeClass('track_highlight');  
        }
        else {
          $(track_element) && $(track_element, label).toggleClass('track_highlight');
          $(label) && $(label).toggleClass('track_highlight');  
        }
      }
      
      if ($(track_element).hasClass('track_highlight')) {
        panel.highlightedTracks[track] = 1;
      }
      else {
        panel.highlightedTracks[track] && delete panel.highlightedTracks[track];
      }
    });

    this.updateExportButton();
  },

  handleConfigClick: function (link) {
    this.base(link);
    $(link).parents('._label_layer').removeClass('hover_label_spinner');
  },

  changeConfiguration: function (config, trackName, renderer) {
    Ensembl.EventManager.triggerSpecific('changeConfiguration', 'modal_config_' + config, trackName, renderer);
    this.updateTrackRenderer(trackName, renderer);
    this.elLk.hoverLabels.filter('.' + trackName).find('.clicked').css('opacity', 1);
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
          this.elLk.hoverLabels.remove();
          this.elLk.hoverLabels = $(json.labels.trim()).appendTo('body');
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
              track.prop('order', orderReverse);
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

  getExtraExportParam: function () {
    var extra = this.base.apply(this, arguments);

    if (extra && extra.mark) {
      extra.mark.x += this.genoverse.labelWidth - 2;
      delete extra.mark.h;
      delete extra.mark.y;
    }

    return extra;
  },

  resize: function (width) {
    width = width || Ensembl.width;
    
    this.elLk.resizeMenu.hide();
    this.elLk.imageResize.html(function (i) { var w = (i - 3) * 100 + width; $(this.parentNode.parentNode)[w < 500 ? 'hide' : 'show'](); return w + ' px'; });
    this.elLk.controls[width < 800 ? 'addClass' : 'removeClass']('narrow');
    this.elLk.container.css({ width: width, height: '' }).resizable('option', 'maxWidth', $(window).width() - this.el.offset().left);
    this.genoverse.setWidth(width);
  }
});
