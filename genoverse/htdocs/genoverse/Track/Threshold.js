// $Revision$

Genoverse.Track.Threshold = Genoverse.Track.Error.extend({
  draw: function (trackImg) {
    return this.browser.length > this.track.threshold ? this.base(trackImg, 'This data is not displayed in regions greater than ' + this.formatLabel(this.track.threshold)) : false;
  }
});
