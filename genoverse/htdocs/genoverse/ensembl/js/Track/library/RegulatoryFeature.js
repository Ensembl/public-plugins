/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

Genoverse.Track.RegulatoryFeature = Genoverse.Track.extend({
  legendType   : 'Regulation', // this forces single legend for all reg feature tracks
  legendName   : 'Regulation Legend',
  legend       : true,

  view: Genoverse.Track.View.extend({
    bump   : true,
    labels : false,
    y_reg_features : {
       'CTCF': 35,
       'promoter': 3,
       'enhancer': 19,
       'open chromatin': 19,
       'transcription factor binding': 19
    },
    drawFeature: function (feature, featureContext, labelContext, scale) {
      if (this.bump) {
      	feature.y = this.y_reg_features[feature.label];
      }
      this.base(feature, featureContext, labelContext, scale);
      feature.legend = feature.label;
    },
 
    bumpFeature: function (bounds, feature, scale, tree) {
      feature.y = this.y_reg_features[feature.label];
      this.base(bounds, feature, scale, tree);
    },

    decorateFeature: function (feature, context, scale) {
      var position    = feature.position[scale];
      var startOffset = position.start - position.X;
      var mid         = position.height / 2;
      var decoration, end;
      
      for (var i = 0; i < feature.decorations.length; i++) {
        decoration       = feature.decorations[i];
        decoration.x     = decoration.start * scale - startOffset;
        decoration.width = (decoration.end - decoration.start) * scale + Math.max(scale, 1);
        
        context.fillStyle = decoration.color;
        
        if (decoration.x < 0 || decoration.x + decoration.width > this.width) {
          this.truncateForDrawing(decoration);
        }
        
        if (decoration.style === 'rect') {
          context.fillRect(decoration.x, position.Y, decoration.width, this.featureHeight);
        } else if (decoration.style === 'fg_ends') {
          end = decoration.end * scale - startOffset;
          
          if (decoration.x >= 0) {
            context.fillRect(decoration.x, position.Y, 1, position.height);
          }
          
          if (end <= this.width) {
            context.fillRect(end, position.Y, 1, position.height);
          }
          
          context.fillRect(decoration.x, position.Y + mid, decoration.width, 1);
        }
      }
    }
  })
});
