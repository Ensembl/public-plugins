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

Genoverse.Track.Synteny = Genoverse.Track.extend({
  featureHeight : 5,
  bump          : true,
  
  model: Genoverse.Track.Model.extend({
    allData: true,
    
    init: function () {
      this.primaryTrack = this.prop('id');
      this.dfds         = {};
      
      for (var i = 0; i < this.browser.tracks.length; i++) {
        if (this.browser.tracks[i].type === 'Synteny') {
          this.primaryTrack = this.browser.tracks[i].id;
          break;
        }
      }
      
      this.colors = this.browser.tracksById[this.primaryTrack] ? this.browser.tracksById[this.primaryTrack].model.colors : false;
      
      this.base();
    },
    
    getData: function (start, end) {
      if (this.colors) {
        return this.base(start, end);
      }
      
      var id = this.prop('id');
      
      if (this.prop('primaryTrack') === id) {
        this.setURL({ colors: 1 });
        
        return this.base(start, end).done(function () {
          for (var i = 0; i < this.browser.tracks.length; i++) {
            if (this.browser.tracks[i].type === 'Synteny' && this.browser.tracks[i].id !== id) {
              this.browser.tracks[i].model.colors = this.colors;
              this.browser.tracks[i].model.getData(start, end).done(function () { this.dfds[start + ':' + end].resolveWith(this); });
            }
          }
        });
      }
      
      return this.dfds[start + ':' + end] = $.Deferred();
    },
    
    parseData: function (data, start, end) {
      if (data.colors) {
        this.colors = data.colors;
      }
      
      for (var i = 0; i < data.features.length; i++) {
        data.features[i].color = data.features[i].labelColor = this.colors[data.features[i].colorId];
      }
      
      this.base(data, start, end);
    }
  })
});