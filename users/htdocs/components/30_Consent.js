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

Ensembl.Panel.Consent = Ensembl.Panel.ModalContent.extend({

  init: function () {
    var panel = this;
    this.base();

    this.elLk.noThanks = this.el.find("#consent_warning");
    this.elLk.message  = this.el.find("#consent_message");

    this.elLk.noThanks.on({ click: function(e) {
      // Don't do this if it's already been done!
      if ($(this).attr('type') != 'submit') { 
        panel.elLk.message.replaceWith('<div id="consent_warning_2"><p>If you do not accept our privacy policy, your account will be disabled and will be deleted after 30 days unless you contact us.</p><p>Are you sure you wish to do this?</div>');
        // Change button text and turn it into a submit button
        $(this).val('Yes, disable my account');
        $(this).attr('type','submit');
        e.preventDefault();
      }
    }});
  }
});
