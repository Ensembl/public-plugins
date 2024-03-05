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

//Extension to Ensembl.Panel.Masthead to load tools tab via ajax

Ensembl.Panel.Masthead = Ensembl.Panel.Masthead.extend({

  init: function () {
    this.base();

    this.elLk.toolsTabs     = this.el.find('.tabs .tools'); // there are two tabs for tools - short and long
    this.elLk.toolsDropdown = this.el.find('.dropdown.tools');

    this.recentJobs = $.makeArray(this.elLk.toolsDropdown.find('li a').map(function(i, el) { return (el.href.match(/tl\=([a-z0-9_\-]+)/i) || []).pop() || null; }));
    this.fetchURL   ='/' + (Ensembl.species || 'Multi') + '/Ajax/tools_tab';

    if (this.elLk.toolsTabs.length) {
      this.fetchToolsTab();
    }
  },
  
  fetchToolsTab: function() {
    var panel = this;

    $.ajax({
      'url': this.fetchURL,
      'context': this,
      'data': { recent: this.recentJobs.join(','), tl: Ensembl.coreParams['tl'] || '' },
      'type': 'POST',
      'dataType': 'JSON',
      'success': function(json) {
        this.populateToolsTab(json);
      }
    });
  },

  populateToolsTab: function(response) {

    if (response.empty) {

      this.elLk.toolsTabs.find('a:not(:first-child)').remove().end().find('.dropdown').removeClass('dropdown');

    } else {

      this.elLk.toolsTabs.filter(':not(.final)').addClass('final').find('a:first-child').html(response.caption).attr('href', response.url);
      this.elLk.toolsDropdown.find('ul.recent').remove().end().find('h4').first().html('Recent jobs').after($('<ul>').append($.map(response.tools, function(details, tool) {
        return $('<li>').append($('<a>').attr('href', details.url).html(details.caption)).append($.map(details.jobs, function(job) {
          return $('<a>').attr('href', job.url).html(job.caption).appendTo('<li>').parent().appendTo('<ul class="recent">').parent();
        }));
      })));
    }

    this.elLk.toolsTabs.filter('.final').removeClass('hidden');
  }
});
