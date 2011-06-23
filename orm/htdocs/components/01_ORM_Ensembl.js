Ensembl.extend({
  initialize: function () {
    this.base();

    $('textarea._datastructure').livequery(function() {
      $(this).datastructure();
    });
  }
});