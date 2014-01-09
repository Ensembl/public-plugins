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

Genoverse.Track.View.TranslatedSequence = Genoverse.Track.View.Sequence.extend({
  widestLabel: 'M',
  
  positionFeature: function (feature, params) {
    this.base(feature, params);
    feature.position[params.scale].bottom = feature.position[params.scale].H * 3;
    params.featureHeight = Math.max(params.featureHeight, feature.position[params.scale].bottom);
  },
  
  draw: function () {
    this.drawn = {};
    return this.base.apply(this, arguments);
  },
  
  drawSequence: function (feature, context, scale) {
    var width      = scale * 3;
    var drawLabels = this.labelWidth[this.widestLabel] < width - 1;
    var phase      = 3;
    var strand     = this.prop('strand');
    var lowerCase  = this.prop('lowerCase');
    var translate  = this.prop('translate')[this.prop('codonTableId')];
    var codons     = this.prop('codons');
    var start, id, codon, sequence, y, i;
    
    while (phase--) {
      for (i = phase - 2; i < feature.sequence.length; i += 3) {
        start = feature.position[scale].X + i * scale;
        
        if (start < -width || start > context.canvas.width) {
          continue;
        }
        
        id = phase + ':' + (feature.start + i) + ':' + feature.strand;
        
        if (this.drawn[id]) {
          continue;
        }
        
        sequence = feature.sequence.substr(i, 3);
        
        if (strand === -1) {
          sequence = sequence.split('').reverse().join('');
        }
        
        codon = typeof codons[sequence] === 'number' ? translate.charAt(codons[sequence]) : lowerCase ? 'x' : 'X';
        y     = phase * (this.featureHeight + this.featureMargin.bottom);
        
        context.fillStyle = this.colors[codon] || this.colors['default'];
        context.fillRect(start, y, width, this.featureHeight);
        
        if (!this.labelWidth[codon]) {
          this.labelWidth[codon] = Math.ceil(context.measureText(codon).width) + 1;
        }
        
        if (drawLabels) {
          context.fillStyle = this.labelColors[codon] || this.labelColors['default'];
          context.fillText(codon, start + (width - this.labelWidth[codon]) / 2, y + this.labelYOffset);
        }
        
        this.drawn[id] = codon.toLowerCase() === 'x' ? 0 : 1;
      }
    }
  }
});
