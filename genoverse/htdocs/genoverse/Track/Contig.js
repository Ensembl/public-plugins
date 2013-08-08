// $Revision$

Genoverse.Track.Contig = Genoverse.Track.extend({
  borderColor : '#000000',
  labels      : 'overlay',
  fixedHeight : true,
  allData     : true,
  
  draw: function (features, featureContext, labelContext, scale) {
    featureContext.fillStyle = this.borderColor;
    featureContext.fillRect(0, 0,                      this.width, 1);
    featureContext.fillRect(0, this.defaultHeight - 1, this.width, 1);
    
    this.base(features, featureContext, labelContext, scale);
  }
});
