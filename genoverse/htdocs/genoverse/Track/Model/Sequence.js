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

Genoverse.Track.Model.Sequence = Genoverse.Track.Model.Stranded.extend({
  chunkSize : 1000,
  buffer    : 0,
  
  setURL: function () {
    if (!this.hasColors) {
      this.urlParams.colors = 1;
    }
    
    return this.base.apply(this, arguments);
  },
  
  getData: function (start, end) {
    start = start - start % this.chunkSize + 1;
    end  = end + this.chunkSize - end % this.chunkSize;
    return this.base(start, end);
  },
  
  parseData: function (data) {
    var i            = data.features.length;
    var strands      = [ 1, -1 ];
    var strand       = this.prop('strand');
    var lowerCase    = this.prop('lowerCase');
    var reverseTrack = this.prop('reverseTrack');
    var sequence, start, complement, str, seq, feature, id, j, k;
    
    if (data.colors) {
      this.hasColors = true;
      
      this.prop('colors',      data.colors);
      this.prop('labelColors', data.labelColors);
      
      if (reverseTrack) {
        reverseTrack.prop('colors',      data.colors);
        reverseTrack.prop('labelColors', data.labelColors);
      }
      
      delete this.urlParams.colors;
      this.setURL(this.urlParams, true);
    }
    
    while (i--) {
      sequence   = data.features[i].sequence[lowerCase ? 'toLowerCase' : 'toUpperCase']();
      start      = data.features[i].start;
      complement = this.complement(sequence);
      
      for (j in strands) {
        str = strands[j];
        seq = str === (data.features[i].strand || strand) ? sequence : complement;
        
        for (k = 0; k < seq.length; k += this.chunkSize) {
          id = (start + k) + ':' + str;
          
          if (this.featuresById[id]) {
            continue;
          }
          
          feature = {
            id       : id,
            sort     : start + k,
            start    : start + k,
            end      : start + k + this.chunkSize + this.buffer,
            strand   : str,
            sequence : seq.substr(k, this.chunkSize + this.buffer)
          };
          
          if (feature.sequence.length > this.buffer) {
            this.features.insert({ x: feature.start, w: this.chunkSize + this.buffer, y: 0, h: 1 }, feature);
            this.featuresById[id] = feature;
          }
        }
      }
    }
  },
  
  complement: function (sequence) {
    if (this.prop('lowerCase')) {
      return sequence.replace(/g/g, 'C').replace(/c/g, 'G').replace(/t/g, 'A').replace(/a/g, 'T').toLowerCase();
    } else {
      return sequence.replace(/G/g, 'c').replace(/C/g, 'g').replace(/T/g, 'a').replace(/A/g, 't').toUpperCase();
    }
  }
});