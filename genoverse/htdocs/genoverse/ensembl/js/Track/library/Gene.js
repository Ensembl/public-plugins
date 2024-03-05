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

Genoverse.Track.Gene = Genoverse.Track.extend({
  height       : 50,
  legendType   : 'GeneLegend', // this forces single gene legend for all Gene tracks
  legendName   : 'Gene Legend',
  legend       : true,
  lengthConfig : {
    1: {
      model : Genoverse.Track.Model.Gene.Transcript,
      view  : Genoverse.Track.View.Gene.Transcript
    },
    1e6: {
      model : Genoverse.Track.Model.Gene.Collapsed,
      view  : Genoverse.Track.View.Gene.Collapsed
    },
    2e6: {
      labels : false
    },
    1e7: {
      model : Genoverse.Track.Model.Gene,
      view  : Genoverse.Track.View.Gene
    },
    10000001: {
      labels : false
    }
  },
  
  rendererThresholds: { transcript: 1, collapsed: 1e6, gene: 1e7 },
  
  setLengthMap: function () {
    var config = $.extend(true, {}, this.lengthConfig);
    
    if (this.renderer) {
      var renderer = this.renderer.split('_');
      var noLabels = /nolabel/.test(renderer[1]);
      
      for (var i in config) {
        if (parseInt(i, 10) < this.rendererThresholds[renderer[0]]) {
          delete config[i];
        } else if (noLabels) {
          config[i].labels = false;
        }
      }
      
      if (this.rendererThresholds[renderer[0]] !== 1) {
        config[1] = config[this.rendererThresholds[renderer[0]]];
        delete config[this.rendererThresholds[renderer[0]]];
      }
    }
    
    this.extend(config);
    this.base();
  }
});