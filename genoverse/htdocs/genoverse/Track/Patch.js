/*
 * Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

// $Revision$

Genoverse.Track.Patch = Genoverse.Track.extend({
  featureHeight : 2,
  bumpSpacing   : 0,
  bump          : true,
  autoHeight    : true,
  allData       : true,
  unsortable    : true,
  resizable     : false,
  featureStrand : 1,
  inherit       : [ 'Stranded' ],
  
  init: function () {
    this.base();
    
    if (this.strand === -1) {
      this.bumpSpacing = 4;
    } else {
      this.labels = false;
    }
  },
  
  // Return all features - there won't be many, and this ensures order and height is always correct
  findFeatures: function () {
    return this.features.search({ x: 1, y: 0, w: 9e99, h: 1 }).sort(function (a, b) { return a.sort - b.sort; });
  },
  
  positionFeatures: function (originalFeatures, params) {
    if (this.strand === 1) {
      return this.base(originalFeatures.reverse(), params);
    } else {
      var scale    = this.scale;
      var features = $.extend(true, [], originalFeatures);
      var i        = features.length;
      
      while (i--) {
        delete features[i].position[scale].H;
        delete features[i].position[scale].Y;
        delete features[i].position[scale].bottom;
        delete features[i].position[scale].positioned;
      }
      
      return this.base(features, params);
    }
  },
  
  makeImage: function (params) {
    params.background = true;
    return this.base(params);
  },
  
  renderBackground: function (f, img) {
    var params   = img.data();
    var features = this.positionFeatures($.extend(true, [], this.findFeatures(params.start, params.end)), params);
    var heights  = [ params.height ];
    
    if (this.strand === 1) {
      img.push(img.clone(true).addClass('fullHeight').css('top', this.fullVisibleHeight).prependTo(img.parent().addClass('fullHeight'))[0]);
      heights.push(1);
    } else {
      img.css('background', this.browser.colors.background);
    }
    
    for (var i = 0; i < img.length; i++) {
      this.base(features, img.eq(i), heights[i]);
    }
  },
  
  drawBackground: function (features, context, params) {
    var scale   = params.scale;
    var reverse = this.strand === -1;
    
    if (reverse) {
      features.reverse();
    }
    
    for (var i = 0; i < features.length; i++) {
      this.drawFeature($.extend({}, features[i], {
        x     : features[i].position[scale].X,
        width : features[i].position[scale].width,
        color : features[i].background,
        label : false
      }, reverse ? { y: 0, height: features[i].position[scale].Y } : { y: context.canvas.height === 1 ? 0 : features[i].position[scale].bottom - this.spacing, height: context.canvas.height }), context, false, scale);
    }
  }
});
