Ensembl.extend({
  initialize: function () {
    this.base();
    new HC_MultiSelector(['hc-comment-link'], 'hc-infobox', 'hc-problem-link', 'hc-new-link', 'hc-dbheading');
  }
});

function HC_MultiSelector(classes, infoClass, problemClass, newClass, tableHeadingClass) {

  this.tables = Array();
  this.info = ["Double click on any 'Select' or 'Deselect' to respectively select or deselect all annotations for that database for multi-annotation."];
  this.configs = Array();
  this.showNewOnly = false;
  this.hideManualOK = false;
  this.evenRow = '';
  this.oddRow = '';
  this.getTable = function(num) {
    if (this.tables[num] === undefined)
    this.tables[num] = new HC_Table(this);
    return this.tables[num];
  }
  
  //init
  for (var i in classes) {
    var p = $('.' + classes[i]).get();//get array of DOM elements (<p>) from jquery object - getElementsByClassName substitute
    for (var j = 0; j < p.length; j++) {
      new HC_Selector(this, p[j].getElementsByTagName('a')[0]);
    }
  }
  if (this.tables.length) { //add information in infobox
    try {
      var infoDiv = $('.' + infoClass).get()[0];
      for (var i in this.info) {
        var p = document.createElement('p');
        p.innerHTML = this.info[i];
        infoDiv.appendChild(p);
      }
      for (var i = 0; i < 2; i++) this.configs.push(document.createElement('input'));
      var labels = Array();
      var labelCaptions = [' Show new reports only', " Exclude 'manual ok' reports"];
      for (var i in this.configs) labels.push(document.createElement('label'));
      this.configs[0].type = this.configs[1].type = 'checkbox';
      this.configs[0].id   = 'hc-show-reports-all';
      this.configs[1].id   = 'hc-exclude-ok';
      var configDiv        = document.createElement('div');
      for (var i in this.configs) {
        var p = document.createElement('p');
        p.appendChild(this.configs[i]);
        p.appendChild(labels[i]);
        labels[i].setAttribute('for', this.configs[i].id);
        labels[i].innerHTML = labelCaptions[i];
        configDiv.appendChild(p);
      }
      infoDiv.parentNode.insertBefore(configDiv, infoDiv.nextSibling);
      configDiv.className = infoDiv.className;
    }
    catch (e) {}
    for (var i in this.tables) {
      if (this.tables[i].selectors[0]) {
        this.evenRow = this.tables[i].selectors[0].row.className;
      }
      if (this.tables[i].selectors[1]) {
        this.oddRow = this.tables[i].selectors[1].row.className;
        break;
      }
    }
  }
  var self = this;
  if (this.configs && this.configs.length == 2) {
    this.configs[0].onchange = function() {
      self.showNewOnly = this.checked;
      self.filterRows();
    };
    this.configs[1].onchange = function() {
      self.hideManualOK = this.checked;
      self.filterRows();
    };
  }
  this.changeLinks = function() {
    var tablesAffected =Array();
    for (var i in this.tables) {
      if (
        this.tables[i].selectedIds === false ||  //coz a link in it has been changed
        this.tables[i].selectedIds.length > 0    //coz it has links that need to be changed
      ) tablesAffected.push(this.tables[i]);
    }
    var rid = Array();
    for (var i in this.tables) {
      var ridTable = this.tables[i].getSelectedIds();
      if (ridTable != '') rid.push(ridTable);
    }
    rid = rid.join(',');
    for (var i in tablesAffected) {
      tablesAffected[i].changeLinks(rid);
    }
  };
  this.filterRows = function() {
    var i = 0;
    var A = this.showNewOnly;
    var B = this.hideManualOK;
    for (var j in this.tables) {
      for (var k in this.tables[j].selectors) {
        var C = !!this.tables[j].selectors[k].a.className.match(newClass);
        var D = !!this.tables[j].selectors[k].a.className.match(problemClass);
        var condition = !A&&!B || C&&D || !A&&D || !B&&C; //karnaugh's map
        this.tables[j].selectors[k].row.style.display = condition ? '' : 'none';
        this.tables[j].selectors[k].active = condition;
        if (condition) this.tables[j].selectors[k].row.className = i++ % 2 ? this.oddRow : this.evenRow;
      }
    }
  };
}
function HC_Table(base) {
  this.base = base;
  this.selectors = Array();
  this.selectedIds = Array(); //false if any selection changed - empty array if none selected - array of ids of reports if selected
  this.table = false;
  this.add = function(selector) {
    this.selectors.push(selector);
    if (!this.table) {
      this.table = selector.row;
      while(this.table.nodeName.toLowerCase() != 'table')
        this.table = this.table.parentNode;
      var heading = this.table.previousSibling;
      while (heading.nodeName.toLowerCase() != 'h3') {
        if (!heading.previousSibling) {
          heading = false;
          break;
        }
        heading = heading.previousSibling;
      }
      if (heading) {
        var showHide = document.createElement('a');
        showHide.href = '#showHide';
        showHide.innerHTML = 'Hide';
        heading.appendChild(showHide);
        var parent = this;
        showHide.onclick = function() {
          parent.table.style.display = this.innerHTML == 'Hide' ? 'none' : '';
          this.innerHTML = this.innerHTML == 'Hide' ? 'Show' : 'Hide';
          return false;
        }
      }
    }
    selector.table = this;
  };
  this.changeLinks = function(rid) {
    for (var i in this.selectors)
      this.selectors[i].changeLink(rid);
  };
  this.selectAll = function(flag) {
    for (var i in this.selectors)
      this.selectors[i].select(flag);
  };
  this.getSelectedIds = function() {
    if (this.selectedIds === false) {
      this.selectedIds = Array();
      for (var i in this.selectors)
        if (this.selectors[i].selected)
          this.selectedIds.push(this.selectors[i].rid);
    }
    return this.selectedIds.join(',');
  };
  this.showReports = function(flag, className) {
    var evenRow = this.selectors[0].rowCSS;
    var oddRow  = this.selectors[1].rowCSS;
    var j = 0;
    for (var i in this.selectors) {
      if (className === undefined || this.selectors[i].a.className.match(className)) {
        this.selectors[i].row.style.display = flag ? '' : 'none';
        this.selectors[i].active = flag;
      }
      if (this.selectors[i].active) this.selectors[i].row.className = j++ % 2 ? oddRow : evenRow;
    }
  };
}
function HC_Selector(base, a) {
  this.a = a;
  this.base = base;
  this.row = this.a;
  while (this.row.nodeName.toLowerCase() != 'tr')
    this.row = this.row.parentNode;
  this.base.getTable(this.a.rel).add(this); //link it to it's table
  this.active = true;
  this.defaultText = this.a.innerHTML;
  this.defaultLink = this.a.href;
  this.selected = false;
  this.link = this.a.href.split('=')[0];
  this.rid = parseInt(this.a.href.split('=')[1]);
  this.a1 = document.createElement('a');
  this.a1.innerHTML = 'Select';
  this.a1.title = 'Select for multi-annotation';
  this.a1.href = '#Select';
  this.a.parentNode.appendChild(this.a1);
  var self = this;
  this.a1.onclick = function() {
    self.select(!self.selected);//reverse selection
    self.table.selectedIds = false;
    self.base.changeLinks();
    return false;
  }
  this.a1.ondblclick = function() {
    self.table.selectAll(!self.selected);
    self.table.selectedIds = false;
    self.base.changeLinks();
    return false;
  }
  this.select = function(flag) {
    if (flag && !this.active) return;
    this.selected = flag;
    this.a1.innerHTML = flag ? 'Deselect' : 'Select';
  }
  this.changeLink = function(rid) {
    this.a.innerHTML = this.selected ? 'Multi Annotate' : this.defaultText;
    this.a.href = this.selected ? this.link + '=' + rid : this.defaultLink;
    this.highlight();
  }
  this.highlight = function() {
    if (!this.tds) this.tds = this.row.getElementsByTagName('td');
    for (var i = 0; i < this.tds.length; i++)
    this.tds[i].className = this.selected ? 'hc-cell-highlight' : '';
  }
}