// $Revision$

Genoverse.Track.Error = Genoverse.Track.extend({
  config: {
    color   : '#FF0000',
    spacing : 0,
    inherit : [ 'Static' ]
  },
  
  constructor: function (config) {
    this.base(config);
    this.makeImage = $.noop;
    
    this.container.hide();
    this.label.hide();
    
    this.height = this.featuresHeight = this.fontHeight + 2;
  },
  
  resize: $.noop,
  
  positionFeatures: function () {
    var width = this.context.measureText(this.message).width;
    var fill  = {};
    
    fill[this.color] = [[ 'fillText', [ this.message, (this.width - width) / 2, 0 ] ]];
    
    return { fill: fill };
  },
  
  draw: function (trackImg, message) {
    this.message = message || 'Unknown error';

    this.image.makeImage();
    this.base(this.image);
    this.image.container.children().addClass('static').appendTo(trackImg.container || trackImg).css({ marginTop: -this.height / 2, marginLeft: this.width - this.browser.left });
  }
});
