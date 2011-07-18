/* JavaScript for DbFrontend List page
 * Script allows inline editing of the table contents
 * For any DbFrontend page using this javascript, check the following things to make if work properly:
 *  1. That the SiteDefs::OBJECT_TO_SCRIPT values for the page is 'Modal'
 *  2. Javascript classes are being added to the html elements properly
 *  3. The page which displays all the records return a single record if its 'id' is specified in GET params
 */

Ensembl.Panel.DbFrontendList = Ensembl.Panel.extend({

  init: function() {
    var self = this;
    this.base();
    this.data = [];
    
    $('table._dbf_list', this.el).each(function() {
      $('thead th', this).each(function() {
        var inps = $('input[type=hidden]', this);
        self.data.push(inps.length ? {url: inps[0].value, name: inps[0].name} : false);
      });
      $('tbody tr', this).each(function () {
        self.dbfRow(this);
      });
      return false;
    });
  },

  dbfRow: function(row) {
    var id = (row.className.match(/_dbf_row_([^\s]+)/) || []).pop();
    for (var i in this.data) {
      if (this.data[i]) {
        new Ensembl.DbFrontendListCell(row.cells[i], $.extend(this.data[i], {id: id, parent: this}));
      }
    }
  }
});

Ensembl.DbFrontendListCell = Base.extend({
  constructor: function(cell, data) {
    var self   = this;
    $.extend(this, data);

    this.el = $('<div>').html(cell.innerHTML).appendTo($(cell).empty()).append($('<span class="dbf-list-edit">').click(function() {
      if (!self.form) {
        self.createForm();
      }
      self.makeRequest(self.form, {
        url:      self.url,
        data:     {id: self.id, _ajax: 1, _list: 1},
        success:  function(json) {
          var form   = $('form', this.getResponseNode(json));
          var field  = $('[name=' + self.name + ']', form).first().parents('div').first().removeAttr('class');
          var button = $('[type=submit]', form).first().parents('div').first().attr('class', 'dbf-list-buttons');
          this.form.empty().append(form.empty().append(field, $('<div>').append(button)));
          Ensembl.EventManager.trigger('validateForms', this.form);
        }
      });
    }));
  },
  
  createForm: function() {
    var self = this;
    if (this.form) {
      return;
    }
    this.form = $('<div>').insertAfter(this.el).hide();

    // Cancel button's event
    $('._dbf_cancel', this.form).live('click', function (event) {
      event.preventDefault();
      self.el.show('fast');
      self.form.hide('fast', function() {
        this.innerHTML = '';
      });
    });

    // Submit event of the form for saving the data
    $('form._dbf_save', this.form).live('submit', function(event) {
      event.preventDefault();
      self.makeRequest(self.form, {
        url:     this.action,
        type:    'POST',
        data:    $(this).serialize() + '&id=' + self.id + '&_ajax=1',
        success: function(json) {
          if (json.redirectURL) {
            var url = window.location.href.split('#')[0];
            this.success = !json.redirectURL.match(/Problem$/);
            this.makeRequest(this.form, {
              async: false,
              url: url,
              data: {id: this.id, _ajax: 1},
              success: function(json) {
                if (this.success) {
                  var res = $('._dbf_row_' + this.id, this.getResponseNode(json));
                  if (res.length) {
                    var row = this.el.parents('tr').first();
                    var td  = $('td', res);
                    $('td', row).each(function(i) {
                      this.innerHTML = td[i].innerHTML;
                    });
                    var table = row.parents('table').first();
                    if (table.hasClass('data_table')) {
                      table.dataTable().fnUpdate(($.map(row[0].cells, function(cell) {return cell.innerHTML; })), row[0]);
                    }
                    this.parent.dbfRow(row[0]);
                  }
                }
                this.afterResponse(this.success);
              }
            });
          }
          else {
            this.showError();
          }
        }
      });
    });
  },

  makeRequest: function(target, options) {
    if (this.ajax) {
      this.ajax.abort();
      this.ajax = false;
    }
    this.el.hide();
    target.empty().html('Loading&#133;').show();
    this.ajax = $.ajax($.extend(options, {
      dataType: 'json',
      context: this || options.context,
      error: function() {
        this.showError();
      }
    }));
  },

  getResponseNode: function(json) {
    return $('._dbf_response', $(document.createElement('div')).html(json.content));
  },
  
  showError: function() {
    this.el.show();
    this.form.html('An error occoured at the server. Please try again.');
  },
  
  afterResponse: function(success) {}
});