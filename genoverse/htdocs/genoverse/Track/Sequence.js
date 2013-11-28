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

Genoverse.Track.Sequence = Genoverse.Track.extend({
  autoHeight : 'force',
  spacing    : 0,
  strand     : 1,
  chunkSize  : 1000,
  buffer     : 0,
  inherit    : [ 'Stranded' ],
  
  constructor: function (config) {
    this.base(config);
    
    this.labelWidth   = {};
    this.widestLabel  = this.lowerCase ? 'g' : 'G';
    this.labelYOffset = (this.featureHeight + (this.lowerCase ? 0 : 1)) / 2;
    
    if (!this.colors) {
      this.colors           = {};
      this.labelColors      = {};
      this.urlParams.colors = 1;
    }
  },
  
  complement: function (sequence) {
    if (this.lowerCase) {
      return sequence.replace(/g/g, 'C').replace(/c/g, 'G').replace(/t/g, 'A').replace(/a/g, 'T').toLowerCase();
    } else {
      return sequence.replace(/G/g, 'c').replace(/C/g, 'g').replace(/T/g, 'a').replace(/A/g, 't').toUpperCase();
    }
  },
  
  parseData: function (data) {
    var i       = data.features.length;
    var strands = [ 1, -1 ];
    var sequence, start, complement, strand, seq, feature, id, j, k;
    
    if (data.colors) {
      this.colors      = data.colors;
      this.labelColors = data.labelColors;
      
      if (this.reverseTrack) {
        this.reverseTrack.colors      = this.colors;
        this.reverseTrack.labelColors = this.labelColors;
      }
      
      delete this.urlParams.colors;
    }
    
    while (i--) {
      sequence   = data.features[i].sequence[this.lowerCase ? 'toLowerCase' : 'toUpperCase']();
      start      = data.features[i].start;
      complement = this.complement(sequence);
      
      for (j in strands) {
        strand = strands[j];
        seq    = strand === (data.features[i].strand || this.strand) ? sequence : complement;
        
        for (k = 0; k < seq.length; k += this.chunkSize) {
          id = (start + k) + ':' + strand;
          
          if (this.featuresById[id]) {
            continue;
          }
          
          feature = {
            id       : id,
            sort     : start + k,
            start    : start + k,
            end      : start + k + this.chunkSize + this.buffer,
            strand   : strand,
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
  
  draw: function (features, featureContext, labelContext, scale) {
    featureContext.textBaseline = 'middle';
    
    if (!this.labelWidth[this.widestLabel]) {
      this.labelWidth[this.widestLabel] = Math.ceil(this.context.measureText(this.widestLabel).width) + 1;
    }
    
    for (var i = 0; i < features.length; i++) {
      if (this.strand === features[i].strand) {
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
  },
  
  getQueryString: function (start, end) {
    return this.base(start - start % this.chunkSize + 1, end + this.chunkSize + this.buffer - end % this.chunkSize);
  },
  
  click: function (e) {
    var x       = Math.floor((e.pageX - this.container.parent().offset().left + this.browser.scaledStart) / this.scale);
    var strand  = this.strand;
    var feature = $.grep(this.features.search({ x: x, w: 1, y: 0, h: 1 }), function (f) { return f.strand === strand; })[0];
    
    if (feature) {
      this.browser.makeMenu(this.menuFeature(feature, x), e, this);
    }
  },
  
  menuFeature: function (feature, position) {
    return {
      id    : feature.id + ':' + position,
      title : feature.sequence.charAt(position - feature.start) + '; Position: ' + this.browser.chr + ':' + position
    };
  }
});
