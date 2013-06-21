// Extension to initForm method of Ensembl.DbFrontend to initialise tinymce

Ensembl.DbFrontend.prototype.initFormORM = Ensembl.DbFrontend.prototype.initForm;
Ensembl.DbFrontend.prototype.initForm = function() {

  this.initFormORM();
  this.form.find('textarea._tinymce').enstinymce();

};
