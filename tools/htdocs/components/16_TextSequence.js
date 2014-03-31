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

Ensembl.Panel.TextSequence = Ensembl.Panel.TextSequence.extend({
  init: function() {

    this.base();

    var panel = this;

    this.el.find('span._seq').on({
      'mouseup': function(e) {

        var div = $('<div>');

        if (document.selection && document.selection.createRange) {
          div.html(document.selection.createRange().htmlText);
        }
        else if (window.getSelection) {
          var selection = window.getSelection();
          if (selection.rangeCount > 0) {
            div.append(selection.getRangeAt(0).cloneContents());
          }
          selection = null;
        }

        panel.showBlastPopup(div.find(':not(._seq)').remove().end().text(), e);
      },
      'click': function(e) {
        if (panel.blastSeq) {
          e.stopPropagation(); // prevent firing click event on the document which will close the popup as soon as it opens
        }
      }
    });

    this.elLk.blastPopup = $('<div class="blast-popup"><p><a href="#">BLAST selected sequence</a></p></div>').hide().appendTo(document.body).on('click', 'a', function(e) {
      e.preventDefault();
      Ensembl.EventManager.trigger('runBlastSeq', panel.blastSeq);
    });
  },

  showBlastPopup: function(seq, event) {

    var panel = this;

    this.blastSeq = seq;

    if (this.blastSeq) {

      this.elLk.blastPopup.css({ left: event.pageX, top: event.pageY }).show();

      $(document).on('click.removeBlastPopup', function() {
        panel.elLk.blastPopup.hide();
        $(document).off('click.removeBlastPopup');
      });
    }
  }
});
