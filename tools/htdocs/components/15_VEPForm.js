Ensembl.Panel.VEPForm = Ensembl.Panel.Content.extend({
  constructor: function () {
    this.base.apply(this, arguments);
    Ensembl.EventManager.register('indicateInputError', this, this.indicateInputError);
  },

  init: function () {
    this.base();
    var panel = this;
    this.elLk.vepForm = this.el.find('form.blast');
    
    this.elLk.vepForm.on('submit', function () {
      panel.elLk.vepForm.addClass('overlay_blast');
      $('input.submit_vep', panel.elLk.vepForm).addClass('disabled').prop('value', 'Processing');
      $('.vep_input', panel.elLk.vepForm).attr('disabled', 'disabled');
      
      // make FormData to allow file upload to go through AJAX
      var formData = new FormData(this);
      
      $.ajax({
        url: this.action,
        data: formData,
        dataType: 'json',
        type: this.method,
        cache: false,
        processData: false,
        contentType: false,
        success: function (json) {

          Ensembl.EventManager.trigger(json.functionName, json.functionData);

          if (json.functionName === 'updateJobsList') {
            window.scrollTo(0, 0);
            $('.failed').removeClass('failed');
            panel.elLk.vepForm[0].reset();
          }
          panel.elLk.vepForm.removeClass('overlay_blast');
          $('input.submit_vep', panel.elLk.vepForm).removeClass('disabled').prop('value', 'Run');
          $('.vep_input', panel.elLk.blastform).removeAttr('disabled');
          Ensembl.replaceTimestamp(window.location.href);
        }
      });
      return false;
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
  }
});
