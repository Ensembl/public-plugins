Ensembl.Panel.OpenIDButtons = Ensembl.Panel.extend({
  init: function() {
    this.base();
    var panel = this;

    var closePopup = function() {
      panel.usernamePopup.hide();
      $(document).off('click', closePopup);
    };

    this.el.find('a._openid_username').on({
      click: function(event) {
        event.preventDefault();
        event.stopPropagation();
        var link = $(this);
        if (!link.data('popup')) {
          link.data('popup', link.next().appendTo(document.body));
        }
        panel.usernamePopup = link.data('popup').css({left: event.pageX + 'px', top: event.pageY + 'px'}).show().find('input[type=text]').focus().end();
        $(document).on('click', closePopup);
      }
    });
    this.el.find('div._openid_username').on({
      click: function(event) {
        event.stopPropagation();
      }
    });
  }
});