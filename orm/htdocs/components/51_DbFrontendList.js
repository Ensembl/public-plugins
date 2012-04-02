/* JavaScript for DbFrontend List page
 * Script allows inline editing of the table contents
 * For any DbFrontend page using this javascript, check the following things to make if work properly:
 *  1. That the SiteDefs::OBJECT_TO_SCRIPT values for the page is 'Modal'
 *  2. Javascript classes are being added to the html elements properly
 *  3. The page which displays all the records return a single record if its 'id' is specified in GET params
 */

Ensembl.DbFrontendList = {

  // Row Class
  Row: Base.extend({
    constructor: function(row, panel) {
      this.id = (row.className.match(/_dbf_row_([^\s]+)/) || []).pop();
      this.panel = panel;
      for (var i in this.panel.data) {
        if (this.panel.data[i]) {
          new Ensembl.DbFrontendList.Cell(row.cells[i], this.panel.data[i], this);
        }
        else if (row.cells[i].className.match(/_dbf_row_handle/)) {
          this.handleCell = new Ensembl.DbFrontendList.HandleCell(row.cells[i], this);
        }
      }
    }
  }),
  
  // Cell Class - extended from js base class for DbFrontend
  Cell: Ensembl.DbFrontend.extend({
  
    // @override
    constructor: function(cell, data, row) {
      var self  = this;
      this.url  = data.url;
      this.name = data.name;
      this.row  = row;
      this.el   = $('<div>').html(cell.innerHTML).appendTo($(cell).empty()).append($('<span class="dbf-list-edit" title="' + (data.type == 'relation' ? 'Choose different ' : 'Edit ') + data.title + '">').click(function() {
        self.buttonClick(this);
      }));
      $('._dbf_list_view', this.el).click(function(e) {
        e.preventDefault();
        var handle = self.row.handleCell;
        handle.initForm();
        handle.makeRequest(this, handle.form, {
          url:      this.href,
          data:     {},
          success:  function(json) {
            handle.getResponseNode(json)
              .children().wrapAll('<div class="dbf-list-view-response">').end()
              .append($('<a class="_dbf_cancel dbf-close-button" href="#Close">Close</a>'))
              .appendTo(handle.form.empty())
            ;
          }
        });
      });
    },

    // @override
    buttonClick: function(button) {
      this.initForm();
      this.makeRequest(button, this.form, {
        url:      this.url,
        data:     {id: this.row.id, _list: 1},
        success:  function(json) {
          var form   = $('form', this.getResponseNode(json));
          var field  = $('[name=' + this.name.replace('.', '\\.') + ']', form).first().parents('div').first().removeAttr('class');
          var button = $('[type=submit]', form).first().parents('div').first().attr('class', 'dbf-list-buttons');
          $('input', this.form.empty().append(form.empty().append(field, $('<div>').append(button)))).first().focus();
          this.validateForms(this.form);
        }
      });
      this.el.hide();
    },

    // @override
    showLoading: function(target, flag) {
      if (flag !== false) {
        target.empty().html('Loading&#133;').show();
      }
    },

    // @override
    cancelButtonClick: function(button) {
      this.el.show('fast');
      this.form.hide('fast', function() {
        this.innerHTML = '';
      });
    },
    
    // @override
    formSubmit: function(form) {
      this.makeRequest(form, this.form, {
        data:    $(form).serialize() + '&id=' + this.row.id,
        success: function(json) {
          if (json.redirectURL) {
            var url = json.redirectURL;
            this.success = !url.match(/Problem/);
            if (this.success) {
              url = window.location.href.split('#')[0];
              url = url + (url.match(/\?/) ? '&' : '?') + 'id=' + this.row.id;
            }
            this.makeRequest({}, this.form, {
              async: false,
              url: url,
              success: function(json) {
                if (this.success) {
                  var resTr = $('._dbf_row_' + this.row.id, this.getResponseNode(json));
                  if (resTr.length) {
                    this.row.panel.updateRow(resTr.children().map(function(i, cell) {return cell.innerHTML;}), this.el.parents('tr')[0]);
                  }
                }
                else {
                  this.showError(this.form, this.getResponseNode(json).children('p').first().html(), this.el);
                }
                this.afterResponse(this.success);
              }
            });
          }
          else {
            this.showError(this.form, '', this.el);
          }
        }
      });
    }
  }),

  // HandleCell Class - cell that contains edit, delete and duplicate link
  HandleCell: Ensembl.DbFrontendRow.extend({

    // @override
    constructor: function(cell, row) {
      this.row = row;
      this.base(cell);
    },

    // @override
    createForm: function() {
      var tr = this.el[0].parentNode;
      return $('<div>').appendTo($('<td>').appendTo($('<tr>').insertAfter(tr).attr('class', 'dbf-list-form')).attr('colspan', tr.cells.length));
    },

    // @override
    buttonClick: function(button) {
      if (this.form) {
        this.form.parents('tr').first().remove();
        this.form = false;
      }
      this.base(button);
    },

    // @override
    cancelButtonClick: function(button) {
      var previous = $(button).parents('._dbf_form_wrap').prev()[0];
      if (previous) {
        $(previous).show().next().remove();
      }
      else {
        this.form.children().first().slideUp(function() {
          $(this).parents('tr').first().remove();
        });
        this.form = false;
      }
    },

    // @override
    deleteButtonClick: function(button) {
      this.makeRequest(button, this.form, {
        success: function(json) {
          if (json.redirectURL) {
            if (json.redirectURL.match(/Problem/)) {
              this.makeRequest({}, this.form, {
                async: false,
                url: json.redirectURL,
                success: function(json) {
                  this.form.html(this.getResponseNode(json).html());
                }
              });
            }
            else {
              this.form.parents('tr').first().remove();
              this.row.panel.deleteRow(this.el.parents('tr')[0]);
              for (var i in this) {
                delete this[i];
              }
            }
          }
        }
      });
    },

    // @override
    formSubmit: function(form) {
      this.action = form.className.match(/_dbf_add/) ? 'add' : 'edit';
      this.makeRequest(form, this.form.children(':last'), {
        success: function(json) {
          if (json.redirectURL) {
            var url = json.redirectURL;
            this.success = !url.match(/Problem/);
            if (this.success) {
              var id = (url.match(/(\?|&|;)id\=([0-9]+)/) || []).pop() || 0;
              if (id) {
                url = window.location.href.split('#')[0];
                url = url + (url.match(/\?/) ? '&' : '?') + 'id=' + id;
              }
            }
            this.makeRequest({}, this.form.children(':last'), {
              async   : false,
              url     : url,
              success : function(json) {
                if (this.success) {
                  var resTr = $('._dbf_row_' + id, this.getResponseNode(json));
                  if (resTr.length) {
                    this.row.panel[this.action === 'add' ? 'addRow' : 'updateRow'](resTr.children().map(function(i, cell) {return cell.innerHTML;}), this.el.parents('tr')[0], resTr[0].className);
                  }
                  this.afterResponse(this.success);
                  this.form.parents('tr').first().remove();
                }
                else {
                  this.showError(this.form, this.getResponseNode(json).children('p').first().html());
                }
              }
            });
          }
        }
      });
    }
  })
};

// DbFrontendList Panel class
Ensembl.Panel.DbFrontendList = Ensembl.Panel.extend({

  init: function() {
    var self = this;
    this.base();
    this.data = [];
    
    $('table._dbf_list', this.el).each(function() {
      $('thead th', this).each(function() {
        var inps = $('input[type=hidden]', this);
        self.data.push(inps.length ? {url: inps[0].value, name: inps[0].name, title: $(this).text(), type: inps[0].className} : false);
      });
      $('tbody tr', this).each(function () {
        self.initRow(this);
      });
      return false;
    });
  },

  // constructs a DbFrontendList.Row object from an already existing TR element
  initRow: function(row) {
    new Ensembl.DbFrontendList.Row(row, this);
  },

  // Adds a new TR element (after a given reference TR element) and initiates it as a DbFrontendList.Row object taking in account the DataTables settings
  addRow: function(data, refRow, classes) {
    var table = $(refRow).parents('table').first();
    var row   = false;
    if (table.hasClass('data_table')) {
      table = table.dataTable();
      row = table.fnGetNodes(table.fnAddData(data));
      $(row).addClass(classes.replace(/bg(1|2)/, ''));
    }
    else {
      row = $('<tr>').attr('class', classes).append($.map(data, function(html) { return $('<td>').html(html)[0]; })).insertAfter(refRow)[0];
      this.setRowBGs();
    }
    if (row) {
      $(row.cells).each(function(i) {this.className = refRow.cells[i].className});
      new Ensembl.DbFrontendList.Row(row, this);
      this.highlightRow(row);
    }
  },

  // Update an already existing TR element with given data and re-initiates it as DbFrontendList.Row taking in account the DataTables settings
  updateRow: function(data, row) {
    $(row.cells).each(function(i) {this.innerHTML = data[i]});
    var table = $(row).parents('table').first();
    if (table.hasClass('data_table')) {
      table.dataTable().fnUpdate($.map(row.cells, function(cell) {return cell.innerHTML; }), row);
    }
    new Ensembl.DbFrontendList.Row(row, this);
    this.highlightRow(row);
  },

  // Removes a TR element from the table, taking in account the DataTables settings
  deleteRow: function(row) {
    var table = $(row).parents('table').first();
    if (table.hasClass('data_table')) {
      table.dataTable().fnDeleteRow(row);
    }
    else {
      $(row).remove();
      this.setRowBGs();
    }
  },

  // Maintains the even-odd backgroundColor order of the TR elements
  setRowBGs: function() {
    var bg = ['bg1', 'bg2'];
    $('table._dbf_list', this.el).each(function() {
      $('tbody tr', this).each(function() {
        if (this.className.match(/_dbf_row_/)) {
          $(this).removeClass('bg1 bg2').addClass(bg[0]);
          bg = bg.reverse();
        }
      });
    });
  },

  // Highlights a row for 1 second
  highlightRow: function(row) {
    $(row).effect('highlight', {'color': '#ddddff'}, 1000);
  }
});