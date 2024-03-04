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

Ensembl.Panel.Pathway = Ensembl.Panel.Content.extend({
  init: function() {
    var panel = this;

    this.base.apply(this, arguments);

    this.elLk.container = $('.pathway', this.el);
    this.elLk.target = $('.pathway .widget #pathway_widget', this.el);
    this.elLk.pathwayList = $('.pathways_list ul', this.el);
    this.elLk.pathwayList.css({
      'max-height': '500px',
      'overflow-y': 'auto'
    });
    this.elLk.title = $('.widget .title', this.el);

    var species = this.params.species_common_name && this.params.species_common_name;
    var xrefs   = this.params.xrefs && JSON.parse(this.params.xrefs);
    var gene_id = this.params.geneId && this.params.geneId;
    this.reactome_url = this.params.reactomeUrl && this.params.reactomeUrl;

    if(!xrefs) {
      this.showError('No data available for this gene');
      return;
    }

    $.when(Ensembl._pathwayLoaded).done(function() {
      panel.udpateXrefsList(xrefs);
      var success = panel.insertWidget();
      success && panel.loadPathway(Object.keys(xrefs)[0], xrefs[Object.keys(xrefs)[0]]);
    });

  },

  udpateXrefsList: function(xrefs) {
    var li, id, title;
    var panel = this;
    $.each(xrefs, function(id, desc) {
      desc = desc || '';
      var li = $('<li />')
                  .data({'id': id, 'desc': desc})
                  .html(id + '<br><i>' + desc + '</i>')
                  .attr('title', desc)
      panel.elLk.pathwayList.append(li);
    });

    $('li', this.elLk.pathwayList).off().on('click', function() {
      id = $(this).data('id');
      title = $(this).data('desc');
      (panel.lastLoaded != id) && panel.loadPathway(id, title);
      $(this).addClass('active').siblings().removeClass('active');
    })

    $($('li', this.elLk.pathwayList)[0]).addClass('active');
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

    $($('li', this.elLk.pathwayList)[0]).addClass('active');
  },

  loadPathway: function(id, title) {
    var panel = this;
    title = title || id;
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
          "proxyPrefix" : this.reactome_url,
          "placeHolder" : "pathway_widget",
          "width" : 750,
          "height" : 450
      });
      this.diagram = diagram;
      return true;
    }
    else {
      this.showError('Could not load pathway widget')
      return false;
    }
  },

  showError: function(message) {
    this.elLk.container.html(message ? message : 'Error loading pathway widget');
  }
});

Ensembl._pathwayLoaded = $.Deferred();
window.onReactomeDiagramReady = function() { Ensembl._pathwayLoaded.resolve(); delete Ensembl._pathwayLoaded; };
