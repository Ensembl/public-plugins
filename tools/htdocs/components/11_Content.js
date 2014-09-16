/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({

  init: function() {
    this.base.apply(this, arguments);

    this.blastButtonEnabled = false;

    Ensembl.EventManager.register('enableBlastButton',  this, this.enableBlastButton);
    Ensembl.EventManager.register('runBlastSeq',        this, this.runBlastSeq);
  },

  enableBlastButton: function(seq) {
    var panel = this;

    if (seq && !this.blastButtonEnabled) {

      this.elLk.blastButton = this.el.find('._blast_button').removeClass('modal_link hidden').on('click', function(e) {
        e.preventDefault();
        panel.runBlastSeq();
      });

      if (this.elLk.blastButton.length) {

        this.elLk.blastForm = $('<form>').appendTo(document.body).hide()
          .attr({action: this.elLk.blastButton.attr('href'), method: 'post'})
          .append($.map(Ensembl.coreParams, function(n, v) { return $('<input type="hidden" name="' + n + '" value="' + v + '" />'); }))
          .append($('<input type="hidden" name="query_sequence" value="' + seq + '" />'));

        this.blastButtonEnabled = true;
      }
    }

    return this.blastButtonEnabled;
  },

  runBlastSeq: function(seq) {
    if (this.elLk.blastForm) {
      if (seq) {
        this.elLk.blastForm.find('input[name=query_sequence]').val(seq);
      }
      this.elLk.blastForm.submit();
    }
  }
});
