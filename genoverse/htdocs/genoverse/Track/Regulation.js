// $Revision$

Genoverse.Track.RegulatoryFeature = Genoverse.Track.extend({
  bump: true,
  
  bumpFeature: function (bounds, feature, scale, tree) {
    bounds.x = feature.bumpStart * scale;
    bounds.w = (feature.bumpEnd - feature.bumpStart) * scale + Math.max(scale, 1);
    this.base(bounds, feature, scale, tree);
  },

  decorateFeature: function (feature, context, scale) {
    var position    = feature.position[scale];
    var startOffset = position.start - position.X;
    var mid         = position.height / 2;
    var decoration, end;
    
    for (var i = 0; i < feature.decorations.length; i++) {
      decoration       = feature.decorations[i];
      decoration.x     = decoration.start * scale - startOffset;
      decoration.width = (decoration.end - decoration.start) * scale + Math.max(scale, 1);
      
      context.fillStyle = decoration.color;
      
      if (decoration.x < 0 || decoration.x + decoration.width > this.width) {
        this.truncateForDrawing(decoration);
      }
      
      if (decoration.style === 'rect') {
        context.fillRect(decoration.x, position.Y, decoration.width, this.featureHeight);
      } else if (decoration.style === 'fg_ends') {
        end = decoration.end * scale - startOffset;
        
        if (decoration.x >= 0) {
          context.fillRect(decoration.x, position.Y, 1, position.height);
        }
        
        if (end <= this.width) {
          context.fillRect(end, position.Y, 1, position.height);
        }
        
        context.fillRect(decoration.x, position.Y + mid, decoration.width, 1);
      }
    }
  }
});

// Track type needed for legend
Genoverse.Track.SegmentationFeature = Genoverse.Track.extend({});
