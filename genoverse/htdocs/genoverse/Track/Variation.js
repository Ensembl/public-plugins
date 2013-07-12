// $Revision$

Genoverse.Track.Variation = Genoverse.Track.extend({
  bump           : true,
  labels         : 'overlay',
  featureSpacing : 0,
  
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
  
  setScale: function () {
    this.dataBuffer.start = this.maxLabelRegion > this.browser.length ? this.browser.labelBuffer : 0;
    this.base();
  },
  
  positionFeature: function (feature, params) {
    var scale = params.scale;
    var width = feature.position[scale].width;
  
    if (!feature.nameWidth) {
      var context = this.context;
      
      for (var i = 0; i < feature.decorations.length; i++) {
        if (feature.decorations[i].style === 'label') {
          feature.nameWidth = Math.ceil(context.measureText(feature.decorations[i].label).width) + 1;
          break;
        }
      }
    }
    
    if (feature.nameWidth && this.maxLabelRegion > this.browser.length) {
      feature.position[scale].width += feature.nameWidth + this.featureSpacing;
    }
    
    this.base(feature, params);
    
    feature.position[scale].width = width;
  },
  
  // Add labels and triangles at the bottom of inserts
  decorateFeature: function (feature, context, scale) {
    var showLabels = this.maxLabelRegion > this.browser.length;
    var i          = feature.decorations.length;
    var position;
    
    while (i--) {
      context.fillStyle = feature.decorations[i].color;
      position          = feature.position[scale];
      
      if (feature.decorations[i].style === 'insertion') {
        context.beginPath();
        context.moveTo(position.X - 3, position.Y + this.featureHeight);
        context.lineTo(position.X,     position.Y + this.featureHeight - 4);
        context.lineTo(position.X + 3, position.Y + this.featureHeight);
        context.fill();
      } else if (showLabels && feature.decorations[i].style === 'label') {
        // Normal labels are overlaid, so textAlign = center and textBaseline = middle. Adjust position here, rather than setting and then resetting textAlign and textBaseline for each feature.
        context.fillText(feature.decorations[i].label, position.X + position.width + feature.nameWidth / 2 + this.featureSpacing, position.Y + this.featureHeight / 2);
      }
    }
  }
});
