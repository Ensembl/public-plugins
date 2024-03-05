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

Genoverse.Track.Clone = Genoverse.Track.extend({
  bump         : true,
  labels       : 'overlay',
  repeatLabels : true,
  
  decorateFeature: function (feature, context, scale) {
    var i = feature.decorations.length;
    var decoration, x, y;
    
    while (i--) {
      decoration = feature.decorations[i];
      
      context.fillStyle = context.strokeStyle = decoration.color;
      
      if (decoration.style === 'left-triangle') {
        x = Math.round(feature.position[scale].X) + 0.5;
        y = feature.position[scale].Y + 0.5;
        
        context.beginPath();
        context.moveTo(x, y);
        context.lineTo(x + Math.min(feature.position[scale].W, 3), y);
        context.lineTo(x, y + 3);
        context.closePath();
        context.fill();
        context.stroke();
      } else if (decoration.style === 'rect') {
        context.fillRect(decoration.start * scale, feature.position[scale].Y, Math.max((decoration.end - decoration.start + 1) * scale, 1), this.featureHeight);
      }
    }
  }
});