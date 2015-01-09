/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

/* Extension to Content panel
 * To use this panel, provide class name _ts_button to the buttons and _ts_tab to the tab divs inside the panel
 * along with css classes
 */

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({

  init: function() {
    this.base();
    var fnEls = {
      tabSelector: this.el.find('._tabselector'),
      enstinymce: this.el.find('textarea._tinymce')
    };
    
    $.extend(this.elLk, fnEls);
    
    for (var fn in fnEls) {
      if (fnEls[fn].length) {
        this[fn]();
      }
    }
  },

  tabSelector: function() {
    var buttons = $('._ts_button', this.elLk.tabSelector);
    var tabs    = $('._ts_tab',    this.elLk.tabSelector);
  
    buttons.each(function(i) {
      $(this).click(function(event) {
        event.preventDefault();
        $(tabs.hide()[i]).show();
        $(buttons.removeClass('selected')[i]).addClass('selected');
      });
    }).first().trigger('click');
  
    $('._ts_loading', this.elLk.tabSelector).removeClass('spinner ts-spinner');
  },

  enstinymce: function() {
    this.elLk.enstinymce.enstinymce();
  }
});