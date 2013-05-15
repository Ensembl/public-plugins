// Extension to Content panel to initialise datastructure editor on load

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({

  init: function () {
    this.base();
    this.el.find('._datastructure').datastructure();
  }
});