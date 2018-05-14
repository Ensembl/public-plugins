/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

Ensembl.Panel.Register = Ensembl.Panel.ModalContent.extend({

  init: function () {
    var panel = this;
    this.base();

    this.elLk.button      = this.el.find('input[type=submit]');
    this.elLk.consent     = this.el.find('input[type=checkbox]');

    this.elLk.button.on({ click: function(e) {
      panel.elLk.placeholder = panel.el.find('#message_placeholder');
      if (!panel.elLk.consent.checked) {
        panel.elLk.placeholder.replaceWith('<div class="error" id="consent_warning"><h3>Consent required</h3><div class="message-pad"><p>Please agree to our privacy policy if you wish to register.</p></div></div>');  
        e.preventDefault();
      }
    }});

    this.elLk.consent.on({ change: function() {
      panel.elLk.warning = panel.el.find('#consent_warning');
      console.log('Clicked on box');
      panel.elLk.warning.replaceWith('<div id="message_placeholder"></div>');
    }});
    
  }
});
