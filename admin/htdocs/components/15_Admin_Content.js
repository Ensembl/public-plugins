/* Extension to Content panel
 * To use this panel, provide class name _ts_button to the buttons and _ts_tab to the tab divs inside the panel
 * along with css classes
 */

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({
  init: function() {
    this.base();
    var fnEls = {
      tabSelector: $('._tabselector', this.el)
    };
    
    $.extend(this.elLk, fnEls);
    
    for (var fn in fnEls) {
      if (fnEls[fn].length) {
        this[fn]();
      }
    }
  },
  tabSelector: function() {
    var buttons = $('._ts_button', this.elLk.tabSelector);
    var tabs    = $('._ts_tab',    this.elLk.tabSelector);
  
    buttons.each(function(i) {
      $(this).click(function(event) {
        event.preventDefault();
        $(tabs.hide()[i]).show();
        $(buttons.removeClass('selected')[i]).addClass('selected');
      });
    }).first().trigger('click');
  
    $('._ts_loading', this.elLk.tabSelector).removeClass('spinner ts-spinner');
  }
});