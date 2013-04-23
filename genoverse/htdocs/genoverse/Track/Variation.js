// $Revision$

Genoverse.Track.Variation = Genoverse.Track.extend({
  config: {
    separateLabels : false,
    bump           : true
  },
  
  init: function () {
    this.base();
    this.setRenderer(this.renderer, true);
  },
  
  setRenderer: function (renderer, permanent) {
    if (renderer === 'compact') {
      this.depth = 1;
    } else if (renderer.match(/labels/)) {
      delete this.depth;
    } else {
      this.depth = 20;
    }
    
    this.maxLabelRegion = renderer === 'labels' ? 1e4 : -1;
    
    if (this.urlParams.renderer !== renderer || permanent) {
      this.base(renderer, permanent);
    }
  },
  
  getRenderer: function () {
    if (this.browser.length > 2e5 && this.renderer === 'normal') {
      this.renderer = 'compact';
    }
    
    return this.renderer;
  },
  
  scaleFeatures: function (features) {
    var i = features.length;
    var j;
    
    while (i--) {
      for (j = 0; j < features[i].decorations.length; j++) {
        if (features[i].decorations[j].style === 'label') {
          features[i].labelWidth = Math.ceil(this.context.measureText(features[i].decorations[j].label).width) + 1;
          break;
        }
      }
      
      features[i].scaledStart = features[i].start * this.scale;
      features[i].scaledEnd   = features[i].end   * this.scale;
    }
    
    return features;
  },
  
  positionFeatures: function (features, startOffset, imageWidth) {
    var feature, start, end, x, y, width, originalWidth, featureHeight, featureSpacing, bounds, bump, bumpFeature, depth, j, k, labelStart, labelWidth;
    var showLabels   = this.maxLabelRegion > this.browser.length;
    var height       = 0;
    var labelsHeight = 0;
    var scale        = this.scale > 1 ? this.scale : 1;
    var scaleKey     = this.scale;
    var seen         = {};
    var draw         = { fill: {}, border: {}, label: {}, highlight: {}, labelHighlight: {} };
    
    for (var i = 0; i < features.length; i++) {
      feature = features[i];
      
      if (seen[feature.id]) {
        continue;
      }
      
      seen[feature.id] = 1;
      
      start          = feature.scaledStart - startOffset;
      end            = feature.scaledEnd   - startOffset;
      bounds         = feature.bounds[scaleKey];
      labelStart     = start;
      labelWidth     = feature.label ? Math.ceil(this.context.measureText(feature.label).width) + 1 : 0;
      featureHeight  = feature.height  || this.featureHeight;
      featureSpacing = feature.spacing || this.featureSpacing;
      
      if (bounds) {
        width = bounds[0].w   - featureSpacing;
      } else {
        width = end - start + scale;
        
        if (end < start) {
          width = 1;
        } else if (width < scale) {
          width = scale;
        }
        
        x      = feature.scaledStart;
        y      = feature.y ? feature.y * (featureHeight + this.bumpSpacing) : 0;
        bounds = [{ x: x, y: y, w: width + featureSpacing, h: featureHeight + this.bumpSpacing }];
        
        if (showLabels) {
          bounds.push({ x: bounds[0].x + bounds[0].w - featureSpacing, y: bounds[0].y, w: feature.labelWidth + featureSpacing, h: bounds[0].h });
        }
        
        if (this.bump) {
          depth = 0;
          
          do {
            if (this.depth && ++depth >= this.depth) {
              if ($.grep(this.featurePositions.search(bounds[0]), function (f) { return f.visible[scaleKey] !== false; }).length) {
                feature.visible[scaleKey] = false;
              }
              
              break;
            }
          
            bump = false;
            j    = bounds.length;
            
            while (j--) {
              bumpFeature = this.featurePositions.search(bounds[j])[0] || feature;
              
              if (bumpFeature.id !== feature.id) {
                k = bounds.length;
                
                while (k--) {
                  bounds[k].y += bumpFeature.bounds[scaleKey][j].h; // bump both feature and label by the height of the current bounds
                }
                
                bump = true;
              }
            }
          } while (bump);
        }
        
        this.featurePositions.insert(bounds[0], feature);
        
        if (showLabels) {
          this.featurePositions.insert(bounds[1], feature);
        }

        feature.bounds[scaleKey] = bounds;
      }
      
      if (feature.visible[scaleKey] === false) {
        continue;
      }
      
      if (!draw.fill[feature.color]) {
        draw.fill[feature.color] = [];
        
        if (feature.order) {
          this.colorOrder[feature.order] = feature.color;
        }
      }
      
      if (feature.borderColor && !draw.border[feature.borderColor]) {
        draw.border[feature.borderColor] = [];
      }
      
      if (feature.labelColor && !draw.label[feature.labelColor]) {
        draw.label[feature.labelColor] = [];
      }
      
      originalWidth = width;
      
      // truncate features - make the features start at 1px outside the canvas to ensure no lines are drawn at the borders incorrectly
      if (start < end && (start < 0 || end > imageWidth)) {
        start = Math.max(start, -1);
        end   = Math.min(end, imageWidth + 1);
        width = end - start + scale;
      }
      
      if (width > 0) {
        draw.fill[feature.color].push([ 'fillRect', [ start, bounds[0].y, width, featureHeight ] ]);
        
        if (feature.borderColor) {
          draw.border[feature.borderColor].push([ 'strokeRect', [ start, bounds[0].y + 0.5, width, featureHeight ] ]);
        }
      }
      
      if (feature.label && labelWidth < originalWidth - 1) { // Don't show overlaid labels on features which aren't wider than the label
        draw.label[feature.labelColor].push([ 'fillText', [ feature.label, labelStart + (originalWidth - labelWidth) / 2, bounds[0].y + bounds[0].h / 2 ] ]);
      }
      
      feature.bottom[scaleKey] = bounds[0].y + bounds[0].h + this.spacing;
      
      if (feature.decorations) {
        for (j = 0; j < feature.decorations.length; j++) {
          if (!this.decorations[feature.decorations[j].color]) {
            this.decorations[feature.decorations[j].color] = [];
          }
          
          this.decorations[feature.decorations[j].color].push([ feature, feature.decorations[j] ]);
        }
      }
      
      if (feature.highlight) {
        if (!draw.highlight[feature.highlight]) {
          draw.highlight[feature.highlight] = [];
        }
        
        if (bounds[1]) {
          if (this.separateLabels) {
            if (!draw.labelHighlight[feature.highlight]) {
              draw.labelHighlight[feature.highlight] = [];
            }
            
            draw.labelHighlight[feature.highlight].push([ 'fillRect', [ start, bounds[1].y, labelWidth, this.fontHeight ] ]);
          } else {
            draw.highlight[feature.highlight].push([ 'fillRect', [ start - 1, bounds[0].y - 1, Math.max(labelWidth, width + 1) + 1, bounds[0].h + bounds[1].h ] ]);
          }
        } else {
          draw.highlight[feature.highlight].push([ 'fillRect', [ start - 1, bounds[0].y - 1, width + 2, bounds[0].h + 1] ]);
        }
      }
      
      height = Math.max(feature.bottom[scaleKey], height);
    }
    
    this.featuresHeight      = Math.max(height, this.fixedHeight ? Math.max(this.height, this.minLabelHeight) : 0);
    this.labelsHeight        = labelsHeight;
    this.fullHeight          = Math.max(height, this.initialHeight) + labelsHeight;
    this.heights.max         = Math.max(this.fullHeight, this.heights.max);
    this.heights.maxFeatures = Math.max(height, this.heights.maxFeatures);
    
    return draw;
  },
  
  // Add triangles at the bottom of inserts
  decorateFeatures: function (image) {
    var startOffset = image.scaledStart;
    var showLabels  = this.maxLabelRegion > this.browser.length;
    var color, i, start, bounds;
    
    for (var color in this.decorations) {
      this.context.fillStyle = color;
      
      i = this.decorations[color].length;
      
      while (i--) {
        if (this.decorations[color][i][1].style === 'insertion') {
          bounds = this.decorations[color][i][0].bounds[this.scale][0];
          start  = this.decorations[color][i][0].scaledStart - startOffset;
          
          this.context.beginPath();
          this.context.moveTo(start - 3, bounds.y + this.featureHeight + 1);
          this.context.lineTo(start,     bounds.y + this.featureHeight - 3);
          this.context.lineTo(start + 3, bounds.y + this.featureHeight + 1);
          this.context.fill();
        } else if (showLabels && this.decorations[color][i][1].style === 'label') {
          bounds = this.decorations[color][i][0].bounds[this.scale][1];
          this.context.fillText(this.decorations[color][i][1].label, bounds.x - startOffset, bounds.y + (this.featureHeight - this.fontHeight) / 2);
        }
      }
    }
  }
});
