/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

Ensembl.Panel.PlantReactome = Ensembl.Panel.Content.extend({
  init: function() {
    var panel = this;

    this.base.apply(this, arguments);

    this.elLk.target = this.el.append('<div id="plant_reactome_widget">');

    if(!this.params.xrefId) {
      this.showError('Reactome ID not available');
      return;
    } 

    var species = this.params.species.replace('_', ' ');
    var xref_id = this.params.xrefId;
    var gene_id = this.params.geneId;
    $.ajax({
      url: 'http://plantreactome.gramene.org/ContentService/data/species/main',
      dataType: 'json',
      context: this,
      success: function(json) {
        if (json) {
          $(json).each(function(i, hash) {
            if(hash.displayName == species) {
              var pathway_ids = [];
              $.ajax({
                url: 'http://plantreactome.gramene.org/ContentService/data/pathways/low/diagram/entity/'+xref_id+'?speciesId='+hash.dbId,
                dataType: 'json',
                context: this,
                success: function(json) {
                  if (json) {
                    $(json).each(function(i, hash) {
                      pathway_ids.push(hash.stId);
                    });
                    console.log(pathway_ids);
                    panel.insertWidget();
                    pathway_ids[0] && panel.diagram.loadDiagram(pathway_ids[0])
                    console.log(gene_id);
                    panel.diagram.onDiagramLoaded(function (loaded) {
                      gene_id && panel.diagram.flagItems(gene_id);
                    });
                  }
                }
              });
            }
          });

        }
      }
    });
    return;
    $.ajax({
      url: 'http://ves-hx-78.ebi.ac.uk:9002/reactome/download/current/diagram/' + this.params.xref_id + '.json',
      type: 'HEAD',
      context: this,
      success: function(message,text,jqXHR) {
        if (jqXHR.status === 200) {
          this.insertWidget();
        } else {
          this.showError('Plant Reactome does not contain data for ' + this.params.xref_id);
        }
      },
      error: function() {
        this.showError('Plant Reactome does not contain data for ' + this.params.xref_id);
      }
    });


  },

  insertWidget: function() {
    var panel = this;
    var diagram = Reactome.Diagram.create({
        "proxyPrefix" : "http://plantreactome.gramene.org",
        "placeHolder" : "plant_reactome_widget",
        "width" : 650,
        "height" : 450
    });
    this.diagram = diagram;
    // console.log(this.params.xref_id);
    // //Initialising pathway
    // diagram.loadDiagram('R-ATH-1119605');

    // //Adding different listeners

    // diagram.onDiagramLoaded(function (loaded) {
    //     // console.info("Loaded ", loaded);
    //     diagram.flagItems('AT1G74470');
    //     // diagram.selectItem("R-OSA-8933859");
    // });
  },

  showError: function(message) {
    this.elLk.target.html(message ? message : 'Error loading Plant Reactome widget');
  }
});
