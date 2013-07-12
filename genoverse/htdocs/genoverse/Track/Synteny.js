// $Revision$

Genoverse.Track.Synteny = Genoverse.Track.extend({
  featureHeight : 5,
  bump          : true,
  allData       : true,
  
  init: function () {
    this.primaryTrack = this.id;
    this.dfds         = {};
    
    for (var i = 0; i < this.browser.tracks.length; i++) {
      if (this.browser.tracks[i].type === 'Synteny') {
        this.primaryTrack = this.browser.tracks[i].id;
        break;
      }
    }
    
    if (this.browser.tracksById[this.primaryTrack] && this.browser.tracksById[this.primaryTrack].colors) {
      this.colors = this.browser.tracksById[this.primaryTrack].colors;
    }
    
    this.base();
  },
  
  getData: function (start, end) {
    if (this.colors) {
      return this.base(start, end);
    }
    
    if (this.primaryTrack === this.id) {
      this.urlParams.colors = 1;
      
      return this.base(start, end).done(function () {
        for (var i = 0; i < this.browser.tracks.length; i++) {
          if (this.browser.tracks[i].type === 'Synteny' && this.browser.tracks[i].id !== this.id) {
            this.browser.tracks[i].colors = this.colors;
            this.browser.tracks[i].getData(start, end).done(function () { this.dfds[start + ':' + end].resolveWith(this); });
          }
        }
      });
    }
    
    return this.dfds[start + ':' + end] = $.Deferred();
  },
  
  parseData: function (data, start, end) {
    if (data.colors) {
      this.colors = data.colors;
      delete this.urlParams.colors;
    }
    
    for (var i = 0; i < data.features.length; i++) {
      data.features[i].color = data.features[i].labelColor = this.colors[data.features[i].colorId];
    }
    
    this.base(data, start, end);
  }
});
