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

Ensembl.Panel.VEPResultsSummary = Ensembl.Panel.Piechart.extend({
  init: function () {
    this.base();
    
    // Consequence colours
    this.graphColours = JSON.parse(this.params['cons_colours'].replace(/\'/g, '"'));
    this.graphColours['default'] = [ '#222222', '#FF00FF', '#008080', '#7B68EE' ];
  },
  
  toggleContent: function (el) {
    if (el.hasClass('closed') && !el.data('done')) {
      this.base(el);
      this.makeGraphs($('.pie_chart > div', '.' + el.attr('rel')).map(function () { return this.id.replace('graphHolder', ''); }).toArray());
      el.data('done', true);
    } else {
      this.base(el);
    }
    
    el = null;
  }
});
