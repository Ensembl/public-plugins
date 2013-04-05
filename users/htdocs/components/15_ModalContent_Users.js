// Extension to the core ModalContent.js to add a confirm dialogue to the links with class '_jconfirm'

Ensembl.Panel.ModalContent = Ensembl.Panel.ModalContent.extend({
  initialize: function () {
    var panel = this;
    this.base();
    
    this.el.find('a._jconfirm').on('click', function() {
      var link = $(this);
      return !link.next().hasClass('_jconfirm') || window.confirm(link.next().html());
    });
    
    this.el.find('input._jcancel').on('click', function(e) {
      var redirectURL = $(this.form).find('input[name=_jcancel]').val();
      if (redirectURL) {
        Ensembl.EventManager.trigger('modalOpen', { href: redirectURL, rel: '' });
      }
    });
  }
});