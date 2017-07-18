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

    this.elLk.target = $('.reactome .widget #plant_reactome_widget', this.el);
    this.elLk.pathwayList = $('.pathways_list ul', this.el);
    this.elLk.title = $('.widget .title', this.el);

    if(!this.params.xrefId) {
      this.showError('Reactome ID not available');
      return;
    }

    var species = this.params.species_common_name;
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
                    panel.udpatePathwaysList(json);
                    panel.insertWidget();
                    panel.loadPathway(json[0].stId, json[0].displayName);
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

  udpatePathwaysList: function(json) {
    var li, id, title;
    var panel = this;
    $.each(json, function(i, pw) {
      var li = $('<li />')
                  .data(pw)
                  .html(pw.displayName)
      panel.elLk.pathwayList.append(li);
    });

    $('li', this.elLk.pathwayList).off().on('click', function() {
      id = $(this).data('stId');
      title = $(this).data('displayName');
      (panel.lastLoaded != id) && panel.loadPathway(id, title);
      $(this).addClass('active').siblings().removeClass('active');
    })

    $($('li', this.elLk.pathwayList)[0]).addClass('active');//.addClass('active');
  },

  loadPathway: function(id, title) {
    var panel = this;
    panel.elLk.title.html(title)
    panel.diagram.loadDiagram(id)
    panel.diagram.onDiagramLoaded(function (loaded) {
      panel.params.geneId && panel.diagram.flagItems(panel.params.geneId);
    });
    panel.lastLoaded = id;

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
