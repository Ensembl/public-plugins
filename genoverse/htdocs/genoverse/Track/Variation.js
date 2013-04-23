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
  
  // Add triangles at the bottom of inserts
  decorateFeatures: function (image) {
    var startOffset = image.scaledStart;
    var showLabels  = this.scale > 1;
    var color, i, start, bounds, label, labelWidth;
    
    for (var color in this.decorations) {
      this.context.fillStyle = color;
      
      i = this.decorations[color].length;
      
      while (i--) {
        start  = this.decorations[color][i][0].scaledStart - startOffset;
        bounds = this.decorations[color][i][0].bounds[this.scale][0];
        
        if (this.decorations[color][i][1].style === 'insertion') {
          this.context.beginPath();
          this.context.moveTo(start - 3, bounds.y + this.featureHeight + 1);
          this.context.lineTo(start,     bounds.y + this.featureHeight - 3);
          this.context.lineTo(start + 3, bounds.y + this.featureHeight + 1);
          this.context.fill();
        } else if (showLabels && this.decorations[color][i][1].style === 'label') {
          label      = this.decorations[color][i][1].letter;
          labelWidth = this.context.measureText(label).width;
          
          if (bounds.w > labelWidth + 1) {
            this.context.fillText(label, start + (bounds.w - labelWidth - 1) / 2, bounds.y + (this.featureHeight - this.fontHeight) / 2);
          }          
        }
      }
    }
  }
});
