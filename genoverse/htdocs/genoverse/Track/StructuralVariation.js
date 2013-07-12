// $Revision$

Genoverse.Track.StructuralVariation = Genoverse.Track.extend({ 
  height : 100,
  
  init: function () {
    this.decorationHeight = this.featureHeight - 1;
    this.breakpoints      = {};
    this.base();
  },
  
  setRenderer: function (renderer, permanent) {
    if (renderer === 'compact') {
      this.depth         = 1;
      this.bump          = false;
      this.featureHeight = 12;
    } else {
      this.depth         = false;
      this.bump          = true;
      this.featureHeight = 6;
    }
    
    if (this.urlParams.renderer !== renderer || permanent) {
      this.base(renderer, permanent);
    }
  },
  
  setScale: function () {
    this.dataBuffer.start = this.dataBuffer.end = 9 / this.browser.scale;
    this.base();
  },
  
  insertFeature: function (feature) {
    if (feature.breakpoint && !this.featuresById[feature.id]) {
      this.breakpoints[feature.featureId] = this.breakpoints[feature.featureId] || [];
      this.breakpoints[feature.featureId].push(feature);
      feature.breakpoint = this.breakpoints[feature.featureId].length;
    }
    
    this.base(feature);
  },
  
  positionFeature: function (feature, params) {
    var scale = params.scale;
    var width = feature.position[scale].width;
  
    if (!feature.adjusted) {
      for (var i = 0; i < feature.decorations.length; i++) {
        if (feature.decorations[i].style.match(/^bound_triangle_(\w+)$/)) {
          feature.position[scale].width += this.decorationHeight / 2;
        }
      }
      
      feature.adjusted = true;
    }
    
    this.base(feature, params);
    
    feature.position[scale].width = width;
  },
  
  bumpFeature: function (bounds, feature, scale, tree) {
    var i;
    
    if (feature.breakpoint) {
      if (bounds.y === 0 || feature.length > this.browser.length) {
        this.base(bounds, feature, scale, tree);
        
        for (i = 0; i < this.breakpoints[feature.featureId].length; i++) {
          this.breakpoints[feature.featureId][i].y = bounds.y / (bounds.h + this.bumpSpacing);
        }
      }
      
      return;
    }
    
    for (i = 0; i < feature.decorations.length; i++) {
      switch (feature.decorations[i].style) {
        case 'bound_triangle_left'  : bounds.x -= this.decorationHeight / 2; break;
        case 'bound_triangle_right' : bounds.w += this.decorationHeight / 2; break;
        default                     : break;
      }
    }
    
    this.base(bounds, feature, scale, tree);
  },
  
  drawFeature: function (feature, featureContext, labelContext, scale) {
    if (!feature.breakpoint) {
      return this.base(feature, featureContext, labelContext, scale);
    }
    
    featureContext.fillStyle   = feature.color;
    featureContext.strokeStyle = feature.border;
    
    var position    = feature.position[scale];
    var breakpointH = this.decorationHeight * 2;
    var x           = position.X;
    var y           = position.Y + 0.5;
    
    featureContext.beginPath();
    featureContext.moveTo(x - 0.5, y);
    featureContext.lineTo(x + 4.5, y);
    featureContext.lineTo(x + 2.5, y + breakpointH / 3);
    featureContext.lineTo(x + 5.5, y + breakpointH / 3);
    featureContext.lineTo(x,       y + breakpointH);
    featureContext.lineTo(x + 0.5, y + breakpointH * 2 / 3 - 1);
    featureContext.lineTo(x - 3.5, y + breakpointH * 2 / 3 - 1);
    featureContext.closePath();
    featureContext.fill();
    featureContext.stroke();
  },
  
  decorateFeature: function (feature, context, scale) {
    var i           = feature.decorations.length;
    var h           = this.decorationHeight;
    var mid         = h / 2;
    var position    = feature.position[scale];
    var startOffset = position.start - position.X;
    var spacing     = feature.spacing || this.featureSpacing;
    var decoration, x, x2, y, triangle, dir;
    
    while (i--) {
      decoration = feature.decorations[i];
      triangle   = decoration.style.match(/^bound_triangle_(\w+)$/);
      
      context.fillStyle   = decoration.color;
      context.strokeStyle = decoration.border;
      
      if (triangle) {
        dir = !!decoration.out === (triangle[1] === 'left');
        x   = Math.floor((dir ? position.X + position.width + spacing - Math.max(scale, 1) : position.X) + (dir ? 1 : -1) * (decoration.out ? mid : 0)) + 0.5;
        x2  = x + ((triangle[1] === 'left' ? -1 : 1) * mid);
        y   = position.Y + 0.5;
        
        if (Math.max(x, x2) > 0 && Math.min(x, x2) < this.width) {
          context.beginPath();
          context.moveTo(x, y);
          context.lineTo(x2, y + mid);
          context.lineTo(x, y + h);
          context.closePath();
          context.fill();
          context.stroke();
        }
      } else if (decoration.style === 'rect') {
        decoration.x     = decoration.start * scale - startOffset;
        decoration.width = (decoration.end - decoration.start) * scale + Math.max(scale, 1);
        
        if (decoration.x < 0 || decoration.x + decoration.width > this.width) {
          this.truncateForDrawing(decoration);
        }
        
        context.fillRect(decoration.x, position.Y, decoration.width, this.featureHeight);
      }
    }
  }
});
