// $Revision$

Genoverse.Track.Patch = Genoverse.Track.extend({
  config: {
    bump          : true,
    featureHeight : 3,
    bumpSpacing   : 0,
    forceLabels   : 'off',
    autoHeight    : true,
    allData       : true,
    backgrounds   : true,
    unsortable    : true,
    resizable     : false,
    featureStrand : 1,
    inherit       : [ 'Stranded' ]
  },
  
  init: function () {
    this.base();
    
    if (this.strand === -1) {
      this.bumpSpacing = 6;
    }
  },
  
  parseFeatures: function (data, bounds) {
    var i = data.features.length;
    
    while (i--) {
      data.features[i].backgroundBottom = {};
      data.features[i].boundsBottom     = {};
      
      if (!this.browser.backgrounds[data.features[i].background]) {
        this.browser.backgrounds[data.features[i].background] = [];
      }
      
      this.browser.backgrounds[data.features[i].background].push(data.features[i]);
    }
    
    this.backgrounds = data.features;
    
    return this.base(data, bounds);
  },
  
  positionFeatures: function (originalFeatures, startOffset, imageWidth) {
    if (this.strand === 1) {
      return this.base(originalFeatures.reverse(), startOffset, imageWidth);
    }
    
    var feature, start, end, width, bounds;
    var height   = this.initialHeight;
    var scale    = this.scale > 1 ? this.scale : 1;
    var seen     = {};
    var draw     = {};
    var features = $.extend(true, [], originalFeatures.sort(function (a, b) { return b.bottom[this.scale] - a.bottom[this.scale]; }));
    var bump     = this.featureHeight + this.fontHeight + this.bumpSpacing;
    
    for (var i = 0; i < features.length; i++) {
      if (seen[features[i].id]) {
        continue;
      }
      
      feature    = features[i];
      start      = feature.scaledStart - startOffset;
      end        = feature.scaledEnd   - startOffset;
      bounds     = feature.boundsBottom[this.scale];
      labelStart = start;
      width      = end - start + scale;
      
      if (width < 1) {
        width = scale;
      }
      
      seen[feature.id] = 1;
      
      if (!bounds) {
        bounds = [
          { x: feature.scaledStart, y: 0, w: width, h: this.featureHeight },
          { x: feature.scaledStart, y: this.featureHeight + 2, w: Math.ceil(this.context.measureText(feature.label).width) + 1, h: this.fontHeight + 2 }
        ];
        
        while (this.featurePositions.search(bounds[0]).length || this.featurePositions.search(bounds[1]).length) {
          bounds[0].y += bump;
          bounds[1].y += bump;
        }
        
        this.featurePositions.insert(bounds[0], feature);
        this.featurePositions.insert(bounds[1], feature);
        
        originalFeatures[i].boundsBottom[this.scale] = bounds;
      }
      
      originalFeatures[i].backgroundBottom[this.scale] = bounds[0].y;
      
      if (!draw[feature.color]) {
        draw[feature.color] = [];
      }
      
      if (!draw[feature.labelColor]) {
        draw[feature.labelColor] = [];
      }
      
      if (scale > 1 && start < end) {
        start = Math.max(start, -1);
        end   = Math.min(end, imageWidth + 1);
        width = end - start;
      }
      
      if (width > 0) {
        draw[feature.color].push([ 'fillRect', [ start, bounds[0].y, width, this.featureHeight ] ]);
      }
      
      draw[feature.labelColor].push([ 'fillText', [ feature.label, labelStart, bounds[1].y ] ]);
      
      feature.bottom[this.scale] = bounds[1].y + bounds[1].h + this.spacing;
      
      height = Math.max(feature.bottom[this.scale], height);
    }
    
    this.fullHeight     = height;
    this.featuresHeight = height;
    this.heights.max    = Math.max(height, this.heights.max);
    
    return { fill: draw };
  },
  
  drawBackgroundColor: function (image, height, scaledStart) {
    var backgrounds = this.browser.backgrounds;
    var forward     = this.strand === 1;
    var scale       = this.scale > 1 ? this.scale : 1;
    var i, start, end;
    
    if (height === 1) {
      return;
    }
    
    for (var c in backgrounds) {
      this.context.fillStyle = c;
      
      i = backgrounds[c].length;
      
      while (i--) {
        if (backgrounds[c][i].end >= image.start && backgrounds[c][i].start <= image.end) {
          start = Math.max(backgrounds[c][i].scaledStart - scaledStart, 0);
          end   = Math.min(backgrounds[c][i].scaledEnd   - scaledStart, image.width);
          
          if (forward) {
            this.context.fillRect(start, backgrounds[c][i].bottom[this.scale] - this.spacing, end - start + scale, height);
          } else {
            this.context.fillRect(start, 0, end - start + scale, backgrounds[c][i].backgroundBottom[this.scale]);
          }
        }
      }
    }
  }
});