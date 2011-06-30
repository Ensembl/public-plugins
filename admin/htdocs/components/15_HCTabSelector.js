Ensembl.Panel.HCTabSelector = Ensembl.Panel.extend({
  init: function() {
    this.base();

    var buttons = $(this.el.childNodes[1]).children();
    var tabs    = $(this.el.childNodes[2]).children();

    buttons.each(function(i) {
      $(this).click(function(event) {
        event.preventDefault();
        $(tabs.hide()[i]).show();
        $(buttons.removeClass('selected')[i]).addClass('selected');
      });
    }).first().trigger('click');
  }
});