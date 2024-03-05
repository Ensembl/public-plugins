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

// Extension to the core ModalContent.js to add a confirm dialogue to the links with class '_jconfirm'

Ensembl.Panel.ModalContent = Ensembl.Panel.ModalContent.extend({
  initialize: function () {
    var panel = this;
    this.base();
    
    this.el.find('a._jconfirm').on('click', function() {
      var link = $(this);
      return !link.next().hasClass('_jconfirm') || window.confirm(link.next().html());
    });
    
    this.el.find('input._jcancel').on('click', function(e) {
      var redirectURL = $(this.form).find('input[name=_jcancel]').val();
      if (redirectURL) {
        Ensembl.EventManager.trigger('modalOpen', { href: redirectURL, rel: '' });
      }
    });
  },
  
  getContent: function (link, url) {
    if (url.match(/\/Bookmark/)) {
      this.el.addClass('_needs_refresh_on_hide');
    }
    return this.base(link, url);
  }
});