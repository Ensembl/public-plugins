Ensembl.Panel.VEPForm = Ensembl.Panel.Content.extend({
  constructor: function () {
    this.base.apply(this, arguments);
    Ensembl.EventManager.register('indicateInputError', this, this.indicateInputError);
  },

  init: function () {
    this.base();
    var panel = this;
    this.elLk.vepForm = this.el.find('form.blast_form');
    
    this.elLk.vepForm.on('submit', function (e) {
      e.preventDefault();
      var formData = new FormData(this);
      
      panel.showBusy(true);
      
      $.ajax({
        'url'       : this.action,
        'method'    : 'post',
        'data'      : formData,
        'dataType'  : 'json',
        'type': this.method,
        'cache': false,
        'processData': false,
        'contentType': false,
        'context'   : panel,
        'success'   : function(json) {
          console.log(json);
          this.showBusy(false);
        }
      });
    });
    
    $('.select_on_focus').on('click', function() { $(this).select(); });
  },

  indicateInputError: function (errors) {
    var panel = this;
    panel.elLk.vepForm.addClass('check');

    var display_errors = { rules: {}, message: {} };
    
    $('.failed').removeClass('failed valid');

    var failed = $.map(errors, function (message, error_class) {
      var tmp_errors = { rules: {}, messages: {} };
      tmp_errors.rules[error_class] = function (val) {
        return !this.inputs.filter('._' + error_class).hasClass('failed');
      };
      tmp_errors.messages[error_class] = message;
      $.extend(true, display_errors, tmp_errors);
      $("." + error_class +":last", panel.elLk.vepForm).parent().parent().prop('title', '<span style="color: red; font-weight: bold;">ERROR: </span>' + message).addClass('_' + error_class + ' failed _ht').helptip();
      return;
    });

    panel.elLk.vepForm.validate( display_errors, 'showError');
    $.each(failed, function () { this.removeClass('failed valid'); });
    failed = null;
  },

  showBusy: function(flag) {
    if (!this.elLk.busyDiv) {
      var offset = this.elLk.vepForm.offset();
      this.elLk.busyDiv = $('<div class="form-overlay">').css({'left': offset.left, 'top': offset.top, 'height': this.elLk.vepForm.height(), 'width': this.elLk.vepForm.width()}).appendTo(document.body);
      this.elLk.spinnerDiv = this.elLk.busyDiv.clone().prop('className', 'form-spinner spinner').appendTo(document.body);
    }
    this.elLk.busyDiv.toggle(flag);
    this.elLk.spinnerDiv.toggle(flag);
  }
});
