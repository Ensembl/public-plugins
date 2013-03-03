Ensembl.Panel.Jobs = Ensembl.Panel.Content.extend({
  constructor: function () { 
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('updateJobsList', this, this.updateJobsList);
  },  

  init: function () {
    this.base();
    var panel = this; 
    $('div.dataTables_export', this.el).hide();
    this.elLk.jobsTable = $('table#job_status', this.el);
    this.elLk.tableWrapper = $('div.dataTables_wrapper');

    $('tbody tr td.remove', this.elLk.jobsTable).bind('click', function () {
      panel.removeJob( $(this).closest("tr").attr("id") );
    });
    

    this.interval = 30000; // time in milliseconds
    this.polled   = 0;
    this.count = 0;

    //if there are rows: this.updateJobsList();
    if ($('td.dataTables_empty').length ){       
      this.elLk.tableWrapper.hide();
      $('p.no_jobs').show();  
    } else {
      if (panel.incompleteTickets()){
        this.updateJobsList();
      }
      this.elLk.tableWrapper.show();
      $('p.no_jobs').hide();
    }

  },

  updateJobsList: function (force) {
    var panel = this;

    clearInterval(this.poll);
    clearInterval(this.countdown);
    
    if (force) {
      this.getContent();
      panel.interval = 30000;
      panel.count = 0;
      return;
    }

    this.poll = setInterval(function () {
      if (panel.polled === 10) {
        panel.updateJobsList();
        panel.interval *= 2;
        panel.polled = 0;
      } else {
        panel.getUpdatedContent();
        panel.polled++;
      }
      panel.count = 0;
    }, this.interval);

    this.countdown = setInterval(function () {
      var counter = (panel.interval /1000) - panel.count;
      $('div.countdown').html("Your results will be updated in " + counter + " seconds");
      panel.count++; 
    }, 1000);
  }, 

  getUpdatedContent: function () {
    var panel = this;
    var incompleteTicketIDs = panel.incompleteTickets();      

    if (incompleteTicketIDs) { 
      panel.updateStatus( incompleteTicketIDs );
    } 
  },

  incompleteTickets: function () {
    var panel = this;
    var incompleteTicketIDs = [];

    this.elLk.jobsTable.find('tr.incomplete').each(function () {
      incompleteTicketIDs.push( $(this).attr('id') );
    });

    if (incompleteTicketIDs.length > 0) {
      return incompleteTicketIDs;
    } else {
      clearInterval(this.poll);
      clearInterval(this.countdown);
      $('div.countdown').html('');  
    }
  },

  updateStatus: function (ticket_ids) {
    var panel = this;
    var url   = Ensembl.speciesPath + "/Ajax/jobstatus";

    $.ajax({
      url: url,
      traditional: true,
      data: { ticket: ticket_ids},
      dataType: 'json',
      success: function (json) {
        $.each(json, function(key, options) {
          panel.elLk.jobsTable.find("tbody tr#" + key  + " td.status").each( function() {
            if ( $(this).html() != options ) {
              $(this).text(options); 
              if (options === 'Completed') {  
                $(this).css('font-weight', 'bold' );
                $("a").removeClass('hidelink');
                $(this).closest("tr").removeClass('incomplete');    
              } else if (options === 'Failed'){
                $(this).closest("tr").removeClass('incomplete');
                $(this).css('font-weight', 'bold' );
                $(this).next().find('img').attr({ src: '/i/16/alert.png', title: 'Display reason for failure', alt:'Display reason for failure' });
                $(this).next().find("a").removeClass('hidelink');
                $("td.save").find("a").removeClass('hidelink');       
                $("td.remove").find("a").removeClass('hidelink');
             }   
            }
          });
        });  
        panel.incompleteTickets();  
      }
    });  
  },

  removeJob: function (ticket_id) {
    var panel = this;
    var url = Ensembl.speciesPath + "/Ajax/deletejob";

    $.ajax({
      url : url,
      data: { ticket: ticket_id},
      dataType: 'json',
      success: function (json) {
        panel.elLk.jobsTable.dataTable().fnDeleteRow($('#' + ticket_id )[0]);
        if ($('td.dataTables_empty').length){
          clearInterval(panel.poll);          
          clearInterval(panel.countdown);
        }
      }
    });
  }


});

