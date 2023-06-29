/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2022] EMBL-European Bioinformatics Institute
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
 * Plugin to GA to avoid adding too many unique labels for results links on LHS menu
 */
Ensembl.extend({
  initialize: function () {
    if (Ensembl.GA && window.location.href.match(/\/Tools\/[^\/]+\/Results/)) {
      (function (conf) {
        conf.oldLabel = conf.label;
        conf.label = function() {
          var label = this.oldLabel();
          if (label && this.currentTarget.href.match(/\/Tools\/[^\/]+\/Results/)) {
            label = 'Tools Job Result';
          }
          return label;
        };
      })(Ensembl.GA.getConfig('LocalContext-LeftButton'));
    }
    this.base.apply(this, arguments);
}})
