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

Genoverse.Track.View.Sequence = Genoverse.Track.View.extend({
  featureMargin : { top: 0, right: 0, bottom: 2, left: 0 },
  colors        : {},
  labelColors   : {},
  widestLabel   : 'G',
  
  constructor: function () {
    this.base.apply(this, arguments);
    
    var lowerCase = this.prop('lowerCase');
    
    this.labelWidth   = {};
    this.labelYOffset = (this.featureHeight + (lowerCase ? 0 : 1)) / 2;
    
    if (lowerCase) {
      this.widestLabel = this.widestLabel.toLowerCase();
    }
  },
  
  draw: function (features, featureContext, labelContext, scale) {
    featureContext.textBaseline = 'middle';
    
    if (!this.labelWidth[this.widestLabel]) {
      this.labelWidth[this.widestLabel] = Math.ceil(this.context.measureText(this.widestLabel).width) + 1;
    }
    
    for (var i = 0; i < features.length; i++) {
      if (this.prop('strand') === features[i].strand) {
        this.drawSequence(features[i], featureContext, scale);
      }
    }
  },
  
  drawSequence: function (feature, context, scale) {
    var drawLabels = this.labelWidth[this.widestLabel] < scale - 1;
    var start, bp;
    
    for (var i = 0; i < feature.sequence.length; i++) {
      start = feature.position[scale].X + i * scale;
      
      if (start < -scale || start > context.canvas.width) {
        continue;
      }
      
      bp = feature.sequence.charAt(i);
      
      context.fillStyle = this.colors[bp] || this.colors['default'];
      context.fillRect(start, feature.position[scale].Y, scale, this.featureHeight);
      
      if (!this.labelWidth[bp]) {
        this.labelWidth[bp] = Math.ceil(context.measureText(bp).width) + 1;
      }
      
      if (drawLabels) {
        context.fillStyle = this.labelColors[bp] || this.labelColors['default'];
        context.fillText(bp, start + (scale - this.labelWidth[bp]) / 2, feature.position[scale].Y + this.labelYOffset);
      }
    }
  }
});