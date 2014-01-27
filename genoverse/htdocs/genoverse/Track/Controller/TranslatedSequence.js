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

Genoverse.Track.Controller.TranslatedSequence = Genoverse.Track.Controller.Sequence.extend({
  click: function (e) {
    var x         = Math.floor((e.pageX - this.container.parent().offset().left + this.browser.scaledStart) / this.scale);
    var phase     = Math.floor((e.pageY - $(e.target).offset().top) / (this.prop('featureHeight') + this.prop('featureMargin').bottom));
    var diff      = phase - (x % 3);
    var strand    = this.prop('strand');
    var lowerCase = this.prop('lowerCase');
    var translate = this.prop('translate')[this.prop('codonTableId')];
    var codons    = this.prop('codons');
    var features  = $.grep(this.prop('features').search({ x: x, w: 1, y: 0, h: 1 }), function (f) { return f.strand === strand; });
    var i         = features.length;
    var seq, codon, feature;
    
    while (i--) {
      feature = features[i];
      
      if (diff === 0) {
        x--;
      } else if (diff === -1 || diff === 2) {
        x -= 2;
      }
      
      seq = feature.sequence.substr(x - feature.start, 3);
      
      if (strand === -1) {
        seq = seq.split('').reverse().join('');
      }
      
      codon = typeof codons[seq] === 'number' ? translate.charAt(codons[seq]) : lowerCase ? 'x' : 'X';
      
      if (codon.toLowerCase() !== 'x' || !i) {
        this.browser.makeMenu(this.menuFeature(feature, x, codon), e, this);
        break;
      }
    }
  },
  
  menuFeature: function (feature, position, codon) {
    return {
      id    : feature.id + ':' + position,
      title : codon + '; Location: ' + this.browser.chr + ':' + position + '-' + (position + 2)
    };
  }
});
