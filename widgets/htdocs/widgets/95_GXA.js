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

Ensembl.Panel.GXA = Ensembl.Panel.Content.extend({
  init: function() {

    this.base.apply(this, arguments);

    this.elLk.target = this.el.append('<div id="expression_atlas">');

    $.ajax({
      url: 'https://www.ebi.ac.uk/gxa/json/expressionData?geneId=' + this.params.geneId,
      dataType: 'json',
      context: this,
      success: function(json) {
        if (json[this.params.geneId]) {
          this.insertWidget();
        } else {
          this.showError('Expression Atlas does not contain baseline expression data for ' + this.params.geneId);
        }
      },
      error: function() {
        this.showError();
      }
    });
  },

  insertWidget: function() {
    var panel = this;
    if ('expressionAtlasHeatmapHighcharts' in window) {
      try {
        expressionAtlasHeatmapHighcharts.render({
//atlasHost: "https://wwwdev.ebi.ac.uk", //uncomment for testing widget before GXA release
          query:{gene: this.params.geneId, species: this.params.species} ,
          isMultiExperiment: true,
          target : this.elLk.target.attr('id'),
          fail: function() {
            panel.showError();
          }
        });
      } catch (ex) {
        console.log(ex);
        this.showError();
      }
    }
  },

  showError: function(message) {
    this.elLk.target.html(message ? message : 'We are currently unable to retrieve gene expression data from the <a href="https://www.ebi.ac.uk/gxa/">Expression Atlas</a>, please try again later.');
  }
});
