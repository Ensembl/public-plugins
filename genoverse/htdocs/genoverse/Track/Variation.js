// $Revision$

Genoverse.Track.Variation = Genoverse.Track.extend({
  config: {
    labelOverlay   : true,
    separateLabels : false,
    autoHeight     : 'force'
  },
  
  // Add triangles at the bottom of inserts
  decorateFeatures: function (image) {
    var c           = this.colorOrder.length;
    var startOffset = image.scaledStart;
    var color, i, start;
    
    while (c--) {
      color = this.colorOrder[c];
      
      if (color && this.decorations[color]) {
        this.context.fillStyle = color;
        
        i = this.decorations[color].length;
        
        while (i--) {
          if (this.decorations[color][i][1].style === 'insertion') {
            start = this.decorations[color][i][0].scaledStart - startOffset;
            
            this.context.beginPath();
            this.context.moveTo(start - 3, this.featureHeight + 1);
            this.context.lineTo(start,     this.featureHeight - 3);
            this.context.lineTo(start + 3, this.featureHeight + 1);
            this.context.fill();
          }
        }
      }
    }
  }
});
