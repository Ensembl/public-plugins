/*
 * Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.OpenIDButtons = Ensembl.Panel.extend({
  init: function() {
    this.base();
    var panel = this;

    var closePopup = function() {
      panel.usernamePopup.hide();
      $(document).off('click', closePopup);
    };

    this.el.find('a._openid_username').on({
      click: function(event) {
        event.preventDefault();
        event.stopPropagation();
        var link = $(this);
        if (!link.data('popup')) {
          link.data('popup', link.next().appendTo(document.body));
        }
        panel.usernamePopup = link.data('popup').css({left: event.pageX + 'px', top: event.pageY + 'px'}).show().find('input[type=text]').focus().end();
        $(document).on('click', closePopup);
      }
    });
    this.el.find('div._openid_username').on({
      click: function(event) {
        event.stopPropagation();
      }
    });
  }
});