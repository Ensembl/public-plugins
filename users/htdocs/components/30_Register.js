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

Ensembl.Panel.Register = Ensembl.Panel.ModalContent.extend({

  init: function () {
    var panel = this;
    this.base();

    this.elLk.form      = this.el.find('form#registration');
    this.elLk.button    = this.el.find('#pre_consent');
    this.elLk.checkbox  = this.el.find('#consent_checkbox');

    this.elLk.checkbox.on('click', function(e) {
      if (panel.elLk.button.hasClass('disabled')) {
        panel.elLk.button.removeClass('disabled');
      }
      else {
        panel.elLk.button.addClass('disabled');
      }
    });

    this.elLk.button.on('click', function(e) {
      if (!panel.elLk.button.hasClass('disabled')) {
        panel.formSubmit(panel.elLk.form);
      }
    });
  }

});
