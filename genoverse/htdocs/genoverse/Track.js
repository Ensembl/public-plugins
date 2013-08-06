// $Revision$

Genoverse.Track = Base.extend({
  height         : 12,
  bumpSpacing    : 2,
  featureSpacing : 1,
  minScaledWidth : 0.5,
  fontHeight     : 10,
  fontFamily     : 'sans-serif',
  fontWeight     : 'normal',
  fontColor      : '#000000',
  color          : '#000000',
  labels         : true,
  bump           : false,
  urlParams      : {},
  urlTemplate    : {},
  xhrFields      : {},
  dataType       : 'json',
  dataBuffer     : { start: 0, end: 0 }, // basepairs, extend data region for, when getting data from the origin
  scrollBuffer   : 1.2,                  // number of widths, if left or right closer to the edges of viewpoint than the buffer, start making more images
  inherit        : [],
  messages       : {
    error     : 'ERROR: ',
    threshold : 'Data for this track is not displayed in regions greater than ', // + this.formatLabel(this.threshold)
    resize    : 'Some features are currently hidden, resize to see all'
  },
  
  constructor: function (config) {
    var deepCopy = {};
    var key;
    
    // Deep clone all [..] and {..} objects in this to prevent sharing between instances
    for (key in this) {
      if (typeof this[key] === 'object') {
        deepCopy[key] = this[key];
      }
    }
    
    this.featureHeight     = typeof this.featureHeight !== 'undefined' ? this.featureHeight : this.height; // Feature height must be based on default height, not config.height, which could be anything
    this.defaultHeight     = this.height;
    this.defaultAutoHeight = this.autoHeight;
    
    this.extend($.extend(true, {}, deepCopy));
    this.extend(config); // Use Base.extend to make any function in config have this.base
    
    for (var i = 0; i < this.inherit.length; i++) {
      if (Genoverse.Track[this.inherit[i]]) {
        this.extend(Genoverse.Track[this.inherit[i]]);
      }
    }
    
    if (typeof this.inheritedConstructor === 'function') {
      this.inheritedConstructor(config);
    }
    
    for (key in this) {
      if (typeof this[key] === 'function' && !key.match(/^(base|extend|constructor|functionWrap|debugWrap)$/)) {
        this.browser.functionWrap(key, this);
      }
    }
    
    this.imgRange       = {};
    this.scrollRange    = {};
    this.order          = typeof this.order            !== 'undefined' ? this.order            : this.index;
    this.spacing        = typeof this.spacing          !== 'undefined' ? this.spacing          : this.browser.trackSpacing;
    this.fixedHeight    = typeof this.fixedHeight      !== 'undefined' ? this.fixedHeight      : this.featureHeight === this.height && !this.bump;
    this.autoHeight     = typeof this.autoHeight       !== 'undefined' ? this.autoHeight       : !this.fixedHeight && !config.height ? this.browser.autoHeight : false;
    this.resizable      = typeof this.resizable        !== 'undefined' ? this.resizable        : !this.fixedHeight;
    this.height        += this.spacing;
    this.initialHeight  = this.height;
    this.minLabelHeight = 0;
    this.font           = this.fontWeight + ' ' + this.fontHeight + 'px ' + this.fontFamily;
    this.labelUnits     = [ 'bp', 'kb', 'Mb', 'Gb', 'Tb' ];
    
    if (this.hidden) {
      this.height = 0;
    }
    
    if (this.autoHeight === 'force') {
      this.autoHeight  = true;
      this.fixedHeight = false;
      this.resizable   = false;
    } else if (this.threshold) {
      this.thresholdMessage = this.formatLabel(this.threshold);
    }
    
    if (this.labels && this.labels !== 'overlay' && (this.depth || this.bump === 'labels')) {
      this.labels = 'separate';
    }
    
    if (this.url) {
      this.setURL();
    }
    
    this.addDomElements();
    this.addUserEventHandlers();
    this.init();
    this.setScale();
  },
  
  init: function () {
    if (this.renderer) {
      this.featuresByRenderer   = {};
      this.featuresByIdRenderer = {};
      this.setRenderer(this.renderer, true);
    } else {
      this.features     = new RTree();
      this.featuresById = {};
      this.dataRanges   = {};
    }
    
    this.scaleSettings = {};
  },
  
  reset: function () {
    this.resetImages();
    this.browser.closeMenus.call(this);
    
    if (this.url !== false) {
      this.init();
    }
  },
  
  resetImages: function () {
    this.imgRange    = {};
    this.scrollRange = {};
    this.scrollContainer.empty();
    this.resetImageRanges();
  },
  
  resetImageRanges: function () {
    this.left        = 0;
    this.scrollStart = 'ss_' + this.browser.start + '_' + this.browser.end;
    
    this.imgRange[this.scrollStart]    = this.imgRange[this.scrollStart]    || { left: this.width * -2, right: this.width * 2 };
    this.scrollRange[this.scrollStart] = this.scrollRange[this.scrollStart] || { start: this.browser.start - this.browser.length, end: this.browser.end + this.browser.length };
  },
  
  resetFeaturePositions: function () {
    this.scaleSettings    = {};
    this.featurePositions = new RTree();
    this.labelPositions   = this.labels === 'separate' ? new RTree() : this.featurePositions;
    
    for (var id in this.featuresById) {
      delete this.featuresById[id].position;
    }
  },
  
  rename: function (name) {
    this.name           = name;
    this.minLabelHeight = $('span.name', this.label).html(this.name).outerHeight(true);
    
    this.label.height(this.hidden ? 0 : Math.max(this.height, this.minLabelHeight));
  },
  
  setURL: function () {
    var track = this;
    
    this.url = this.url.split('?');
    
    if (this.url[1]) {
      $.each(this.url[1].split(/[;&]/), function () {
        var tmp = this.split('=');
        track[tmp[1].match(/__(CHR|START|END)__/) ? 'urlTemplate' : 'urlParams'][tmp[0]] = tmp[1];
      });
    }
    
    this.url = this.url[0];
    
    if (this.browser.proxy) {
      this.urlParams.url = this.url;
      this.url = this.browser.proxy;
    }
  },
  
  addDomElements: function () {
    var track = this;
    
    this.menus            = $();
    this.container        = $('<div class="track_container">').appendTo(this.browser.wrapper);
    this.scrollContainer  = $('<div class="scroll_container">').appendTo(this.container);
    this.imgContainer     = $('<div class="image_container">').width(this.width);
    this.messageContainer = $('<div class="message_container"><div class="messages"></div><span class="control collapse">&laquo;</span><span class="control expand">&raquo;</span></div>').appendTo(this.container);
    this.border           = $('<div class="track_border">').appendTo(this.container);
    this.label            = $('<li>').appendTo(this.browser.labelContainer).height(this.height).data('track', this);
    this.context          = $('<canvas>')[0].getContext('2d');
    
    if (this.unsortable) {
      this.label.addClass('unsortable');
    } else {
      $('<div class="handle">').appendTo(this.label);
    }
    
    this.minLabelHeight = $('<span class="name" title="' + (this.name || '') + '">' + (this.name || '') + '</span>').appendTo(this.label).outerHeight(true);
    
    var h = this.hidden ? 0 : Math.max(this.height, this.minLabelHeight);
    
    if (this.minLabelHeight) {
      this.label.height(h);
    }
    
    this.container.height(h);
    
    if (!this.fixedHeight && this.resizable !== false) {
      this.heightToggler = $('<div class="height_toggler"><div class="auto">Set track to auto-adjust height</div><div class="fixed">Set track to fixed height</div></div>').on({
        mouseover : function () { $(this).children(track.autoHeight ? '.fixed' : '.auto').show(); },
        mouseout  : function () { $(this).children().hide(); },
        click     : function () {
          var height;
          
          if ((track.autoHeight = !track.autoHeight)) {
            track.heightBeforeToggle = track.height;
            height = track.fullVisibleHeight;
          } else {
            height = track.heightBeforeToggle || track.initialHeight;
          }
          
          $(this).toggleClass('auto_height').children(':visible').hide().siblings().show();
          
          track.resize(height, true);
        }
      }).addClass(this.autoHeight ? 'auto_height' : '').appendTo(this.label);
    }
  },
  
  addUserEventHandlers: function () {
    var track   = this;
    var browser = this.browser;
    
    this.container.on('mouseup', '.image_container', function (e) {
      if ((e.which && e.which !== 1) || browser.start !== browser.dragStart || (browser.dragAction === 'select' && browser.selector.outerWidth(true) > 2)) {
        return; // Only show menus on left click when not dragging and not selecting
      }

      track.click(e);
    });
    
    this.messageContainer.on('click', '> *', function () {
      var collapsed = track.messageContainer.children('.messages').is(':visible') ? ' collapsed' : '';
      var code      = track.messageContainer.find('.msg')[0].className.replace('msg', '').replace(' ', '');
      
      track.messageContainer.attr('class', 'message_container' + collapsed);
      
      if (code !== 'error') {
        document.cookie = [ 'gv_msg', code, track.id ].join('_') + '=1; expires=' + (collapsed ? 'Tue, 19 Jan 2038' : 'Thu, 01 Jan 1970') + ' 00:00:00 GMT; path=/';
      }
      
      track.checkHeight();
    });
  },
  
  click: function (e) {
    var x = e.pageX - this.container.parent().offset().left + this.browser.scaledStart;
    var y = e.pageY - $(e.target).offset().top;
    var f = this[e.target.className === 'labels' ? 'labelPositions' : 'featurePositions'].search({ x: x, y: y, w: 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; })[0];
    
    if (f) {
      this.browser.makeMenu(f, e, this);
    }
  },
  
  // FIXME: messages are now hidden/shown instead of removed/added. This will cause a problem if a new message arrives with the same code as one that already exists.
  showMessage: function (code, additionalText) {
    var messages = this.messageContainer.children('.messages');
    
    if (!messages.children('.' + code).show().length) {
      messages.prepend('<div class="msg ' + code + '">' + this.messages[code] + (additionalText || '') + '</div>');
      this.messageContainer[document.cookie.match([ 'gv_msg', code, this.id ].join('_') + '=1') ? 'addClass' : 'removeClass']('collapsed');
    }
    
    var height = this.messageContainer.show().outerHeight(true);
    
    if (height > this.height) {
      this.resize(height);
    }
    
    messages = null;
  },
  
  hideMessage: function (code) {
    var messages = this.messageContainer.find('.msg');
    
    if (code) {
      if (!messages.filter('.' + code).hide().siblings().filter(function () { return this.style.display !== 'none'; }).length) {
        this.messageContainer.hide();
      }
    } else {
      messages.hide();
      this.messageContainer.hide();
    }
    
    messages = null;
  },
  
  checkHeight: function () {
    var autoHeight;
    
    if (this.threshold && this.browser.length > this.threshold) {
      autoHeight      = this.autoHeight;
      this.autoHeight = true;
      
      if (this.thresholdMessage) {
        this.showMessage('threshold', this.thresholdMessage);
        this.fullVisibleHeight = this.messageContainer.outerHeight(true);
      } else {
        this.fullVisibleHeight = 0;
      }
    } else {
      var bounds = { x: this.browser.scaledStart, w: this.width, y: 0, h: 9e99 };
      var scale  = this.scale;
      var height = Math.max.apply(Math, $.map(this.featurePositions.search(bounds), function (feature) { return feature.position[scale].bottom; }).concat(0));
      
      if (this.labels === 'separate') {
        this.labelTop = height;
        height += Math.max.apply(Math, $.map(this.labelPositions.search(bounds), function (feature) { return feature.position[scale].label.bottom; }).concat(0));
      }
      
      if (this.thresholdMessage) {
        this.hideMessage('threshold');
      }
      
      this.fullVisibleHeight = height || (this.messageContainer.is(':visible') ? this.messageContainer.outerHeight(true) : 0);
    }
    
    this.autoResize();
    
    if (typeof autoHeight !== 'undefined') {
      this.autoHeight = autoHeight;
    }
  },
  
  autoResize: function () {
    if (this.autoHeight || this.labels === 'separate') {
      this.resize(this[this.autoHeight ? 'fullVisibleHeight' : 'height'], this.labelTop);
    } else {
      this.toggleExpander();
    }
  },
  
  resize: function (height) {
    if (arguments[1] !== true && height < this.featureHeight) {
      height = 0;
    } else {
      height = this.hidden ? 0 : Math.max(height, this.minLabelHeight);
    }
    
    this.height = height;
    
    if (typeof arguments[1] === 'number') {
      this.imgContainers.children('.labels').css('top', arguments[1]);
    }
    
    this.container.height(height);
    this.label.height(height)[height ? 'show' : 'hide']();
    this.toggleExpander();
  },
  
  toggleExpander: function () {
    if (!this.resizable) {
      return;
    }
    
    var track = this;
    
    // Note: this.fullVisibleHeight - this.bumpSpacing is not actually the correct value to test against, but it's the easiest best guess to obtain.
    // this.fullVisibleHeight is the maximum bottom position of the track's features in the region, which includes spacing at the bottom of each feature and label
    // Therefore this.fullVisibleHeight includes this spacing for the bottom-most feature.
    // The correct value (for a track using the default positionFeatures code) is:
    // this.fullVisibleHeight - ([there are labels in this region] ? (this.labels === 'separate' ? 0 : this.bumpSpacing + 1) + 2 : this.bumpSpacing)
    //                                                                ^ padding on label y-position                            ^ margin on label height
    if (this.fullVisibleHeight - this.bumpSpacing > this.height) {
      this.showMessage('resize');
      
      var height = this.messageContainer.outerHeight(true);
      
      if (height > this.height) {
        this.resize(height);
      }
      
      this.expander = (this.expander || $('<div class="expander static">').width(this.width).appendTo(this.container).on('click', function () {
        track.resize(track.fullVisibleHeight);
      }))[this.height === 0 ? 'hide' : 'show']();
    } else if (this.expander) {
      this.hideMessage('resize');
      this.expander.hide();
    }
  },
  
  setWidth: function (width) {
    this.width = width;
    this.imgContainer.width(width);
  },
  
  setScale: function () {
    var track = this;
    var featurePositions, labelPositions;
    
    this.scale = this.browser.scale;
    
    this.resetImageRanges();
    
    if (this.renderer) {
      var renderer = this.getRenderer();
      
      if (renderer !== this.urlParams.renderer) {
        this.setRenderer(renderer);
      }
    }
    
    // Don't draw labels if the region is too big
    if (this.maxLabelRegion) {
      if (this.maxLabelRegion < this.browser.length) {
        if (this.labels) {
          this._labels = this.labels;
          this.labels  = false;
        }
      } else if (typeof this._labels !== 'undefined') {
        this.labels = this._labels;
        delete this._labels;
      }
    }
    
    if (this.labels && this.labels !== 'overlay') {
      this.dataBuffer.start = Math.max(this.dataBuffer.start, this.browser.labelBuffer);
    }
    
    if (!this.scaleSettings[this.scale]) {
      featurePositions = featurePositions || new RTree();
      
      this.scaleSettings[this.scale] = {
        imgContainers    : $(),
        featurePositions : featurePositions,
        labelPositions   : this.labels === 'separate' ? labelPositions || new RTree() : featurePositions
      };
    }
    
    $.each(this.scaleSettings[this.scale], function (k, v) { track[k] = v; });
    
    this.hideMessage();
    
    if (this.scrollContainer.children().hide().filter('.' + this.scrollStart).show().length) {
      this.checkHeight();
    } else {
      this.scrollContainer.css('left', 0);
      this.makeFirstImage();
    }
  },
  
  setRenderer: function (renderer, permanent) {
    if (this.urlParams.renderer !== renderer) {
      this.urlParams.renderer = renderer;
      this.dataRanges         = {};
      this.features           = (this.featuresByRenderer[renderer]   = this.featuresByRenderer[renderer]   || new RTree());
      this.featuresById       = (this.featuresByIdRenderer[renderer] = this.featuresByIdRenderer[renderer] || {});
    }
    
    if (permanent && this.renderer !== renderer) {
      this.renderer = renderer;
      this.reset();
      this.setScale();
    }
  },
  
  getRenderer: function () {
    return this.urlParams.renderer;
  },
  
  /**
  * parseData(data, start, end) - parse raw data from the data source (e.g. online web service)
  * extract features and insert it into the internal features storage (RTree)
  *
  * >> data  - raw data from the data source (e.g. ajax response)
  * >> start - start location of the data
  * >> end   - end   location of the data
  * << nothing
  *
  * every feature extracted this routine must construct a hash with at least 3 values:
  *  {
  *    id    : [unique feature id, string],
  *    start : [chromosomal start position, integer],
  *    end   : [chromosomal end position, integer],
  *    [other optional key/value pairs]
  *  }
  *
  * and call this.insertFeature(feature)
  */
  parseData: function (data, start, end) {
    // Example of parseData function when data is an array of hashes like { start: ..., end: ... }
    for (var i = 0; i < data.length; i++) {
      var feature = data[i];
      
      feature.sort = start + i;
      
      this.insertFeature(feature);
    }
  },
  
  insertFeature: function (feature) {
    // Make sure we have a unique ID, this method is not efficient, so better supply your own id
    if (!feature.id) {
      feature.id = JSON.stringify(feature).hashCode();
    }
    
    if (!this.featuresById[feature.id]) {
      this.features.insert({ x: feature.start, y: 0, w: feature.end - feature.start + 1, h: 1 }, feature);
      this.featuresById[feature.id] = feature;
    }
  },
  
  findFeatures: function (start, end) {
    return this.features.search({ x: start - this.dataBuffer.start, y: 0, w: end - start + this.dataBuffer.start + this.dataBuffer.end + 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; });
  },
  
  move: function (delta) {
    this.left += delta;
    this.scrollContainer.css('left', this.left);
    
    var scrollStart = this.scrollStart;
    
    if (this.imgRange[scrollStart].left + this.left > -this.scrollBuffer * this.width) {
      var end = this.scrollRange[scrollStart].start - 1;
      
      this.makeImage({
        scale : this.scale,
        start : end - this.browser.length + 1,
        end   : end,
        left  : this.imgRange[scrollStart].left,
        cls   : scrollStart
      });
      
      this.imgRange[scrollStart].left     -= this.width;
      this.scrollRange[scrollStart].start -= this.browser.length;
    }
    
    if (this.imgRange[scrollStart].right + this.left < this.scrollBuffer * this.width) {
      var start = this.scrollRange[scrollStart].end + 1;
      
      this.makeImage({
        scale : this.scale,
        start : start,
        end   : start + this.browser.length - 1,
        left  : this.imgRange[scrollStart].right,
        cls   : scrollStart
      });
      
      this.imgRange[scrollStart].right  += this.width;
      this.scrollRange[scrollStart].end += this.browser.length;
    }
  },
  
  moveTo: function (start, end, delta) {
    var scrollRange = this.scrollRange[this.scrollStart];
    var scrollStart = 'ss_' + start + '_' + end;
    
    if (this.scrollRange[scrollStart] || start > scrollRange.end || end < scrollRange.start) {
      this.resetImageRanges();
      
      if (!this.scrollContainer.css('left', 0).children().hide().filter('.' + scrollStart).show().length) {
        return this.makeFirstImage();
      }
    } else {
      this.move(typeof delta === 'number' ? delta : (start - this.browser.start) * this.scale);
    }
    
    this.checkHeight();
  },
  
  makeImage: function (params) {
    params.scaledStart   = params.scaledStart   || params.start * params.scale;
    params.width         = params.width         || this.width;
    params.height        = params.height        || this.height;
    params.featureHeight = params.featureHeight || 0;
    params.labelHeight   = params.labelHeight   || 0;
    
    var deferred;
    var tooLarge = this.threshold && this.threshold < this.browser.length;
    var div      = this.imgContainer.clone().addClass((params.cls + ' loading').replace('.', '_')).css({ left: params.left, display: params.cls === this.scrollStart ? 'block' : 'none' });
    var bgImage  = params.background ? $('<img class="bg">').addClass(params.background).data(params).prependTo(div) : false;
    var image    = $('<img class="data">').hide().data(params).appendTo(div).load(function () {
      $(this).fadeIn('fast').parent().removeClass('loading');
    });
    
    params.container = div;
    
    this.imgContainers.push(div[0]);
    this.scrollContainer.append(this.imgContainers);
    
    if (!tooLarge && !this.checkDataRange(params.start, params.end)) {
      params.start -= this.dataBuffer.start;
      params.end   += this.dataBuffer.end;
      deferred      = this.getData(params.start, params.end);
    }
    
    if (!deferred) {
      deferred = $.Deferred();
      setTimeout($.proxy(deferred.resolve, this), 1); // This defer makes scrolling A LOT smoother, pushing render call to the end of the exec queue
    }
    
    return deferred.done(function () {
      var features = tooLarge ? [] : this.findFeatures(params.start, params.end);
      
      this.render(features, image);
      
      if (bgImage) {
        this.renderBackground(features, bgImage);
      }
    });
  },
  
  makeFirstImage: function () {
    var start   = this.browser.start;
    var end     = this.browser.end;
    var length  = this.browser.length;
    var scale   = this.scale;
    var cls     = this.scrollStart;
    var loading = this.imgContainer.clone().addClass('loading').prependTo(this.scrollContainer);
    
    function makeImages() {
      this.makeImage({ start: start,          end: end,          scale: scale, cls: cls, left: 0           });
      this.makeImage({ start: start - length, end: start - 1,    scale: scale, cls: cls, left: -this.width });
      this.makeImage({ start: end + 1,        end: end + length, scale: scale, cls: cls, left: this.width  });
      loading.remove();
    }
    
    // FIXME: on zoom out, making more than 1 request
    if (this.threshold && this.threshold < length || this.checkDataRange(start, end)) {
      makeImages.call(this);
    } else {
      this.getData(start - this.dataBuffer.start - length, end + this.dataBuffer.end + length).done(makeImages);
    }
  },
  
  getData: function (start, end) {
    return this.url ? $.ajax({
      url       : this.url,
      data      : this.getQueryString(start, end),
      dataType  : this.dataType,
      context   : this,
      xhrFields : this.xhrFields,
      success   : function (data) { this.receiveData(data, start, end); },
      error     : this.showError
    }) : $.Deferred().resolveWith(this);
  },
  
  receiveData: function (data, start, end) {
    start = Math.max(start, 1);
    end   = Math.min(end, this.browser.chromosomeSize);
    
    this.setDataRange(start, end);
    this.parseData(data, start, end);
  },
  
  setDataRange: function (start, end) {
    if (this.allData) {
      this.dataRanges = { 1: this.browser.chromosomeSize };
      return;
    }
    
    var sorted   = $.map(this.dataRanges, function (e, s) { return parseInt(s, 10); }).sort(function (a, b) { return a - b; });
    var i        = sorted.length;
    var toDelete = {};
    var done     = false;
    var s, e;
    
    while (i--) {
      s = sorted[i];
      e = this.dataRanges[s];
      
      if ((s === start && e === end) || (s < start && e > end)) {
        done = true;
        continue;
      }
      
      // New region and old region have the same start, or new region overlaps old region to the right. Must be done first as this.dataRanges[s] is altered, and is used in the second check.
      if (s === start || start <= e && end >= e) {
        this.dataRanges[s] = Math.max(e, end);
        done = true;
      }
      
      // New region and old region have the same end, or new region overlaps old region to the left
      if (e === end || start <= s && end >= s) {
        this.dataRanges[start] = Math.max(this.dataRanges[start] || 0, this.dataRanges[s]);
        toDelete[s] = true;
        done = true;
      }
    }
    
    for (i in toDelete) {
      delete this.dataRanges[i];
    }
    
    if (!done) {
      this.dataRanges[start] = end;
    }
  },
  
  checkDataRange: function (start, end) {
    if (!this.url) {
      return { start: 1, end: this.browser.chromosomeSize };
    }
    
    for (var i in this.dataRanges) {
      if (Math.max(start, 1) >= parseInt(i, 10) && Math.min(end, this.browser.chromosomeSize) <= this.dataRanges[i]) {
        return { start: i, end: this.dataRanges[i] };
      }
    }
    
    return false;
  },
  
  scaleFeatures: function (features, scale) {
    var add = Math.max(scale, 1);
    var feature;
    
    for (var i = 0; i < features.length; i++) {
      feature = features[i];
      
      if (!feature.position) {
        feature.position = {};
      }

      if (!feature.position[scale]) {
        feature.position[scale] = {
          start  : feature.start * scale,
          width  : (feature.end - feature.start) * scale + add,
          height : feature.height || this.featureHeight
        };
        
        if (feature.position[scale].width < this.minScaledWidth) {
          feature.position[scale].width = this.minScaledWidth;
        }
      }
    }
    
    return features;
  },
  
  positionFeatures: function (features, params) {
    for (var i = 0; i < features.length; i++) {
      this.positionFeature(features[i], params);
    }
    
    params.width         = Math.ceil(params.width);
    params.height        = Math.ceil(params.height);
    params.featureHeight = Math.max(Math.ceil(params.featureHeight), this.fixedHeight ? Math.max(this.height, this.minLabelHeight) : 0);
    params.labelHeight   = Math.ceil(params.labelHeight);
    
    return features;
  },
  
  positionFeature: function (feature, params) {
    var scale = params.scale;
    
    feature.position[scale].X = feature.position[scale].start - params.scaledStart; // FIXME: always have to reposition for X, in case a feature appears in 2 images. Pass scaledStart around instead?
    
    if (!feature.position[scale].positioned) {
      feature.position[scale].H = (feature.position[scale].height + this.bumpSpacing);
      feature.position[scale].W = feature.position[scale].width + (feature.spacing || this.featureSpacing);
      feature.position[scale].Y = (feature.y ? feature.y * (feature.position[scale].H + this.bumpSpacing) : 0);
      
      if (feature.label) {
        if (typeof feature.label === 'string') {
          feature.label = feature.label.split('\n');
        }
        
        var context = this.context;
        
        feature.labelHeight = feature.labelHeight || (this.fontHeight + 2) * feature.label.length;
        feature.labelWidth  = feature.labelWidth  || Math.max.apply(Math, $.map(feature.label, function (l) { return Math.ceil(context.measureText(l).width); })) + 1;
        
        if (this.labels === true) {
          feature.position[scale].H += feature.labelHeight;
          feature.position[scale].W  = Math.max(feature.labelWidth, feature.position[scale].W);
        } else if (this.labels === 'separate' && !feature.position[scale].label) {
          feature.position[scale].label = {
            x: feature.position[scale].start,
            y: feature.position[scale].Y,
            w: feature.labelWidth,
            h: feature.labelHeight
          };
        }
      }
      
      var bounds = {
        x: feature.position[scale].start,
        y: feature.position[scale].Y,
        w: feature.position[scale].W,
        h: feature.position[scale].H
      };
      
      if (this.bump === true) {
        this.bumpFeature(bounds, feature, scale, this.scaleSettings[scale].featurePositions);
      }
      
      this.scaleSettings[scale].featurePositions.insert(bounds, feature);
      
      feature.position[scale].bottom = feature.position[scale].Y + feature.position[scale].H + this.spacing;
      
      if (feature.position[scale].label) {
        var f = $.extend(true, {}, feature); // FIXME: hack to avoid changing feature.position[scale].Y in bumpFeature
        
        this.bumpFeature(feature.position[scale].label, f, scale, this.scaleSettings[scale].labelPositions);
        
        f.position[scale].label        = feature.position[scale].label;
        f.position[scale].label.bottom = f.position[scale].label.y + f.position[scale].label.h + this.spacing;
        
        feature = f;
        
        this.scaleSettings[scale].labelPositions.insert(feature.position[scale].label, feature);
        
        params.labelHeight = Math.max(params.labelHeight, feature.position[scale].label.bottom);
      }
      
      feature.position[scale].positioned = true;
    }
    
    params.featureHeight = Math.max(params.featureHeight, feature.position[scale].bottom);
    params.height        = Math.max(params.height, params.featureHeight + params.labelHeight);
  },
  
  bumpFeature: function (bounds, feature, scale, tree) {
    var depth = 0;
    var bump;
    
    do {
      if (this.depth && ++depth >= this.depth) {
        if ($.grep(this.scaleSettings[scale].featurePositions.search(bounds), function (f) { return f.position[scale].visible !== false; }).length) {
          feature.position[scale].visible = false;
        }
        
        break;
      }
      
      bump = false;
      
      if ((tree.search(bounds)[0] || feature).id !== feature.id) {
        bounds.y += bounds.h;
        bump      = true;
      }
    } while (bump);
    
    feature.position[scale].Y = bounds.y;
  },
  
  render: function (features, img) {
    var params         = img.data();
        features       = this.positionFeatures(this.scaleFeatures(features, params.scale), params); // positionFeatures alters params.featureHeight, so this must happen before the canvases are created
    var featureCanvas  = $('<canvas>').attr({ width: params.width, height: params.featureHeight || 1 });
    var labelCanvas    = this.labels === 'separate' && params.labelHeight ? featureCanvas.clone().attr('height', params.labelHeight) : featureCanvas;
    var featureContext = featureCanvas[0].getContext('2d');
    var labelContext   = labelCanvas[0].getContext('2d');
    
    featureContext.font = labelContext.font = this.font;
    
    switch (this.labels) {
      case false     : break;
      case 'overlay' : labelContext.textAlign = 'center'; labelContext.textBaseline = 'middle'; break;
      default        : labelContext.textAlign = 'left';   labelContext.textBaseline = 'top';    break;
    }
    
    this.draw(features, featureContext, labelContext, params.scale);
    
    img.attr('src', featureCanvas[0].toDataURL());
    
    if (labelContext !== featureContext) {
      img.clone(true).attr({ 'class': 'labels', src: labelCanvas[0].toDataURL() }).insertAfter(img);
    }
    
    this.checkHeight();
    
    featureCanvas = labelCanvas = img = null;
  },
  
  renderBackground: function (features, img, height) {
    var canvas = $('<canvas>').attr({ width: this.width, height: height || 1 })[0];
    this.drawBackground(features, canvas.getContext('2d'), img.data());
    img.attr('src', canvas.toDataURL());
    canvas = img = null;
  },
  
  draw: function (features, featureContext, labelContext, scale) {
    var feature;
    
    for (var i = 0; i < features.length; i++) {
      feature = features[i];
      
      if (feature.position[scale].visible !== false) {
        // TODO: extend with feature.position[scale], rationalize keys
        this.drawFeature($.extend({}, feature, {
          x             : feature.position[scale].X,
          y             : feature.position[scale].Y,
          width         : feature.position[scale].width,
          height        : feature.position[scale].height,
          labelPosition : feature.position[scale].label
        }), featureContext, labelContext, scale);
      }
    }
  },
  
  drawFeature: function (feature, featureContext, labelContext, scale) {
    if (feature.x < 0 || feature.x + feature.width > this.width) {
      this.truncateForDrawing(feature);
    }
    
    if (feature.color !== false) {
      featureContext.fillStyle = feature.color || this.color;
      featureContext.fillRect(feature.x, feature.y, feature.width, feature.height);
    }
    
    if (this.labels && feature.label) {
      var labelStart = feature.untruncated ? feature.untruncated.x : feature.x;
      
      if (typeof feature.label === 'string') {
        feature.label = [ feature.label ];
      }
      
      if (labelStart > 0 || labelStart + feature.labelWidth < this.width) {
        labelContext.fillStyle = feature.labelColor || feature.color || this.color;
        
        if (this.labels === 'overlay') {
          var featureWidth = feature.untruncated ? feature.untruncated.width : feature.width;
          
          if (feature.labelWidth < featureWidth) {
            labelContext.fillText(feature.label.join(' '), labelStart + featureWidth / 2, feature.y + (feature.height + 1) / 2);
          }
        } else {
          for (var i = 0; i < feature.label.length; i++) {
            labelContext.fillText(feature.label[i], labelStart, i * (this.fontHeight + 2) + (feature.labelPosition ? feature.labelPosition.y : feature.y + feature.height + this.bumpSpacing + 1));
          }
        }
      }
    }
    
    if (feature.borderColor) {
      featureContext.strokeStyle = feature.borderColor;
      featureContext.strokeRect(feature.x, feature.y + 0.5, feature.width, feature.height);
    }
    
    if (feature.decorations) {
      this.decorateFeature(feature, featureContext, scale);
    }
  },
  
  // truncate features - make the features start at 1px outside the canvas to ensure no lines are drawn at the borders incorrectly
  truncateForDrawing: function (feature) {
    var start = Math.min(Math.max(feature.x, -1), this.width + 1);
    var width = feature.x - start + feature.width;

    if (width + start > this.width) {
      width = this.width - start + 1;
    }
    
    feature.untruncated = { x: feature.x, width: feature.width };
    feature.x           = start;
    feature.width       = Math.max(width, 0);
  },
  
  showError: function (error) {
    this.showMessage('error', error);
  },
  
  getQueryString: function (start, end) {
    var chr      = this.browser.chr;
    var data     = {};
    var template = false;
        start    = this.allData ? 1 : Math.max(start, 1);
        end      = this.allData ? this.browser.chromosomeSize : Math.min(end, this.browser.chromosomeSize);
    
    $.each(this.urlTemplate, function (key, val) {
      data[key] = val.replace(/__CHR__/, chr).replace(/__START__/, start).replace(/__END__/, end);
      template  = true;
    });
    
    if (!template) {
      data = { chr: chr, start: start, end: end };
    }
    
    return $.extend(data, this.urlParams);
  },
  
  formatLabel: function (label) {
    var str = label.toString();
    
    if (this.minorUnit < 1000) {
      return str.replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1,');
    } else {
      var power = Math.floor((str.length - 1) / 3);
      var unit  = this.labelUnits[power];
      
      label /= Math.pow(10, power * 3);
      
      return Math.floor(label) + (unit === 'bp' ? '' : '.' + (label.toString().split('.')[1] || '').concat('00').substring(0, 2)) + ' ' + unit;
    }
  },
  
  populateMenu: function (feature) {
    return feature;
  },
  
  show: function () {
    this.hidden = false;
    this.resize(this.initialHeight);
  },
  
  hide: function () {
    this.hidden = true;
    this.resize(0);
  },
  
  enable: function () {
    this.show();
    this.disabled = false;
    this.makeFirstImage();
  },
  
  disable: function () {
    this.hide();
    this.scrollContainer.css('left', 0);
    this.reset();
    this.disabled = true;
  },
  
  remove: function () {
    this.container.add(this.label).add(this.menus).remove();
    
    for (var key in this) {
      delete this[key];
    }
  },
  
  drawBackground      : $.noop,
  decorateFeature     : $.noop, // decoration for the features
  systemEventHandlers : {}
}, {
  on: function (events, handler) {
    $.each(events.split(' '), function () {
      if (typeof Genoverse.Track.prototype.systemEventHandlers[this] === 'undefined') {
        Genoverse.Track.prototype.systemEventHandlers[this] = [];
      }
      
      Genoverse.Track.prototype.systemEventHandlers[this].push(handler);
    });
  }
});

String.prototype.hashCode = function () {
  var hash = 0;
  var chr;
  
  if (!this.length) {
    return hash;
  }
  
  for (var i = 0; i < this.length; i++) {
    chr  = this.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash = hash & hash; // Convert to 32bit integer
  }
  
  return '' + hash;
};
