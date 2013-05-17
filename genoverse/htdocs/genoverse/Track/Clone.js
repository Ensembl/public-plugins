// $Revision$

Genoverse.Track.Clone = Genoverse.Track.extend({
  config: {
    bump         : true,
    labelOverlay : true
  },
  
  decorateFeatures: function (image) {
    var c           = this.colorOrder.length;
    var startOffset = image.scaledStart;
    var color, decoration, feature, i, x, y;
    
    for (var color in this.decorations) {
      this.context.fillStyle   = color;
      this.context.strokeStyle = color;
      
      i = this.decorations[color].length;
      
      while (i--) {
        feature    = this.decorations[color][i][0];
        decoration = this.decorations[color][i][1];
        
        if (decoration.style === 'left-triangle') {
          x = Math.round(feature.scaledStart - startOffset) + 0.5;
          y = feature.bounds[this.scale][0].y + 0.5;
          
          this.context.beginPath();
          this.context.moveTo(x, y);
          this.context.lineTo(x + Math.min(feature.scaledEnd - feature.scaledStart - 1, 3), y);
          this.context.lineTo(x, y + 3);
          this.context.closePath();
          this.context.fill();
          this.context.stroke();
        } else if (decoration.style === 'rect') {
          this.context.fillRect(decoration.start * this.scale - startOffset, feature.bounds[this.scale][0].y, Math.max((decoration.end - decoration.start + 1) * this.scale, 1), this.featureHeight);
        }
      }
    }
  }
});