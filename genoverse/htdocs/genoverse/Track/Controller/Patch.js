/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Genoverse.Track.Controller.Patch = Genoverse.Track.Controller.Stranded.extend({
  makeImage: function (params) {
    return this.base($.extend(params, { background: true }));
  },
  
  render: function (f, img) {
    var strand = this.prop('strand');
    
    img.off('load').on('load', function () {
      $(this).fadeIn('fast').parent().removeClass('loading');
      
      if (strand === -1) {
        $(this).siblings('.bg').show();
        img.data('container').children('img').show(); // img data for the reverse strand is cloned from that of the forward strand, so container is actually the forward strand image's container
      }
    });
    
    return this.base(f, img);
  },
  
  renderBackground: function (f, img) {
    var params   = img.data();
    var features = this.view.positionFeatures($.extend(true, [], this.model.findFeatures(params.start, params.end)), params);
    var heights  = [ Math.max(params.height, this.minLabelHeight) ];
    
    if (this.prop('strand') === 1) {
      var bounds = { x: params.scaledStart, w: params.width, y: 0, h: 9e99 };
      var top    = Math.max.apply(Math, $.map(this.featurePositions.search(bounds), function (feature) { return feature.position[params.scale].bottom; }).concat(0));
      
      img.push(img.clone(true).addClass('fullHeight').css('top', top).prependTo(img.parent().addClass('fullHeight'))[0]);
      heights.push(1);
    } else {
      img.css('background', this.browser.colors.background);
    }
    
    for (var i = 0; i < img.length; i++) {
      this.base(features, img.eq(i), heights[i]);
    }
  },
  
  autoResize: function () {
    var reverseTrack = this.prop('reverseTrack');
    var forwardTrack = this.prop('forwardTrack');
    
    if (this.strand === 1 && reverseTrack.fullVisibleHeight) {
      this.resize(this.fullVisibleHeight);
      
      if (this.prop('height') === 0) {
        reverseTrack.resize(0);
      }
    } else {
      this.resize(forwardTrack && forwardTrack.prop('height') === 0 ? 0 : this.fullVisibleHeight);
    }
  }
});