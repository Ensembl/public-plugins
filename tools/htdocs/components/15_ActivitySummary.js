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

Ensembl.Panel.ActivitySummary = Ensembl.Panel.ContentTools.extend({

  constructor: function () {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('toolsRefreshActivitySummary', this, this.refresh);
    Ensembl.EventManager.register('toolsToggleEmptyTable', this, this.toggleEmptyTable);

    this.POLL_INTERVAL  = 10; //seconds
    this.MAX_POLLS      = -1; // no maximum
    this.pollCounter    = 0;
  },

  init: function () {

    var panel = this;

    this.base();

    this.refreshURL         = this.el.find('input[name=_refresh_url]').remove().val();
    this.ticketsDataHash    = this.el.find('input[name=_tickets_data_hash]').remove().val();

    // 'No jobs' message div
    this.elLk.noJobsMessage = this.el.find('div._no_jobs');

    // Refresh button
    this.elLk.refreshButton = this.el.find('a._tickets_refresh').on('click', function(e) {
      e.preventDefault();
      panel.clearTimer();
      panel.refresh(false, false, true);
    });

    this.elLk.refreshButtonReload = this.elLk.refreshButton.children().eq(0);
    this.elLk.refreshButtonTimer  = this.elLk.refreshButton.children().eq(1);
    this.elLk.refreshButtonText   = this.elLk.refreshButton.children().eq(2);

    // Edit icons
    this.el.find('._ticket_edit').on('click', function() {
      var ticketName = (this.href.match(/tl=([a-z0-9_-]+)/i) || []).pop();
      Ensembl.EventManager.trigger('toolsHideTicket');
      return !!ticketName && !Ensembl.EventManager.trigger('toolsEditTicket', ticketName);
    });

    // View ticket link
    this.el.find('._ticket_view').on('click', function() {
      var ticketName = (this.href.match(/tl=([a-z0-9_-]+)/i) || []).pop();
      Ensembl.EventManager.trigger('toolsToggleForm', false);
      return !!ticketName && !Ensembl.EventManager.trigger('toolsViewTicket', ticketName);
    });

    // Ticket share icon
    this.el.find('._ticket_share').each(function() {
      var share_url = $(this).find('.ticket-share-input').val();
      share_url = $('<a/>', {'href': share_url}).prop('href');
      // Create an href from <a> and get a valid url
      $(this).find('.ticket-share-input').attr('value', share_url);

      $(this).helptip({
        content: $(this).html(),
        close: function(e, ui, flag) {
          if (flag) {
            $(this).helptip('option', 'content', $(this).html()).helptip('close');
          }
        },
        open: function(e, ui) {
          ui.tooltip.find('input[type=checkbox]').on('change', { icon: $(this) }, function(e) {
            var form = $(this).parents('form').on('submit', function() { return false; });
            $.ajax({
              'url'       : form.prop('action'),
              'type'      : 'get',
              'data'      : form.serialize(),
              'dataType'  : 'json',
              'context'   : { tooltip: ui.tooltip, icon: e.data.icon },
              'success'   : function(json) {
                this.tooltip.find('._ticket_share_url').toggle(!!json.shared);
                this.icon.find('._ticket_share_url').toggle(!!json.shared).end().find('input[type=checkbox]')[json.shared ? 'attr' : 'removeAttr']('checked', 'checked'); // $.prop doesn't work as it doesn't change the raw html
              }
            });
          });
        }
      });
    });

    this.toggleEmptyTable();
    this.updateTicketList(false, !!this.el.find('input[name=_auto_refresh]').remove().val());
  },

  refresh: function (forceRefresh, resetPollCount, ignorePollCounter) {
  /*
   * Does a query to the backend to refresh the Activity Summary table
   * This get called by frontend and backend
   */
    var panel = this;

    this.pollCounter = !resetPollCount ? ignorePollCounter ? this.pollCounter : this.pollCounter + 1 : 0;

    this.toggleLoadingMessage(true);
    this.updateRefreshButton('refreshing');
    this.ajax({
      'url'     :  this.refreshURL,
      'data'    : { 'tickets': forceRefresh ? '' : this.ticketsDataHash }, // if forceRefresh flag is on, don't send the ticket data to the backend. This forces the backend to respond with current ticket data again.
      'cache'   : false,
      'spinner' : true,
      'success' : function(json, previous) {
        if (previous != 'method_applied') {
          this.updateRefreshButton('cleartimer');
          this.clearTimer();
        }
      },
      'error'   : function() {
        this.updateRefreshButton('cleartimer');
        this.clearTimer();
      },
      'complete': function() {
        this.toggleLoadingMessage(false);
      }
    });
  },

  updateRefreshButton: function(status) {
  /*
   * Updates the 'Refresh' link
   */
    var panel = this;

    this.elLk.refreshButtonReload.toggle(status === 'cleartimer');
    this.elLk.refreshButtonText.html(status === 'refreshing' ? 'Refreshing now&#8230;' : 'Refresh');

    if (status === 'refreshing') {
      this.elLk.refreshButtonTimer.hide();
    } else {
      this.elLk.refreshButtonTimer.toggle(status !== 'cleartimer');
      if (status === 'inittimer') {
        panel.elLk.refreshButtonTimer.text(this.POLL_INTERVAL);
        Ensembl.Panel.ActivitySummary.counter = setInterval(function() {
          panel.elLk.refreshButtonTimer.text(parseInt(panel.elLk.refreshButtonTimer.text()) - 1);
        }, 1000);
      }
    }
  },

  updateTicketList: function(ticketsDataHash, autoRefresh) {
  /*
   * Updates the Activity Summary table according to the request recieved from the backend
   * ticketsDataHash: only provided if changed
   */
    var panel = this;

    this.clearTimer();

    if (!!ticketsDataHash) {

      var memcacheProofURL  = this.params.updateURL;
          memcacheProofURL  = memcacheProofURL.replace(/\;?mcache\=[0-9]+/, '');
          memcacheProofURL += ';mcache=' + (new Date()).getTime();

      this.getContent(memcacheProofURL);

      Ensembl.EventManager.trigger('toolsRefreshTicket', false); // getContent for the displayed ticket details if any
    }
    this.autoRefresh = !!autoRefresh;

    if (this.autoRefresh && (this.MAX_POLLS < 0 || this.pollCounter < this.MAX_POLLS)) {
      Ensembl.Panel.ActivitySummary.poll = setTimeout(function () {
        panel.refresh(false, false, false);
      }, this.POLL_INTERVAL * 1000);

      this.updateRefreshButton('inittimer');

    } else {
      this.updateRefreshButton('cleartimer');
    }
  },

  toggleEmptyTable: function() {
  /*
   * Toggles the table according to whether it has any records in it or not
   */
    var tableWrapper  = this.el.find('div._ticket_table');
    var showTable     = !tableWrapper.find('.dataTables_empty').length;

    tableWrapper.toggle(showTable);
    this.elLk.noJobsMessage.toggle(!showTable);
    if (!showTable) {
      Ensembl.EventManager.trigger('toolsToggleForm', true, false);
    }
  },

  toggleLoadingMessage: function(flag) {
  /*
   * Toggles a message to the user when the jobs are refreshing (only when user has no existing jobs)
   */
    if (this.elLk.noJobsMessage.find('p').length === 1) {
      this.elLk.noJobsMessage.append($('<p>Loading...</p>').hide());
    }
    this.elLk.noJobsMessage.find('p').each(function(i) { $(this).toggle(i === 0 ? !flag : flag); }); // Loading message is in the second <p>
  },

  clearTimer: function() {
  /*
   * Clears the timers for polling ticket update and showing timer
   */
    clearTimeout(Ensembl.Panel.ActivitySummary.poll);
    clearInterval(Ensembl.Panel.ActivitySummary.counter);
  },

  destructor: function() {
  /*
   * Clears the timers before destroying the object
   */
    this.clearTimer();
    this.base.apply(this, arguments);
  }
});

