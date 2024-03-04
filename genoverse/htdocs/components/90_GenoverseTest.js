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

/*
 * This panel only gets initialised if the backend is not sure about what image should be displayed
 * It just checks whether Genoverse is supported or not and adds an extra param 'genoverse' to the panel's updateURL
 */

Ensembl.Panel.GenoverseTest = Ensembl.Panel.Content.extend({
  init: function () {

    this.base.apply(this, arguments);

    this.params.updateURL = Ensembl.updateURL({genoverse: typeof Ensembl.genoverseSupported === "function" ? 1 : 0}, this.params.updateURL);

    this.getContent();
  }
});
