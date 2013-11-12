Ensembl.Panel.ActivitySummary = Ensembl.Panel.ContentTools.extend({

  constructor: function () {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('refreshActivitySummary', this, this.refresh);

    this.MAXIMUM_POLLS  = 10;
    this.POLL_INTERVAL  = 30; //seconds
  },

  init: function () {

    var panel = this;

    this.base();

    this.refreshURL         = this.el.find('input[name=_refresh_url]').remove().val();
    this.ticketsData        = this.el.find('input[name=_tickets_data]').remove().val();
    this.pollCounter        = 0;

    this.elLk.countdownDiv  = this.el.find('div._countdown');

    // Save icons
    this.el.find('._ticket_save').on('click', function(e) {
      e.preventDefault();
      panel.ajax({ 'url': this.href });
    });

    // Delete icons
    this.el.find('._ticket_delete').on('click', function(e) {
      e.preventDefault();
      var ticketName = (this.href.match(/tl=([a-z0-9_]+)/i) || []).pop();
      if (ticketName && window.confirm("This will delete ticket '" + ticketName + "' permanently.")) {
        panel.ajax({ 'url': this.href });
      }
    });

    // Edit icons
    this.el.find('._ticket_edit').on('click', function() {
      var ticketName = (this.href.match(/tl=([a-z0-9_]+)/i) || []).pop();
      return !!ticketName && !Ensembl.EventManager.trigger('editToolsTicket', ticketName);
    });

    this.toggleEmptyTable();
    this.updateTicketList(false, !!this.el.find('input[name=_auto_refresh]').remove().val());
  },

  refresh: function (forceRefresh) {
  /*
   * Does a query to the backend to refresh the Activity Summary table
   */
    var panel = this;

    this.updateCountdown('refreshing_in', 0);
    this.ajax({
      'url'     :  this.refreshURL,
      'data'    : { 'tickets': forceRefresh ? '' : this.ticketsData }, // if forceRefresh flag is on, don't send the ticket data to the backend. This forces the backend to respond with current ticket data again.
      'type'    : 'post',
      'success' : function(json, previous) {
        if (previous != 'method_applied') {
          this.updateCountdown('refresh_now');
         this.clearTimers();
        }
      },
      'error'   : function() {
        this.updateCountdown('refresh_now');
        this.clearTimers();
      }
    });
  },

  updateCountdown: function(type, time) {
  /*
   * Updates the 'Refresh' link
   */
    var panel =  this;

    if (this.elLk.countdownDiv.is(':empty')) {
      this.elLk.countdownDiv.on('click', 'a', function (event) {
        event.preventDefault();
        panel.clearTimers();
        panel.refresh();
      });
    }

    if (type == 'refreshing_in' && !time) {
      this.elLk.countdownDiv.html('<p>Refreshing now&#8230;</p>');
    } else {
      var message;
      if (type == 'refreshing_in') {
        message   = 'Refreshing in ' + time + ' second' + (time === 1 ? '' : 's');
      } else if (type == 'refreshed') {
        var unit  = time > 60 ? time > 3600 ? time > 86400 ? 'day' : 'hour' : 'minute' : 'second';
        time      = parseInt(time > 60 ? time > 3600 ? time > 86400 ? time / 86400 : time / 3600 : time / 60 : time);
        time      = time === 1 ? unit === 'hour' ? 'an' : 'a' : time;
        message   = 'Refreshed ' + (unit === 'second' ? 'few seconds ago' : ('more than ' + time + ' ' + unit + (typeof time === 'number' ? 's' : '') + ' ago'));
      } else {
        message   = 'Refresh now';
      }
      this.elLk.countdownDiv.html('<p><a class="tickets-refresh" href="#"><span class="tickets-refresh-now">Refresh now</span></a></p>').find('a').prepend($('<span>').html(message));
    }
  },

  updateTicketList: function(ticketsData, autoRefresh) {
  /*
   * Updates the Activity Summary table according to the request recieved from the backend
   * ticketsData: only provided if changed
   */
    var panel = this;

    this.clearTimers();

    if (!!ticketsData) {
      this.ticketsData = ticketsData;
      this.getContent();
    }
    this.autoRefresh = !!autoRefresh;

    if (this.autoRefresh && this.pollCounter < this.MAXIMUM_POLLS) {
      this.poll = setTimeout(function () {
        panel.pollCounter++;
        panel.refresh();
      }, this.POLL_INTERVAL * 1000);

      this.countdown  = setInterval(function () {
        panel.updateCountdown('refreshing_in', panel.POLL_INTERVAL - ++panel.timePassed);
      }, 1000);
    } else if (this.autoRefresh) {
      this.countdown  = setInterval(function () {
        panel.updateCountdown('refreshed', ++panel.timePassed);
      }, 1000);
    } else {
      this.pollCounter = 0;
      this.updateCountdown('refresh_now');
    }
  },

  toggleEmptyTable: function() {
  /*
   * Toggles the table according to whether it has any records in it or not
   */
    var tableWrapper  = this.el.find('div._ticket_table');
    var showTable     = !tableWrapper.find('.dataTables_empty').length;
    
    tableWrapper.toggle(showTable);
    this.el.find('p._no_jobs').toggle(!showTable);
  },

  clearTimers: function() {
  /*
   * Clears the timers for polling ticket update and showing countdown
   */
    this.timePassed = 0;
    clearTimeout(this.poll);
    clearInterval(this.countdown);
  },

  destructor: function() {
  /*
   * Clears the timers before destroying the object
   */
    this.clearTimers();
    this.base();
  }
});

