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

// $Revision$

Ensembl.Panel.VEPResults = Ensembl.Panel.Content.extend({
  init: function () {
    var panel = this;
    
    this.base();
    
    this.el.find('a.zmenu').on('click', this.zmenu);
    
    this.el.find('a.filter_toggle').on('click', this.filter_toggle);
    
    this.el.find('input.autocomplete').on('focus', {panel: this}, this.filter_autocomplete);
  },
  
  zmenu: function(e){
    var el = $(this);
    Ensembl.EventManager.trigger('makeZMenu', el.text().replace(/\W/g, '_'), { event: e, area: {a: el}});
    return false;
  },
  
  filter_toggle: function(e){
    $("." + this.rel).each(function() {
      this.style.display = (this.style.display == 'none' ? '' : 'none');
    });
  },
  
  filter_autocomplete: function(e){
      var el = $(this);
      var fieldNum = this.name.replace("field", "").replace("value", "");
      var panel = e.data.panel;
      
      // find value and field input
      var value = $("input[name='value" + fieldNum + "']");
      var field = $("select[name='field" + fieldNum + "']");
      
      var autoValues = JSON.parse(panel.params['auto_values'].replace(/\'/g, '"'));
      
      if(autoValues[field[0].value] && autoValues[field[0].value].length) {
        value.autocomplete({
          minLength: 0,
          source: autoValues[field[0].value]
        });
      }
      else if(value.hasClass('ui-autocomplete-input')) {
        value.autocomplete("destroy");
      }
      
      // update placeholder
      if(field[0].value == 'Location') {
        value.attr("placeholder", "chr:start-end");
      }
      else {
        value.attr("placeholder", "defined");
      }
      
      return false;
  }
});
