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

Genoverse.Track.View.Patch = Genoverse.Track.View.extend({
  bump          : true,
  featureHeight : 2,
    
  setDefaults: function () {
    if (this.prop('strand') !== -1) {
      this.featureMargin = { top: 0, right: 1, bottom: 0, left: 0 }; // featureMargin is shared between forward and reverse track for some reason, so completely overwrite it
      this.labels        = false;
    }
    
    this.base();
  },
  
  positionFeatures: function (originalFeatures, params) {
    if (this.prop('strand') === -1) {
      var scale    = params.scale;
      var features = $.extend(true, [], originalFeatures);
      var i        = features.length;
      
      while (i--) {
        delete features[i].position[scale].H;
        delete features[i].position[scale].Y;
        delete features[i].position[scale].bottom;
        delete features[i].position[scale].positioned;
      }
      
      return this.base(features, params);
    } else {
      return this.base(originalFeatures.reverse(), params);
    }
  },
  
  drawBackground: function (features, context, params) {
    var scale   = params.scale;
    var reverse = this.prop('strand') === -1;
    
    if (reverse) {
      features.reverse();
    }
    
    for (var i = 0; i < features.length; i++) {
      this.drawFeature(
        $.extend({}, features[i], {
            x     : features[i].position[scale].X,
            width : features[i].position[scale].width,
            color : features[i].background,
            label : false
          },
          reverse ?
            { height: features[i].position[scale].Y, y: 0 } :
            { height: context.canvas.height,         y: context.canvas.height === 1 ? 0 : features[i].position[scale].bottom - this.prop('margin') }
        ),
        context, false, scale
      );
    }
  }
});