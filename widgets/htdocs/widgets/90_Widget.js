/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.Widget = Ensembl.Panel.Content.extend({
  init: function () {
    var id  = this.id.replace("tempId",'');

    if(!this.supported()) {
      var url = this.params.updateURL.split('?'); 
      url = url[0] + '/main?' + url[1] + ';static=1';    

      $('#' + this.id).html('<div class="ajax js_panel" id="' + id + '"><input type="hidden" class="ajax_load" value="' + url + '" /></div>');

      this.base();

      Ensembl.EventManager.register('ajaxComplete', this, function () { Ensembl.EventManager.remove(this.id); });
    }
  },
  
  supported: function () {
    var  support = document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.1");
    return support ? 1 : 0;
//return 0;
  }
});
