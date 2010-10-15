Ensembl.extend({
  initialize: function () {
    this.base();
   
    $('head').append('<style type="text/css" media="all">.mceLayout td { width: auto !important }</style>');

    $('textarea[name=content]').tinymce({
      script_url: '/tiny_mce/jscripts/tiny_mce/tiny_mce.js',
      theme: "advanced",
      theme_advanced_buttons1: "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect",
      theme_advanced_buttons2: "cut,copy,paste,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,cleanup,code,|,removeformat,visualaid,|,sub,sup,|,charmap",
      theme_advanced_buttons3: "",
      theme_advanced_toolbar_location: "top"
    });
  }
});
