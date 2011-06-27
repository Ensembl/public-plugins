Ensembl.extend({
  initialize: function () {
    this.base();

    //JS for healthcheck pages
    this.HCManager.initialize();

    //JS for changelog (TinyMCE)
    $('textarea._tinymce').livequery(function() {
      $(this).tinymce({
        script_url: '/tiny_mce/jscripts/tiny_mce/tiny_mce.js',
        theme: "advanced",
        theme_advanced_buttons1: "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect",
        theme_advanced_buttons2: "cut,copy,paste,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,cleanup,code,|,removeformat,visualaid,|,sub,sup,|,charmap",
        theme_advanced_buttons3: "",
        theme_advanced_toolbar_location: "top"
      });
    });
  }
});