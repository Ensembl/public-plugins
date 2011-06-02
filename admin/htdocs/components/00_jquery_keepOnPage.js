/**
 * keepOnPage
 * A very small jQuery plugin to keep an element always on the page when page scrolled vertically
 * Not yet tested in all scenarios, but works for Ensembl Admin Healthcheck pages where required
 */

(function($) {
  
  $.keepOnPage = function (el, options) {

    el = $(el);
    
    if (!navigator.userAgent.match(/msie\s6/i)) {
    
      var defaults = {
        coords: el.offset(),
        position: el.css('position'),
        top: el.css('top')
      };
      
      el.css('width', el.css('width'));
  
      var rePosition = function () {
        el.css(defaults.coords.top - options.marginTop <= $(window).scrollTop() ? {position: 'fixed', top: options.marginTop} : {position: defaults.position, top: defaults.top});
      };
  
      $(window).bind({
        load:   rePosition,
        scroll: rePosition
      });
    }
  };
  
  $.fn.keepOnPage = function (options) {

    options = options || {};
    options.marginTop = options.marginTop || 0;
    
    this.each(function() {

      new $.keepOnPage(this, options);
    });
    
    return this;

  };
})(jQuery);



