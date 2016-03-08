Ensembl.Panel.SearchBox = Ensembl.Panel.SearchBox.extend({

  init: function () {
    this.base();
    var se_q = $('input#se_q,input#q',this.el);
    if(!se_q.parents('form').hasClass('no-ac')) {
      se_q.searchac().parents('form').submit(function() {
        if(se_q.val().substring(0,2) === '!!') {
          var q = se_q.val().substring(2);
          window.solr_jump_to(q); /* Hack, :-(. Pull that code in here. */
          return false;
        }
        return true;
      });
    }
  }
});
