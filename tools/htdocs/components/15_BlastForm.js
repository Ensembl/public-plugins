Ensembl.Panel.BlastForm = Ensembl.Panel.Content.extend({
  constructor: function () {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('indicateInputError', this, this.indicateInputError);
  },

  init: function () {
        
    this.base();
    var panel = this;
    this.elLk.blastForm = $('form.blast', this.el);
    this.elLk.query     = $('input.query', this.elLk.blastForm);
    this.elLk.db_type   = $('input.db_type', this.elLk.blastForm);
    this.elLk.db_name   = $('select[name="db_name"]', this.elLk.blastForm);
    this.elLk.method    = $('select[name="blastmethod"]', this.elLk.blastForm);
    this.elLk.species   = $('select[name="species"]', this.elLk.blastForm);    
    this.elLk.queryloc  = $('input.config_query_loc', this.elLk.blastForm);

    this.queryLabel = this.elLk.queryloc[0].defaultValue;        

    this.updateOptions(); 

    this.elLk.blastForm.on('submit', function () {

      panel.elLk.blastForm.addClass('overlay_blast');
      $('input.submit_blast', panel.elLk.blastForm).addClass('disabled').prop('value', 'Processing');
      $('.blast_input', panel.elLk.blastForm).attr('disabled', 'disabled');
      $.ajax({
        url: this.action,
        data: $(this).serialize(),
        dataType: 'json',
        type: this.method,
        success: function (json) { 

          Ensembl.EventManager.trigger(json.functionName, json.functionData);

          if (json.functionName === 'updateJobsList') {
            window.scrollTo(0, 0);
            panel.elLk.blastForm[0].reset();
          }
          panel.elLk.blastForm.removeClass('overlay_blast');
          $('input.submit_blast', panel.elLk.blastForm).prop('value', 'Processing');
          $('.blast_input', panel.elLk.blastform).removeAttr('disabled');
        }
      });

      return false;
    });

    $('textarea', this.elLk.blastForm).bind('change', function () {
      panel.sequenceType($(this).val());
      panel.updateOptions();  
    });

    $('input:radio, select', this.elLk.blastForm).bind('change', function () {
      panel.updateOptions();
    });

    this.elLk.method.on('change', function () {
      panel.updateConfiguration();
    });

    this.elLk.queryloc.on({
      focus: function () {
        if (panel.queryLabel === this.value){
          $(this).removeClass('inactive').val('');
        }
      },
      blur: function () {
        if (!this.value){
          $(this).addClass('inactive').val(panel.queryLabel);
        }
      }
    });

    $('input.config_ungapped', this.elLk.blastForm).bind('change', function () {
      if ($('select.config_comp_based_stats', panel.elLk.blastform).attr('disabled')){
        $('select.config_comp_based_stats', panel.elLk.blastform).removeAttr('disabled');
      }
      else $('select.config_comp_based_stats', panel.elLk.blastform).attr('disabled', 'disabled');
    })

    $('a.toggle', this.elLk.blastForm).bind('click', function () {
      $('a.toggle', panel.elLk.blastForm).css({ "border-bottom-width" : $('fieldset.config', panel.elLk.blastForm).css("display") === 'none' ? '2px' : '0px'  });
    });

  },

  sequenceType: function (sequence) {
    
    var bases = 'ACTGNX';
    var dna_threshold = 85;
    var seqLength = 1000;
    var count = 0;
    var letters = 0;
    var query_type = this.elLk.query.val();
    var base_found, percentage, new_query_type, residue;
    

    if (sequence.length < seqLength){ seqLength = sequence.length; }

    for (var i=0; i<seqLength; i++){
      residue = sequence.charAt(i).toUpperCase();

      // skip fasta header lines
      if (residue === '>') { 
        for (i=i++; i<seqLength; i++){
          residue = sequence.charAt(i); 
          if (residue === '\n'){ break; }
        }
      }
    
      // skip if space or digit do we need to warn invalid sequence?
      if (residue.match(/\d|\n|\t/)) {
        continue;
      } 

      // find valid DNA bases 
      base_found = bases.indexOf(residue);
      if (base_found >= 0){ count++; }
   
      letters++;
    }; 

    percentage = ( count / letters ) * 100;
    new_query_type = percentage < dna_threshold ? 'protein' : 'dna'; 
    this.elLk.query.each(function () { 
       this.checked = !!this.value.match(new_query_type);
    });
  },

  updateConfiguration: function () {
    var panel = this;
    var url   = Ensembl.speciesPath + "/Ajax/blastconfig";

    $.ajax({
      url: url,
      data: { blastmethod : this.elLk.method.val()},
      dataType: 'json',
      success: function (json) {
        $.each( json, function (key, options){ 
          if (options[0] === 1){
            $('.config_'+ key, panel.elLk.blastForm).val(options[1]);
            if ($('.blast_config_'+ key, panel.elLk.blastForm).hasClass('hide')) {
              $('.blast_config_'+ key, panel.elLk.blastForm).removeClass('hide');
            }
          } else {
            if(!$('.blast_config_'+ key, panel.elLk.blastForm).hasClass('hide')){  
              $('.blast_config_'+ key, panel.elLk.blastForm).addClass('hide');  
            }
          }
        })
      }
    });
  },
  
  updateOptions: function () {
    var panel  = this;    
    var url    = Ensembl.speciesPath + "/Ajax/blastinput";
    var method = this.elLk.method.val();

    // Due to form complexity reset form validation for every change 
    if ($('label.invalid',panel.elLk.blastForm).length != 0) {  
      $('.failed', panel.elLk.blastForm).each ( function () { 
        $(this).removeClass( '_' + $(this).attr('name') + ' failed required invalid'); 
      })   
      panel.elLk.blastForm.validate().removeData('validator').find(':input').removeData();
    }

    $.ajax({
      url: url, 
      data: { species: this.elLk.species.val(),
              query:   this.elLk.query.filter(':checked').val(),
              db_type: this.elLk.db_type.filter(':checked').val(), 
              db_name: this.elLk.db_name.val(), 
              blastmethod:  this.elLk.method.val()
            },
      dataType: 'json',
      success: function (json) {
        $.each(json, function (key, options){
          $('select[name="'+ key +'"]', panel.elLk.blastForm).empty();
          $.each(options, function(index, option ){
            $('select[name="'+ key +'"]', panel.elLk.blastForm).append(option);

            if (key === 'blastmethod' && option.match(/selected/) ){
              var selected = option.substring(option.lastIndexOf('">') +2 , option.lastIndexOf("<"));
              if (selected !== method){ panel.updateConfiguration(); } 
            }
          });  
        });
      }
    });
  },

  indicateInputError: function (errors) {
    var panel = this; 
    panel.elLk.blastForm.addClass('check');

    var display_errors = { rules: {}, message: {} };

    var failed = $.map(errors, function (message, error_class) { 
      var tmp_errors = { rules: {}, messages: {} };
      tmp_errors.rules[error_class] = function (val) { 
        return !this.inputs.filter('._' + error_class).hasClass('failed'); 
      }; 
      tmp_errors.messages[error_class] = message;
      
      $.extend(true, display_errors, tmp_errors);
      $("." + error_class +":last", panel.elLk.blastForm).addClass('_' + error_class + ' failed required');
      return;
    });

    panel.elLk.blastForm.validate( display_errors, 'showError');
    $.each(failed, function () { this.removeClass('failed required valid'); });
    failed = null;
  }
});
