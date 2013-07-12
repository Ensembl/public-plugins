// $Revision$

Genoverse.Track.Stranded = {
  inheritedConstructor: function (config) {
    if (typeof this._makeImage === 'function') {
      return;
    }
    
    this.base(config);
    
    if (this.strand === -1) {
      this.url        = 0; // falsy value but not actually false, so fails on === false checks (allows reset to work properly on renderer change)
      this._makeImage = this.makeReverseImage || this.makeImage;
      this.makeImage  = $.noop;
    } else {
      this.strand       = 1;
      this._makeImage   = this.makeImage;
      this.makeImage    = this.makeForwardImage;
      this.reverseTrack = this.browser.setTracks([ $.extend({}, config, { strand: -1, forwardTrack: this }) ], this.browser.tracks.length)[0];
    }
    
    if (!this.featureStrand) {
      this.featureStrand = this.strand;
    }
    
    this.urlParams.strand = this.featureStrand;
  },
  
  init: function () {
    this.base();
    
    if (this.strand === 1) {
      this.reverseTrack.features = this.features;
      
      if (this.renderer) {
        this.reverseTrack.featuresByRenderer   = this.featuresByRenderer;
        this.reverseTrack.featuresByIdRenderer = this.featuresByIdRenderer;
      }
    } else {
      this.features = this.forwardTrack.features;
      
      if (this.renderer) {
        this.featuresByRenderer   = this.forwardTrack.featuresByRenderer;
        this.featuresByIdRenderer = this.forwardTrack.featuresByIdRenderer;
      }
    }
  },
  
  setRenderer: function (renderer, permanent) {
    if (this.urlParams.renderer !== renderer) {
      var otherTrack = this.forwardTrack || this.reverseTrack;
      
      this.urlParams.renderer = otherTrack.urlParams.renderer = renderer;
      this.dataRanges         = otherTrack.dataRanges         = {};
      this.features           = otherTrack.features           = (this.featuresByRenderer[renderer]   = this.featuresByRenderer[renderer]   || new RTree());
      this.featuresById       = otherTrack.featuresById       = (this.featuresByIdRenderer[renderer] = this.featuresByIdRenderer[renderer] || {});
    }
    
    this.base(renderer, permanent);
  },
  
  findFeatures: function () {
    var strand = this.featureStrand;
    return $.grep(this.base.apply(this, arguments), function (feature) { return feature.strand === strand; });
  },
  
  makeForwardImage: function (params) {
    var rtn = this._makeImage(params);
    
    if (rtn && typeof rtn.done === 'function') {
      rtn.done(function () {
        this.reverseTrack._makeImage(params, rtn);
      });
    } else {
      this.reverseTrack._makeImage(params, rtn);
    }
  },
  
  remove: function () {
    if (!this.removing) {
      var track = this.forwardTrack || this.reverseTrack;
      
      track.removing = true;
      this.browser.removeTrack(track);
    }
    
    this.base();
  }
};
