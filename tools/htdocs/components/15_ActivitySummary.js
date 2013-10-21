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
    this.deleteURL          = this.el.find('input[name=_delete_url]').remove().val();
    this.ticketsData        = this.el.find('input[name=_tickets_data]').remove().val();
    this.pollCounter        = 0;

    this.elLk.countdownDiv  = this.el.find('div._countdown');
    this.elLk.deleteLinks   = this.el.find('._ticket_delete').on('click', function() {
      var ticketName = ($(this).parents('tr').first().prop('className').match(/_ticket_([^\s]+)/) || []).pop();
      if (ticketName) {
        if (window.confirm("This will delete ticket '" + ticketName + "' permanently.")) {
          panel.ajax({ 'url': panel.deleteURL.replace('TICKET_NAME', ticketName) });
        }
      }
    });

    this.refresh(true);

  },

  refresh: function (delayed) {
  /*
   * Does a query to the backend to refresh the Activity Summary table
   */
    var panel = this;

    if (!delayed) {
      this.updateCountdown('refreshing');
      this.ajax({ 'url': this.refreshURL });
    }

    this.clearTimers();

    if (this.pollCounter < this.MAXIMUM_POLLS) {
      this.poll = setTimeout(function () {
        panel.pollCounter++;
        panel.refresh();
      }, this.POLL_INTERVAL * 1000);

      this.countdown  = setInterval(function () {
        panel.updateCountdown('refreshing_in', panel.POLL_INTERVAL - ++panel.timePassed);
      }, 1000);
    } else {
      this.countdown  = setInterval(function () {
        panel.updateCountdown('refreshed', ++panel.timePassed);
      }, 1000);
    }
  },

  ajaxSuccess: function(json) {
  /*
   * If invalid JSON response is received, clear the timers
   */
    if (this.base(json) != 'method_applied') {
      this.updateCountdown('refresh_now');
      this.clearTimers();
    }
  },

  ajaxError: function() {
  /*
   * Clear the timers for any error while ajax request
   */
    this.base.apply(this, arguments);
    this.updateCountdown('refresh_now');
    this.clearTimers();
  },

  updateCountdown: function(type, time) {
  /*
   * Updates the 'Refresh' link
   */
    var panel =  this;

    if (this.elLk.countdownDiv.is(':empty')) {
      this.elLk.countdownDiv.on({
        'click': function (event) {
          event.preventDefault();
          panel.refresh();
        }
      });
    }

    if (type == 'refreshing') {
      this.elLk.countdownDiv.html('<p>Refreshing now&#8230;</p>');
    } else {
      var message;
      if (type == 'refreshing_in') {
        message   = 'Refreshing in ' + time + ' second' + (time === 1 ? '' : 's');
      } else if (type == 'refreshed') {
        var unit  = time > 60 ? time > 3600 ? time > 86400 ? 'day' : 'hour' : 'minute' : 'second';
        time      = parseInt(time > 60 ? time > 3600 ? time > 86400 ? time / 86400 : time / 3600 : time / 60 : time);
        time      = time === 1 ? unit === 'hour' ? 'an' : 'a' : time;
        message   = 'Refreshed ' + (unit === 'second' ? '' : 'more than ') + time + ' ' + unit + (typeof time === 'number' ? 's' : '') + ' ago';
      } else {
        message   = 'Refresh now';
      }
      this.elLk.countdownDiv.html('<p><a class="tickets-refresh" href="#"><span class="tickets-refresh-now">Refresh now</span></a></p>').find('a').prepend($('<span>').html(message));
    }
  },

  updateTicketList: function(ticketsData) {
  /*
   * Updates the Activity Summary table according to the request recieved from the backend
   */
    if (ticketsData !== this.ticketsData) {
      this.ticketsData = ticketsData;
      this.getContent();
    }
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

