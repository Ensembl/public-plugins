/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Genoverse.Track = Genoverse.Track.extend({
  constructor: function (config) {
    var mvc = [ 'Controller', 'Model', 'View', 'controller', 'model', 'view' ];
    
    for (var i = 0; i < 3; i++) {
      if (Genoverse.Track[mvc[i]][this.type] && !this[mvc[i + 3]]) {
        this[mvc[i + 3]] = Genoverse.Track[mvc[i]][this.type];
      }
    }
    
    this.base(config);

    if (this.legend === true) {
      this.addLegend();
    }
  },

  addLegend: function (config, constructor) {
    if (this.legendName) {
      config = $.extend(config, {name: this.legendName});
    }
    this.base(config, constructor);
  },

  setLengthMap: function () {
    this.base();
    
    var mv  = [ 'Model', 'View', 'model', 'view' ];
    var obj = {};
    
    for (var i = 0; i < 2; i++) {
      if (Genoverse.Track[mv[i]][this.type]) {
        obj[mv[i + 2]] = Genoverse.Track[mv[i]][this.type];
      }
    }
    
    if (obj.model || obj.view) {
      this.lengthMap.push([ 0, $.extend(true, {}, this, obj) ]);
    }
  },
  
  setRenderer: function (renderer) {
    if (this.renderer === renderer) {
      return;
    }
    
    this.renderer = this.constructor.prototype.renderer = renderer;
    
    delete this.model;
    delete this.view;
    
    this.setLengthMap();
    
    this.controller.resetImages();
    this.controller.setScale();
    this.controller.makeFirstImage();
    
    var hoverLabel = this.prop('hoverLabel');
    
    if (hoverLabel) {
      var li = $('div.config li.' + renderer, hoverLabel);
      
      if (!li.hasClass('current')) {
        $('div.config li.current', hoverLabel).removeClass('current').find('img.tick').insertAfter(li.addClass('current').find('img'));
      }
      
      li = null;
    }
    
    hoverLabel = null;
  },
  
  setDefaults: function () {
    this.base.apply(this, arguments);
    
    if (this.user) {
      if (this.user.height) {
        this.initialHeight = this.user.height + this.margin;
        
        if (!this.hidden) {
          this.height = this.initialHeight;
        }
      }
      
      for (var i in this.user) {
        if (i !== 'height') {
          this[i] = this.user[i];
        }
      }
    }
  },
  
  updateHeightToggler: function () {
    var hoverLabel = this.prop('hoverLabel');
    
    if (hoverLabel) {
      hoverLabel.find('div._track_height').toggleClass('auto_height', this.prop('autoHeight'));
    }
    
    hoverLabel = null;
  }
}, {
  on: Genoverse.Track.on
});