// $Revision$

Genoverse.Track.StructuralVariation = Genoverse.Track.extend({ 
  config: {
    height : 100,
    bump   : true
  },
  
  positionFeatures: function (features, startOffset, imageWidth) {
    var scale = this.browser.scale;
    
    if (scale < 1) {
      var threshold = 1 / scale;
          features  = $.grep(features, function (f) { return f.end - f.start > threshold || f.breakpoint; }).sort(function (a, b) { return a.start - b.start; });
    }
    
    return this.base(features, startOffset, imageWidth);
  },
  
  decorateFeatures: function (image) {
    var h           = this.featureHeight - 1;
    var mid         = h / 2;
    var breakpointH = h * 2;
    var startOffset = image.scaledStart
    var color, tag, feature, i, x, y, triangle, dir;
    
    for (var color in this.decorations) {
      this.context.fillStyle = color;
      
      if (this.context.strokeStyle !== this.decorations[color][0][1].border) {
        this.context.strokeStyle = this.decorations[color][0][1].border;
      }
      
      i = this.decorations[color].length;
      
      while (i--) {
        feature    = this.decorations[color][i][0];
        decoration = this.decorations[color][i][1];
        triangle   = decoration.style.match(/^bound_triangle_(\w+)$/);
        
        if (triangle) {
          dir = !!decoration.out === (triangle[1] === 'left');
          x  = (dir ? feature.scaledEnd : feature.scaledStart) - startOffset + (dir ? 1 : -1) * (decoration.out ? mid : 0);
          y  = feature.bounds[this.scale][0].y + 0.5;
          
          this.context.beginPath();
          this.context.moveTo(x, y);
          this.context.lineTo(x + ((triangle[1] === 'left' ? -1 : 1) * mid), y + mid);
          this.context.lineTo(x, y + h);
          this.context.closePath();
          this.context.fill();
          this.context.stroke();
        } else if (decoration.style === 'somatic_breakpoint') {
          x = decoration.start * this.scale - startOffset;
          y = feature.bounds[this.scale][0].y + 0.5;
          
          this.context.beginPath();
          this.context.moveTo(x - 0.5, y);
          this.context.lineTo(x + 4.5, y);
          this.context.lineTo(x + 2.5, y + breakpointH / 3);
          this.context.lineTo(x + 5.5, y + breakpointH / 3);
          this.context.lineTo(x,       y + breakpointH);
          this.context.lineTo(x + 0.5, y + breakpointH * 2 / 3 - 1);
          this.context.lineTo(x - 3.5, y + breakpointH * 2 / 3 - 1);
          this.context.closePath();
          this.context.fill();
          this.context.stroke();
          
          feature.bottom[this.scale] = y + breakpointH + this.bumpSpacing;
          
          this.featurePositions.insert({ x: x + startOffset - 3.5, y: y, w: 9, h: breakpointH }, $.extend({}, feature, { breakpoint: true, sort: -feature.sort })); // make the whole thing clickable for a menu
        } else if (decoration.style === 'rect') {
          this.context.fillRect(decoration.start * this.scale - startOffset, feature.bounds[this.scale][0].y, Math.max((decoration.end - decoration.start + 1) * this.scale, 1), this.featureHeight);
        }
      }
    }
  },
  
  click: function (e) {
    var x = e.pageX - this.container.parent().offset().left + this.browser.scaledStart;
    var y = e.pageY - $(e.target).offset().top;
    var f = this.featurePositions.search({ x: x, y: y, w: 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; })[0];
    
    if (f && f.breakpoint !== 1) {
      this.browser.makeMenu(this, f, { left: e.pageX, top: e.pageY });
    }
  }
});
