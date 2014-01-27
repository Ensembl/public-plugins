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

Genoverse.Track.Controller.Sequence = Genoverse.Track.Controller.Stranded.extend({
  click: function (e) {
    var x       = Math.floor((e.pageX - this.container.parent().offset().left + this.browser.scaledStart) / this.scale);
    var strand  = this.prop('strand');
    var feature = $.grep(this.prop('features').search({ x: x, w: 1, y: 0, h: 1 }), function (f) { return f.strand === strand; })[0];
    
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