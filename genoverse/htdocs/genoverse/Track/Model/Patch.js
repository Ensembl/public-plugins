/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Genoverse.Track.Model.Patch = Genoverse.Track.Model.Stranded.extend({
  allData : true,

  // Return all features - there won't be many, and this ensures order and height is always correct
  findFeatures: function () {
    return this.features.search({ x: 1, y: 0, w: 9e99, h: 1 }).sort(function (a, b) { return a.sort - b.sort; });
  }
});