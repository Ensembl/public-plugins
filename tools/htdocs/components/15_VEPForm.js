Ensembl.Panel.VEPForm = Ensembl.Panel.Content.extend({
  init: function () {
    this.base();
    var panel = this;
    this.elLk.vepForm = this.el.find('form.blast');
    
    this.elLk.vepForm.on('submit', function () {
      panel.elLk.vepForm.addClass('overlay_blast');
      $('input.submit_vep', panel.elLk.vepForm).addClass('disabled').prop('value', 'Processing');
      $('.vep_input', panel.elLk.vepForm).attr('disabled', 'disabled');
      $.ajax({
        url: this.action,
        data: $(this).serialize(),
        dataType: 'json',
        type: this.method,
        success: function (json) {

          Ensembl.EventManager.trigger(json.functionName, json.functionData);

          if (json.functionName === 'updateJobsList') {
            window.scrollTo(0, 0);
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
  }
});
