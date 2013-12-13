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

Genoverse.Track.Contig = Genoverse.Track.extend({
  borderColor : '#000000',
  labels      : 'overlay',
  fixedHeight : true,
  allData     : true,
  
  draw: function (features, featureContext, labelContext, scale) {
    featureContext.fillStyle = this.borderColor;
    featureContext.fillRect(0, 0,                      this.width, 1);
    featureContext.fillRect(0, this.defaultHeight - 1, this.width, 1);
    
    this.base(features, featureContext, labelContext, scale);
  }
});
