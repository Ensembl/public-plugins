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

Genoverse.Track.Variation = Genoverse.Track.extend({  
  setLengthMap: function () {
    var config;
    
    switch (this.renderer) {
      case 'nolabels' : config = { 1: { nameLabels : false } };                                          break;
      case 'labels'   : config = { 1: { nameLabels : true              }, 1e4: { nameLabels : false } }; break;
      case 'normal'   : config = { 1: { nameLabels : false, depth : 20 }, 2e5: { bump       : false } }; break;
      default         : config = { 1: { bump       : false } };                                          break;
    }
    
    this.extend(config);
    this.base();
  },
  
  view: Genoverse.Track.View.extend({
    bump   : true,
    labels : 'overlay',
    
    setScale: function () {
      this.prop('dataBuffer').start = this.prop('nameLabels') ? this.browser.labelBuffer : 0;
      this.base();
    },
    
    positionFeature: function (feature, params) {
      var scale = params.scale;
      var width = feature.position[scale].width;
    
      if (!feature.nameWidth) {
        var context = this.context;
        
        for (var i = 0; i < feature.decorations.length; i++) {
          if (feature.decorations[i].style === 'label') {
            feature.nameWidth = Math.ceil(context.measureText(feature.decorations[i].label).width) + 1;
            break;
          }
        }
      }
      
      if (feature.nameWidth && this.prop('nameLabels')) {
        feature.position[scale].width += feature.nameWidth;
      }
      
      this.base(feature, params);
      
      feature.position[scale].width = width;
    },
    
    // Add labels and triangles at the bottom of inserts
    decorateFeature: function (feature, context, scale) {
      var showLabels = this.prop('nameLabels');
      var i          = feature.decorations.length;
      var position;
      
      while (i--) {
        context.fillStyle = feature.decorations[i].color;
        position          = feature.position[scale];
        
        if (feature.decorations[i].style === 'insertion') {
          context.beginPath();
          context.moveTo(position.X - 3, position.Y + this.featureHeight);
          context.lineTo(position.X,     position.Y + this.featureHeight - 4);
          context.lineTo(position.X + 3, position.Y + this.featureHeight);
          context.fill();
        } else if (showLabels && feature.decorations[i].style === 'label') {
          // Normal labels are overlaid, so textAlign = center and textBaseline = middle. Adjust position here, rather than setting and then resetting textAlign and textBaseline for each feature.
          context.fillText(feature.decorations[i].label, position.X + position.width + feature.nameWidth / 2, position.Y + this.featureHeight / 2);
        }
      }
    }
  })
});