// $Revision$

Ensembl.Panel.ZMenu = Ensembl.Panel.ZMenu.extend({
  buildMenuAjax: function (json) {
    this.base.apply(this, arguments)
    
    if (json.highlight) {
      if (this.relatedEl) {
        this.relatedEl.removeClass('highlight');
      }
      
      this.relatedEl = $('tr.' + json.highlight, this.el);
      this.relatedEl.addClass('highlight');
    }
  }  
}, {
  template: Ensembl.Panel.ZMenu.template
});
