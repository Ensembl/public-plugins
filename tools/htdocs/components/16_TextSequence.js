/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
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

    this.base.apply(this, arguments);

    var panel = this;

    // Enable the 'BLAST selected sequence' popup botton only if 'BLAST this sequence' link is present in component buttons
    var bottonPresent = Ensembl.EventManager.trigger('enableBlastButton', this.el.clone().find('._seq').text());
    if (typeof bottonPresent !== 'boolean') {
      bottonPresent = !!$.grep($.map(bottonPresent, function(f, i) { return f; }), function(i) { return i; }).length;
    }
    if (!bottonPresent) {
      return;
    }

    this.el.find('span._seq').removeClass('_seq').filter(function() { return !$(this).text().match(/\.+/) }).addClass('_seq').on({

      'mousedown': function() {
        panel.blastSeq = '';
        panel.resetSelection();
        panel.toggleBlastPopup(false);
        $(document.body).addClass('sequence_selection');
        $(document).on('mouseup.TextSequence', function(e) {
          panel.blastSeq = panel.getSelection();
          panel.toggleBlastPopup(!!panel.blastSeq, e);
          $(document.body).removeClass('sequence_selection');
        });
      },
      'mouseup': function(e) {
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

  toggleBlastPopup: function(flag, event) {

    var panel = this;

    $(document).off('mouseup.TextSequence');

    if (flag) {

      this.elLk.blastPopup.css({ left: event.pageX, top: event.pageY }).show();

      $(document).on('mouseup.TextSequence', function() {
        panel.toggleBlastPopup(false);
      });

    } else {
      this.elLk.blastPopup.hide();
    }
  },

  resetSelection: function() {
    if (document.selection && document.selection.empty) {
      document.selection.empty();
    } else if (window.getSelection) {
      window.getSelection().removeAllRanges();
    }
  },

  getSelection: function() {
    var seq;

    if (document.selection && document.selection.createRange) {
      seq = $('<div>').html(document.selection.createRange().htmlText).find('._seq').text();
    } else if (window.getSelection) {
      var selection = window.getSelection();
      if (selection.rangeCount > 0) {
        if ($(selection.anchorNode).parents('._seq')[0] === $(selection.focusNode).parents('._seq')[0]) {
          seq = $('<div>').append(selection.getRangeAt(0).cloneContents()).text();
        } else {
          seq = $('<div>').append(selection.getRangeAt(0).cloneContents()).find('._seq').text();
        }
      }
      selection = null;
    }

    // sequence is possibly missing some bps if it contains dots
    if (seq && seq.match(/^\.+/)) {
      seq = '';
    }

    return seq;
  }
});
