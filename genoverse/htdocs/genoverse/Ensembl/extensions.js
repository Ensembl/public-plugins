// $Revision$

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({
  init: function () {
    this.base();
    
    if (this.el.parent().hasClass('image_panel') && this.panelType !== 'ImageMap') {
      this.imagePanel = true; // Panels which would be image maps if the region wasn't too large
    }
  },
  
  hashChange: function () {
    if (this.imagePanel && Ensembl.location.length > Ensembl._maxRegionLength) {
      return;
    }
    
    this.base.apply(this, arguments);
  }
});

Ensembl.Panel.ImageMap = Ensembl.Panel.ImageMap.extend({
  init: function () {
    var panel = this;
    
    this.base();
    
    this.el.css('position', 'relative');
    
    if (this.params.genoverseSwitch) {
      var isStatic = panel.params.updateURL.match('static');
      
      $('<div class="genoverse_switch"></div>').appendTo($('.image_toolbar', this.el)).click(function () {
        panel.params.updateURL = Ensembl.updateURL({ 'static': !isStatic }, panel.params.updateURL);
        panel.getContent();
        
        $.ajax({
          url  : '/' + Ensembl.species + '/Genoverse/switch_image',
          data : { 'static' : isStatic ? 0 : 1, id : panel.id }
        });
      }).helptip('Switch to ' + (isStatic ? 'scrollable' : 'static') + ' image');
    } else {
      this.elLk.container     = $('.image_container', this.el);
      this.elLk.overlay       = $('<div class="image_update_overlay">');
      this.elLk.updateButtons = $('<div class="image_update_buttons">');
      
      $('<input class="fbutton update" type="button" value="Update this image" /><input class="fbutton reset" type="button" value="Reset scrollable image" />').appendTo(this.elLk.updateButtons).on('click', function () {
        if ($(this).hasClass('update')) {
          panel.params.updateURL = Ensembl.urlFromHash(panel.params.updateURL);
          panel.getContent();
        } else {
          panel.resetGenoverse = true;
          Ensembl.EventManager.trigger('genoverseMove', panel.highlightRegions[0][0].region.range, true, true);
          panel.elLk.overlay.add(panel.elLk.updateButtons).detach();
        }
      });
    }
    
    Ensembl.EventManager.register('resetImageOffset', this, function () { delete this.imgOffset; })
  },
  
  hashChange: function () {
    if (this.resetGenoverse) {
      this.resetGenoverse = false;
    } else if (Ensembl.genoverseScroll && !this.params.genoverseSwitch) {
      var range = this.highlightRegions[0][0].region.range;
      
      if (range.start > Ensembl.location.start || range.end < Ensembl.location.end) {
        this.elLk.overlay.prependTo(this.el).css({ width: this.elLk.container.outerWidth(), height: this.elLk.container.outerHeight() });
        this.elLk.updateButtons.appendTo(this.el);
      }
    } else {
      this.base.apply(this, arguments);
    }
  }
});

Ensembl.Panel.Configurator = Ensembl.Panel.Configurator.extend({
  updateConfiguration: function () {
    if (this.params.reset && this.params.reset !== 'track_order') {
      Ensembl.EventManager.triggerSpecific('resetTrackHeights', this.component);
    }
    
    return this.base.apply(this, arguments);
  }
});

Ensembl.Panel.LocationNav = Ensembl.Panel.LocationNav.extend({
  init: function () {
    var panel = this;
    
    this.base();
    
    this.elLk.r = this.elLk.forms.children('input[name=r]');
    
    this.elLk.r.parent().on('submit', function () {
      return panel.formSubmit();
    }).find('a.go-button').off().on('click', function () {
      return panel.formSubmit();
    });
  },
  
  formSubmit: function () {
    var panel = this;
    var r     = this.elLk.r.val();
    
    if (r) {
      $.ajax({
        url: Ensembl.updateURL({ r: r, update_panel: 1 }, this.elLk.updateURL.val()),
        dataType: 'json',
        success: function (json) {
          if (json[2] !== Ensembl.coreParams.r) {
            return Ensembl.updateLocation(json[2]);
          }
          
          var sliderValue = json.shift();
          
          if (panel.elLk.slider.slider('value') !== sliderValue) {
            panel.elLk.slider.slider('option', 'force', true);
            panel.elLk.slider.slider('value', sliderValue);
            panel.elLk.slider.slider('option', 'force', false);
          }
          
          panel.elLk.updateURL.val(json.shift());
          panel.elLk.locationInput.val(json.shift());
          
          panel.elLk.navLinks.attr('href', function () {
            return this.href.replace(Ensembl.locationReplace, '$1$2' + json.shift() + '$3');
          });
        }
      });
    }
    
    return false;
  }
});
