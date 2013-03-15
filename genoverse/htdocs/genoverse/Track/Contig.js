// $Revision$

Genoverse.Track.Contig = Genoverse.Track.extend({
  config: {
    borderColor  : '#000000',
    labelOverlay : true
  },
  
  constructor: function (config) {
    this.base(config);
    
    this.colors = {};
    this.urlParams.colors = 1;
  },
  
  parseFeatures: function (data, bounds) {
    var i = data.features.length;
    
    if (data.colors) {
      this.colors = data.colors;
      delete this.urlParams.colors;
    }
    
    while (i--) {
      data.features[i].color = this.colors[data.features[i].id];
    }
    
    return this.base(data, bounds);
  },
  
  beforeDraw: function (image) {
    this.context.fillStyle = this.borderColor;
    
    this.context.fillRect(0, 0,                      image.width, 1);
    this.context.fillRect(0, this.featureHeight - 1, image.width, 1);
  }
});