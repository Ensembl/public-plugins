// $Revision$

Genoverse.Track.Clone = Genoverse.Track.extend({
  bump   : true,
  labels : 'overlay',
  
  decorateFeature: function (feature, context, scale) {
    var i = feature.decorations.length;
    var decoration, x, y;
    
    while (i--) {
      decoration = feature.decorations[i];
      
      context.fillStyle = context.strokeStyle = decoration.color;
      
      if (decoration.style === 'left-triangle') {
        x = Math.round(feature.position[scale].X) + 0.5;
        y = feature.position[scale].Y + 0.5;
        
        context.beginPath();
        context.moveTo(x, y);
        context.lineTo(x + Math.min(feature.position[scale].W, 3), y);
        context.lineTo(x, y + 3);
        context.closePath();
        context.fill();
        context.stroke();
      } else if (decoration.style === 'rect') {
        context.fillRect(decoration.start * scale, feature.position[scale].Y, Math.max((decoration.end - decoration.start + 1) * scale, 1), this.featureHeight);
      }
    }
  }
});
