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

Genoverse.Track.ChrBand = Genoverse.Track.extend({
  resizable     : 'auto',
  labels        : 'overlay',
  allData       : true,
  repeatLabels  : true,
  featureMargin : { top: 0, right: 0, bottom: 0, left: 0 }
});

Genoverse.Track.Codons = Genoverse.Track.extend({
  resizable     : 'auto',
  featureHeight : 3
});

Genoverse.Track.Marker = Genoverse.Track.extend({
  bump : 'labels',  
  1    : { labels: true  }, 
  5e4  : { labels: false }
});

Genoverse.Track.Patch = Genoverse.Track.extend({
  name          : 'Patches',
  controls      : 'off',
  featureStrand : 1,
  unsortable    : true,
  resizable     : 'auto'
});

Genoverse.Track.SegmentationFeature = Genoverse.Track.extend({
  resizable     : 'auto',
  featureMargin : { top: 0, right: 0, bottom: 0, left: 0 }
});

Genoverse.Track.Sequence = Genoverse.Track.extend({
  resizable : 'auto',
  strand    : 1,
  lowerCase : false
});