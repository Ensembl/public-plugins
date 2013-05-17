// $Revision$

Genoverse.Track.Ensembl = {
  ensemblInit: function () {
    this.ensembl     = true;
    this.urlTemplate = { r: '__CHR__:__START__-__END__' };
    
    $.extend(this.urlParams, Ensembl.coreParams);
    
    delete this.urlParams.r;
  },
  
  updateHeightToggler: function () {
    this.hoverLabel.children('.height')[this.autoHeight ? 'addClass' : 'removeClass']('auto_height');
  },
  
  setRenderer: function (renderer, permanent) {
    if (permanent) {
      var li = $('div.config li.' + renderer, this.hoverLabel);
      
      if (!li.hasClass('current')) {
        $('div.config li.current', this.hoverLabel).removeClass('current').find('img.tick').insertAfter(li.addClass('current').find('img'))
      }
      
      li = null;
    }
    
    return this.base(renderer, permanent);
  },
  
  remove: function () {
    this.menus.each(function () { Ensembl.EventManager.trigger('destroyPanel', this.id); });
    
    if (this.id) {
      delete this.browser.tracksById[this.id];
    }
    
    this.base();
  },
  
  getData: function () {
    this.base.apply(this, arguments);
    
    if (this.fetchFeatures) {
      this.fetchFeatures.success(function (data) {
        if (data.dataRegion) {
          this.setDataRegion(data.dataRegion);
        }
        
        if (data.cacheURL) {
          $.ajax({ url: data.cacheURL });
        }
      });
    }
  },
  
  getQueryString: function () {
    return decodeURIComponent($.param(this.base.apply(this, arguments)));
  },
  
  populateMenu: function () {
    return false;
  },
  
  resize: function () {
    this.base.apply(this, arguments);
    
    if (this.resizer) {
      this.resizer[this.autoHeight ? 'hide' : 'show']();
    }
    
    if (arguments[1] === true) {
      var data = {
        image_config : this.browser.panel.imageConfig,
        track        : this.id,
        auto_height  : this.autoHeight ? 1 : 0
      };
      
      if (!this.autoHeight) {
        data.height = Math.max(this.height - this.spacing, 1);
      }
      
      $.ajax({
        url  : '/' + Ensembl.species + '/Genoverse/track_height',
        type : 'post',
        data : data
      });
    }
  }
};

Genoverse.Track.on('afterResize', function () {
  Ensembl.EventManager.trigger('resetImageOffset');
  this.browser.updateSelectorHeight();
});

Genoverse.Track.on('beforeParseFeatures', function (data, bounds) {
  if (data.highlights) {
    var i = data.features.length;
    
    while (i--) {
      if (data.highlights[data.features[i].id]) {
        data.features[i].highlight = data.highlights[data.features[i].id];
      }
    }
  }
});