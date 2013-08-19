/* Wrapper around tinymce to provide default values */

(function($) {
  
  $.enstinymce = function (el) {

    el = $(el);
    var height = el[0].className.match(/_tinymce_h_([0-9]+)/);
    var width  = el[0].className.match(/_tinymce_w_([0-9]+)/);
    el.tinymce({
      script_url: '/tiny_mce/jscripts/tiny_mce/tiny_mce.js',
      theme: "advanced",
      theme_advanced_buttons1: "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect,|,cut,copy,paste,|,charmap",
      theme_advanced_buttons2: "bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,cleanup,code,|,removeformat,visualaid,|,sub,sup,",
      theme_advanced_buttons3: "",
      theme_advanced_toolbar_location: "top",
      height: height ? height[1] : 300,
      width: width ? width[1] : 500,
      relative_urls: false,
      convert_urls: false
    });
  };
  
  $.fn.enstinymce = function () {

    this.each(function() {
      $.enstinymce(this);
    });
    
    return this;

  };
})(jQuery);
