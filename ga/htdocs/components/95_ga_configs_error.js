/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

Ensembl.extend({
  initialize: function () {

    if (Ensembl.GA.reportErrors) {

      this.reportErrorConfig = new Ensembl.GA.EventConfig({
        category        : 'ErrorReport',
        label           : function() { return this.getURL(window.location.href) },
        nonInteraction  : true
      });
    }

    this.base.apply(this, arguments);

    if (Ensembl.GA.reportErrors) {
      $(document).find('div.error > h3').each(function() {
        Ensembl.GA.sendEvent(Ensembl.reportErrorConfig, { action: $(this).text() });
      });
    }
  }
});
