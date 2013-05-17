// $Revision$

Genoverse.Track.Synteny = Genoverse.Track.extend({
  config: {
    featureHeight : 5,
    bump          : true,
    forceLabels   : true,
    allData       : true
  },
  
  parseFeatures: function (data, bounds) {
    data.features = data[this.urlParams.id];
    
    var i = data.features.length;
    
    if (this.url) {
      var j = this.browser.tracks.length;
      
      this.colors = data.colors;
      
      while (j--) {
        if (this.browser.tracks[j].type === 'Synteny' && this.browser.tracks[j] !== this) {
          this.browser.tracks[j].colors = this.colors;
          this.browser.tracks[j].parseFeatures($.extend(true, {}, data), bounds);
        }
      }
    }
    
    while (i--) {
      data.features[i].color = data.features[i].labelColor = this.colors[data.features[i].colorId];
    }
    
    return this.base(data, bounds);
  },
  
  makeImage: function () {
    var args = arguments;
    
    if (this.url) {
      var track       = this;
      var deferred    = $.Deferred();
      var otherTracks = $.grep(this.browser.tracks, function (t) { if (t.type === 'Synteny' && t !== track) { t.url = false; return true; } });
      
      $.when(this.base.apply(this, args)).done(function (dfd) {
        $.when.apply($, $.map(otherTracks, function (t) { return t.makeImage.apply(t, args); })).done(function () {
          var i = arguments.length;
          var args = { target: [ dfd.target ], img: [ dfd.img ] };
          
          while (i--) {
            args.target.push(arguments[i].target);
            args.img.push(arguments[i].img);
          }
          
          deferred.resolve(args);
        });
      });
      
      return deferred;
    } else if (this.colors) {
      return this.base.apply(this, args); 
    }
  }
});