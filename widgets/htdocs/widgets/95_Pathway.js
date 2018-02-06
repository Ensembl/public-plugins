/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

Ensembl.Panel.Pathway = Ensembl.Panel.Content.extend({
  init: function() {
    var panel = this;

    this.base.apply(this, arguments);

    this.elLk.container = $('.pathway', this.el);
    this.elLk.target = $('.pathway .widget #pathway_widget', this.el);
    this.elLk.pathwayList = $('.pathways_list ul', this.el);
    this.elLk.title = $('.widget .title', this.el);

    var species = this.params.species_common_name && this.params.species_common_name;
    var xref_id = this.params.xrefId &&this.params.xrefId;
    var gene_id = this.params.geneId && this.params.geneId;

    if(!xref_id) {
      this.showError('No data available to retrieve from Plant Reactome for this gene');
      return;
    }

    $.ajax({
      url: 'http://plantreactome.gramene.org/ContentService/data/species/main',
      dataType: 'json',
      success: function(json) {
        if (json) {
          $(json).each(function(i, hash) {
            if(hash.displayName == species) {
              var pathway_ids = [];
              $.ajax({
                url: 'http://plantreactome.gramene.org/ContentService/data/pathways/low/diagram/entity/'+xref_id+'?speciesId='+hash.dbId,
                dataType: 'json',
                success: function(json) {
                  if (json) {
                    $.when(Ensembl._pathwayLoaded).done(function() {
                      panel.udpatePathwaysList(json);
                      var success = panel.insertWidget();
                      success && panel.loadPathway(json[0].stId, json[0].displayName);
                    });
                  }
                  else {
                    this.showError('No data available to retrieve from Plant Reactome for this gene');
                    console.log('JSON: ', json);
                  }
                },
                error: function(XMLHttpRequest, textStatus, errorThrown) {
                  this.showError('Unable to fetch data from Plant Reactome. Please try after sometime.');
                  console.log("Pathway component couldn't download pathway data");
                  console.log("Status: " + textStatus + " Error: " + errorThrown);
                }
              });
            }
          });
        }
        else {
          this.showError('Unable to fetch data from Plant Reactome. Please try after sometime.');
        }
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        this.showError('No data available to retrieve from Plant Reactome for this gene');
        console.log("Pathway component couldn't download species data");
        console.log("Status: " + textStatus + " Error: " + errorThrown);
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
    if (panel.diagram) {
      panel.diagram.loadDiagram(id)
      panel.diagram.onDiagramLoaded(function (loaded) {
        panel.params.geneId && panel.diagram.flagItems(panel.params.geneId);
        panel.diagram.selectItem(id);
      });
    }
    panel.lastLoaded = id;

  },

  insertWidget: function() {
    var panel = this;

    if(window.Reactome) {
      var diagram = Reactome.Diagram.create({
          "proxyPrefix" : "http://plantreactome.gramene.org",
          "placeHolder" : "pathway_widget",
          "width" : 750,
          "height" : 450
      });
      this.diagram = diagram;
      return true;
    }
    else {
      this.showError('Could not load the Reactome widget')
      return false;
    }
  },

  showError: function(message) {
    this.elLk.container.html(message ? message : 'Error loading Plant Reactome widget');
  }
});

Ensembl._pathwayLoaded = $.Deferred();
window.onReactomeDiagramReady = function() { Ensembl._pathwayLoaded.resolve(); delete Ensembl._pathwayLoaded; };
