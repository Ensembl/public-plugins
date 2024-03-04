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

Ensembl.Panel.AccountForm = Ensembl.Panel.extend({
  init: function () {
    var panel = this;
    this.base();

    this.elLk.email           = this.el.find('._openid_email');
    this.elLk.hideIfTuststed  = this.el.find('._hide_if_trusted');
    this.elLk.passwordAuth    = this.el.find('input._password_auth');
    this.elLk.passwordField   = this.el.find('div._password_auth');
    this.elLk.changeEmailEls  = this.el.find('._change_email');

    if (parseInt(this.el.find('._trusted_provider').val())) { // has trusted provider
      this.elLk.email.on({
        'change': function() { panel.toggleEmail(); },
        'click' : function() { panel.toggleEmail(); },
        'keyup' : function() { panel.toggleEmail(); }
      });
      this.toggleEmail();
    }

    this.elLk.passwordAuth.parents('div').first().find('input').on({
      'change'  : function() { panel.togglePassword(); }
    });

    this.togglePassword();
    this.initChangeEmail();
  },

  toggleEmail: function() {
    var inp = this.elLk.email[0];
    this.elLk.hideIfTuststed.toggle(inp.defaultValue != inp.value);
    this.togglePassword();
  },

  togglePassword: function() {
    this.elLk.passwordField.toggle(!!(this.elLk.passwordAuth.is(':visible') && this.elLk.passwordAuth.attr('checked'))).find('input').focus();
  },

  initChangeEmail: function() {
    var panel = this;
    this.elLk.changeEmailEls.filter('a').on({click: function(event) {
      event.preventDefault();
      var inp = panel.elLk.changeEmailEls.find('input')[0];
      inp.value = inp.defaultValue;
      panel.elLk.changeEmailEls.toggleClass('hidden');
    }});
  }
});
