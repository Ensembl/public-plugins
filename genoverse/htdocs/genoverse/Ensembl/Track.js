// $Revision$

Genoverse.Track.on('beforeSetURL', function () {
  this.urlTemplate = { r: '__CHR__:__START__-__END__' };
  $.extend(this.urlParams, Ensembl.coreParams);
  delete this.urlParams.r;
});

Genoverse.Track.on('beforeSetRenderer', function (renderer, permanent) {
  if (permanent && this.hoverLabel) {
    var li = $('div.config li.' + renderer, this.hoverLabel);
    
    if (!li.hasClass('current')) {
      $('div.config li.current', this.hoverLabel).removeClass('current').find('img.tick').insertAfter(li.addClass('current').find('img'));
    }
    
    li = null;
  }
});

Genoverse.Track.on('beforeRemove', function () {
  this.menus.each(function () { Ensembl.EventManager.trigger('destroyPanel', this.id); });
  
  if (this.id) {
    delete this.browser.tracksById[this.id];
  }
});

Genoverse.Track.on('afterResize', function () {
  if (arguments[1] === true) {
    var config = { auto_height: this.autoHeight ? 1 : 'undef' };
    
    if (!this.autoHeight) {
      config.user_height = Math.max(this.height - this.spacing, 1);
    }
    
    this.browser.saveConfig(config, this);
  }
  
  Ensembl.EventManager.trigger('resetImageOffset');
  this.browser.updateSelectorHeight();
});

Genoverse.Track.on('beforeParseData', function (data) {
  if (data.highlights) {
    var i = data.features.length;
    
    while (i--) {
      if (data.highlights[data.features[i].id]) {
        data.features[i].highlight = data.highlights[data.features[i].id];
      }
    }
  }
});

Genoverse.Track.on('beforeDrawFeature', function (feature, featureContext, labelContext, scale) {
  if (feature.highlight) {
    var position = feature.position[scale];
    
    featureContext.fillStyle = feature.highlight;
    featureContext.fillRect(position.X, position.Y, position.W, position.H);
    
    if (feature.labelPosition) {
      labelContext.fillStyle = feature.highlight;
      labelContext.fillRect(feature.x, feature.labelPosition.y, feature.labelPosition.w, feature.labelPosition.h);
    }
  }
});

Genoverse.Track.prototype._click = Genoverse.Track.prototype.click;
Genoverse.Track.prototype.click = function () {
  if (this.browser.panel.elLk.container.hasClass('ui-resizable-resizing')) {
    return false;
  }
  
  this._click.apply(this, arguments);
};

Genoverse.Track.prototype.populateMenu = function () {
  return false;
};

Genoverse.Track.prototype.updateHeightToggler = function () {
  this.hoverLabel.children('.height')[this.autoHeight ? 'addClass' : 'removeClass']('auto_height');
};

Genoverse.Track.prototype._getQueryString = Genoverse.Track.prototype.getQueryString;
Genoverse.Track.prototype.getQueryString  = function () {
  return decodeURIComponent($.param(this._getQueryString.apply(this, arguments)));
};

Genoverse.Track.prototype._getData = Genoverse.Track.prototype.getData;
Genoverse.Track.prototype.getData  = function () {
  return this._getData.apply(this, arguments).done(function (data) {
    if (data) {
      if (data.dataRange) {
        this.setDataRange(data.dataRange.start, data.dataRange.end);
      }
      
      if (data.cacheURL) {
        $.ajax({ url: data.cacheURL });
      }
    }
  });
};

Genoverse.Track.prototype._parseData = Genoverse.Track.prototype.parseData;
Genoverse.Track.prototype.parseData  = function (data, start, end) {
  if (data.error) {
    this.showError(data.error);
  } else {
    return this._parseData(data.features, start, end);
  }
};
