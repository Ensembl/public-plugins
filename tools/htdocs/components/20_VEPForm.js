Ensembl.Panel.VEPForm = Ensembl.Panel.ToolsForm.extend({
  init: function () {
    this.base();
    var panel = this;
    this.elLk.form = this.el.find('form.vep_form');
    
    this.elLk.form.on('submit', function (e) {
      e.preventDefault();
      panel.toggleSpinner(true);
      var formData = new FormData(this);
      
      panel.ajax({
        'url'       : this.action,
        'method'    : 'post',
        'data'      : formData,
        'dataType'  : 'json',
        'type': this.method,
        'cache': false,
        'processData': false,
        'contentType': false,
        'context'   : panel,
        'complete'  : function() {
          this.toggleSpinner(false);
        }
      });
    });
  }
});
