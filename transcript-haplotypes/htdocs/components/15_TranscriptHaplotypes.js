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

Ensembl.Panel.TranscriptHaplotypes = Ensembl.Panel.Content.extend({
  init: function () {
    var panel = this;

    this.base();

    // get data
    this.alignmentData = JSON.parse(this.params['alignment_data']);
    delete this.params['alignment_data'];

    // Initialise ZMenus on links
    this.el.find('a.zmenu').on('click', function(e) {
      e.preventDefault();
      Ensembl.EventManager.trigger('makeZMenu', $(this).text().replace(/\W/g, '_'), { event: e, area: { link: $(this) }});
    });

    // activate alignment links
    this.el.find('a.alignment-link').on('click', function(e) {
      $('pre.alignment-view').show().empty().append(panel.alignmentData[this.rel]['aln']);
    });

    // activate sequence links
    this.el.find('a.sequence-link').on('click', function(e) {
      $('pre.alignment-view').show().empty().append(panel.alignmentData[this.rel]['seq'].match(/.{1,60}/g).join("\n"));
    });

    console.log(this.alignmentData);
  }
});
