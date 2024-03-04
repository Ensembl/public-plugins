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

Genoverse.Track.Contig = Genoverse.Track.extend({
  resizable : false,
  allData   : true,
  
  view: Genoverse.Track.View.extend({
    borderColor   : '#000000',
    labels        : 'overlay',
    repeatLabels  : true,
    featureMargin : { top: 0, right: 0, bottom: 0, left: 0 },
    
    positionFeatures: function (features, params) {
      this.base(features, params);
      params.featureHeight = params.featureHeight || this.prop('height');
      return features;
    },
    
    draw: function (features, featureContext, labelContext, scale) {
      featureContext.fillStyle = this.borderColor;
      
      featureContext.fillRect(0, 0,                      this.width, 1);
      featureContext.fillRect(0, this.featureHeight - 1, this.width, 1); 
      
      this.base(features, featureContext, labelContext, scale);
    }
  })
});