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

Ensembl.Panel.TicketDetails = Ensembl.Panel.ContentTools.extend({

  constructor: function() {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('toolsViewTicket', this, this.viewTicket);
    Ensembl.EventManager.register('toolsRefreshTicket', this, this.refresh);
    Ensembl.EventManager.register('toolsHideTicket', this, this.hide);
  },

  init: function() {

    this.base();

    var panel = this;

    // Edit icons
    this.el.find('._ticket_edit').on('click', function() {
      var tl          = (this.href.match(/tl=([a-z0-9_-]+)/i) || []).pop();
      var ticketName  = tl.split('-')[0];
      if (ticketName !== panel.currentTicket) {
        Ensembl.EventManager.trigger('toolsToggleForm', false, true);
        panel.currentTicket = ticketName;
      }
      return !!tl && !Ensembl.EventManager.trigger('toolsEditTicket', tl);
    });

    // Hide button
    this.el.find('._ticket_hide').on('click', function(e) {
      e.preventDefault();
      panel.el.empty();
      panel.hide();
    });

    // Redirect to tools form after delete
    this.el.find('._ticket_delete').on('click', function(e) {
      if ($(this).data('redirect-url')) {
        Ensembl.redirect($(this).data('redirect-url'));
      }
    });
  },

  refresh: function(refreshActivitySummary) {
  /*
   * Method called by backend to refresh the displayed ticket
   */

    this.getContent();
    if (refreshActivitySummary) {
      Ensembl.EventManager.trigger('toolsRefreshActivitySummary', false, false, true);
    }
  },

  viewTicket: function(ticketName) {

    var ajaxURL = this.params.updateURL.replace(/tl\=[a-z0-9_-]+/i, '');
    if (!ajaxURL.match(/\?/)) {
      ajaxURL += '?';
    }

    this.getContent(ajaxURL, this.el.show(), { updateURL: ajaxURL, updateData: {'tl' : ticketName, 'view': 1} });
    this.scrollIn();

    return true;
  }
});
