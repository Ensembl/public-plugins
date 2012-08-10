Ensembl.HCManager = new Base();

Ensembl.HCManager.extend({
  initialize: function () {
    this.base();
    
    var self = this;
    
    this.constant = {
      classes:            ['hc-comment-link'],
      infoBoxClass:       '_hc_infobox',
      configDivClass:     'hc-config',
      localTools:         'tool_buttons',
      manualOkClass:      'hc-oked-link',
      notNewClass:        'hc-notnew-link',
      noFailsClass:       'hc-nofailsrow',
      failsClass:         'hc-failsrow',
      tableHeadingClass:  'hc-dbheading',
      evenOddClasses:     ['bg1', 'bg2'],
      filterTableClass:   '_filter_table',
      hilightedCell:      'hc-cell-highlight',
      isIE6:              $('body').hasClass('ie6'),
      info:               ["Double click on any 'Select' or 'Deselect' to respectively select or deselect all reports for multi-annotation."]
    };

    this.tables   = [];
    this.configs  = false;
    this.evenRow  = '';
    this.oddRow   = '';
    
    //if details page, create selectors
    for (var i in this.constant.classes) {

      $('.' + this.constant.classes[i]).each(function () {
          new HCSelector(self, $('a', this)[0]);
      });
    }
    
    //update info, checkboxes etc if selectors created if it has selectors
    if (this.tables.length) {

      this.configs = {};
      this.configs[this.constant.notNewClass] = {
        label:      ' Show new reports only',
        flag:       false,
        cookieName: 'a'
      };
      this.configs[this.constant.manualOkClass] = {
        label:      " Exclude 'manual ok' reports",
        flag:       false,
        cookieName: 'b'
      };

      var infoDiv = $('.' + this.constant.infoBoxClass).first();
      for (var i in this.constant.info) {
        infoDiv.append($(document.createElement('p')).html(this.constant.info[i]));
      }
      
      for (var i in this.tables) {
        if (this.tables[i].selectors[0]) {
          this.evenRow = this.tables[i].selectors[0].row.attr('class');
        }
        if (this.tables[i].selectors[1]) {
          this.oddRow = this.tables[i].selectors[1].row.attr('class');
          break;
        }
      }
    }
    
    //if summary page
    if ($('.' + this.constant.failsClass + ', .' + this.constant.noFailsClass).length) {
      
      this.configs = {};
      this.configs[this.constant.noFailsClass] = {
        label:      " Exclude 'no fail' rows",
        flag:       false,
        cookieName: 'c'
      };
      $('.' + this.constant.noFailsClass).parents('table').addClass(this.constant.filterTableClass);
      $('.' + this.constant.noFailsClass).parents('tr').addClass(this.constant.noFailsClass);
    }
    
    //create config checkboxes
    if (this.configs) {

      var configDiv = $(document.createElement('div'))
        .addClass(this.constant.configDivClass)
        .insertAfter($('.' + this.constant.localTools)[0])
        .keepOnPage({marginTop: 3});

      for (var i in this.configs) {
  
        this.configs[i].checkbox = $(document.createElement('input'))
          .attr({type: 'checkbox', id: i})
          .bind('change', function () {
            self.configs[this.id].flag = this.checked;
            self.updateCookie();
            self.filterRows();
          })
          .prependTo($(document.createElement('p'))
            .append($(document.createElement('label')).attr('for', i).html(this.configs[i].label))
            .appendTo(configDiv)
          );
      }
      
      this.updateFromCookie();
      this.filterRows();
    }
  },

  getTable: function (num) {

    return this.tables[num] = this.tables[num] || new HCTable(this);
  },

  changeLinks: function () {

    var tablesAffected = [];

    for (var i in this.tables) {

      if (
        this.tables[i].selectedIds === false ||  //coz a link in it has been changed
        this.tables[i].selectedIds.length > 0    //coz it has links that need to be changed
      ) {
        tablesAffected.push(this.tables[i]);
      }
    }

    var rid = [];
    for (var i in this.tables) {
      var ridTable = this.tables[i].getSelectedIds();
      if (ridTable != '') {
        rid.push(ridTable);
      }
    }
    rid = rid.join(',');
    for (var i in tablesAffected) {
      tablesAffected[i].changeLinks(rid);
    }
  },

  filterRows: function () {
    var self = this;
  
    var rowsToHide = [];
    for (var i in this.configs) {
      if (this.configs[i].flag) {
        rowsToHide.push('tr.' + i);
      }
    }

    $('table.' + this.constant.filterTableClass + ' tr').show().data('hidden', false);
    if (rowsToHide.length) {
      $(rowsToHide.join(', ')).hide().data('hidden', true);
    }
    
    $('table.' + this.constant.filterTableClass + ' tbody').each(function () {
    
      var classes = self.constant.evenOddClasses.slice(0);
      $('tr', this).each(function () {

        if (!$(this).data('hidden')) {
          classes = classes.reverse();
          $(this).removeClass(classes[0]).addClass(classes[1]);
        }
      });
    });
  },
  
  cookie: {
    data: {},

    set: function (name, value) {
      this.data[name] = value;

      var ck = [];
      for (var i in this.data) {
        ck.push(i + '-' + this.data[i]);
      }
      
      Ensembl.cookie.set('hcconfig', ck.join('.'));
    },

    get: function(name) {
      var ck = Ensembl.cookie.get('hcconfig').split('.');
      for (var i in ck) {
        if (ck[i]) {
          var val = ck[i].split('-');
          this.data[val[0]] = val[1];
        }
      }
      
      return this.data[name];
    }
  },

  updateCookie: function () {
    var j = 2;
    for (var i in this.configs) {
      this.cookie.set(this.configs[i].cookieName, this.configs[i].flag * 1); 
    }
  },

  updateFromCookie: function () {

    for (var i in this.configs) {

      this.configs[i].flag = !!parseInt(this.cookie.get(this.configs[i].cookieName));

      if (this.configs[i].checkbox) {
        this.configs[i].checkbox.attr('checked', this.configs[i].flag);
      }
    }

  }
});

function HCTable(manager) {
  var self = this;

  this.manager = manager;
  this.selectors = [];
  this.selectedIds = []; //false if any selection changed - empty array if none selected - array of ids of reports if selected
  this.table = false;

  this.add = function (selector) {

    this.selectors.push(selector);

    if (!this.table) {
      this.table = selector.row.parents('table').first().addClass(this.manager.constant.filterTableClass);
      this.table.prev('h3').append(
        $(document.createElement('a'))
          .attr('href', '#showHide')
          .html('Hide')
          .bind('click', function (e) {
            e.preventDefault();
            this.innerHTML = this.innerHTML == 'Hide' ? 'Show' : 'Hide';
            self.table.toggle();
          })
      );
    }
    
    selector.table = this;
  };

  this.changeLinks = function(rid) {
    for (var i in this.selectors) {
      this.selectors[i].changeLink(rid);
    }
  };

  this.selectAll = function(flag) {
    for (var i in this.selectors) {
      this.selectors[i].select(flag);
    }
  };
  
  this.getSelectedIds = function() {
    if (this.selectedIds === false) {
      this.selectedIds = [];
      for (var i in this.selectors) {
        if (this.selectors[i].selected) {
          this.selectedIds.push(this.selectors[i].rid);
        }
      }
    }
    return this.selectedIds.join(',');
  };
}

function HCSelector(manager, a) {
  var self = this;

  this.a = $(a);
  this.manager = manager;
  this.row = this.a.parents('tr').first().addClass(this.a.attr('class'));
  this.manager.getTable(a.rel).add(this); //link it to it's table & vice versa
  this.defaultText = a.innerHTML;
  this.selected = false;
  this.link = a.href;
  this.rid = a.href.match(/[^a-z0-9]+rid=([0-9]+)/)[1];

  this.a1 = $(document.createElement('a'))
    .html('Select')
    .attr({title: 'Select for multi-annotation', href: '#Select'})
    .appendTo(a.parentNode)
    .bind({
      click: function (e) {
        e.preventDefault();
        self.select(!self.selected); //reverse selection
        self.dblclickFlag = self.selected;
        self.table.selectedIds = false;
        self.manager.changeLinks();
      },
      dblclick: function (e) {
        e.preventDefault();
        self.table.selectAll(self.manager.constant.isIE6 ? self.dblclickFlag : !self.selected);
        self.table.selectedIds = false;
        self.manager.changeLinks();
      }
    });
  
  this.select = function(flag) {
    if (flag && !!this.row.data('hidden')) {
      return;
    }
    this.selected = flag;
    this.a1.html(flag ? 'Deselect' : 'Select');
  };

  this.changeLink = function(rid) {
    this.a.html(this.selected ? 'Multi&nbsp;Annotate' : this.defaultText).attr('href', this.selected ? this.link.replace(this.rid, rid) : this.link);
    this.highlight();
  };

  this.highlight = function() {
    $('td', this.row).attr('class', this.selected ? this.manager.constant.hilightedCell : '');
  };
}