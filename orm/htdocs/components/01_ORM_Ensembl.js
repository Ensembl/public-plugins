Ensembl.extend({
  initialize: function () {
    this.base();

    $('._datastructure').livequery(function() {
      $(this).datastructure();
    });
  }
});