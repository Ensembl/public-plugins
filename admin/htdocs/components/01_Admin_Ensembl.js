Ensembl.extend({
  initialize: function () {
    this.base();

    //JS for healthcheck pages
    this.HCManager.initialize();

    //JS for changelog (TinyMCE)
    $('textarea._tinymce').livequery(function() {
      var configs = {
        script_url: '/tiny_mce/jscripts/tiny_mce/tiny_mce.js',
        theme: "advanced",
        theme_advanced_buttons1: "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect,|,cut,copy,paste,|,charmap",
        theme_advanced_buttons2: "bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,cleanup,code,|,removeformat,visualaid,|,sub,sup,",
        theme_advanced_buttons3: "",
        theme_advanced_toolbar_location: "top"
      };
      var height = this.className.match(/_tinymce_h_([0-9]+)/);
      var width  = this.className.match(/_tinymce_w_([0-9]+)/);
      if (height) {
        configs.height = height[1];
      }
      if (width) {
        configs.width = width[1];
      }
      $(this).tinymce(configs);
    });
  }
});