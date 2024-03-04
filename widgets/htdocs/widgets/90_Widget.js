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

Ensembl.Panel.Widget = Ensembl.Panel.ImageMap.extend({
  init: function () {
    
    var panel         = this;
    var id            = this.id.replace("tempId",'');

    if(!this.supported()) {
      var url = this.params.updateURL.split('?'); 
      url = url[0] + '/main?' + url[1] + ';static=1';    

      $('#' + this.id).html('<div class="ajax js_panel" id="' + id + '"><input type="hidden" class="ajax_load" value="' + url + '" /></div>');
      
      this.base();
      Ensembl.EventManager.register('ajaxComplete', this, function () { Ensembl.EventManager.remove(this.id); });
    } else {
      this.base();
      this.tree              = this.params.treeType;
      this.json              = $.parseJSON(this.params.json);
      this.species_name_map  = $.parseJSON(this.params.species_name_map); //json object of production name mapping to url name
      this.species_name      = this.params.species_name;
      Ensembl.CafeTree.displayTree(this.json, this.species_name, this.species_name_map, this);

    /* these need to be initialised after tree is drawn */    
      this.elLk.img     = $(".tnt_groupDiv", this.elLk.container);
      this.elLk.d3_menu = $('.d3_menu', this.elLk.container);
      this.d3Tree       = tnt.tree();  
      
      $('div._ht', this.elLk.toolbars).helptip({ track: false });  /* this has to be after the tree is drawn */        
      
      this.elLk.popupLinks.on('click', function () {
        panel.elLk.d3_menu.hide();
        return false;
      });
    }
  },
  
//  makeImageMap: function () { },
  
  /*
    drawing the image toolbar, already have resize functionality if resize class pass through
    classes are icon classes that you want on the toolbar. The icon functionality should be in each view unless it is a generic one and can go in here
  */
  imageToolbar: function(tree_obj, classes) {
    var panel           = this;
    var d3El            = d3.select(".image_container");    
    var width           = Math.floor(d3El.style("width").replace(/px/g,'') / 100) * 100;    
    
    //adding classes for the other icons   
    for	(var i = 0; i < classes.length; i++) {
      d3.select(".image_toolbar").append("div").attr("class", classes[i]+" _ht");
    };    
    d3.select(".image_toolbar").append("div").attr("class", "tree_label"); 
    
    if($(".resize").length) {    
      d3El.append("div").attr("class", "toolbar_menu d3_menu resize_menu");
      panel.drawResizeMenu(width);   
          
      d3.select(".resize")
        .attr("title", "Resize this image")
        .on("click",function(){
          if(d3.select(".resize_menu").style("display") == 'none') {
            //just making sure all other menu are closed
            d3.selectAll(".toolbar_menu").each(function(d,i) {
              d3.select(this).style("display", "none");
              d3.select(".share_page").style("display", "none");
            });
          
            d3.select(".resize_menu").style("display", "block");

            d3.select(".resize_menu").selectAll("div").each(function(d, i) {                                  
                d3.select(this).on("click", function () { 
                  var current_width = Math.floor(d3El.style("width").replace(/px/g,'') / 100) * 100;
                  var selection = d3.select(this).text();
                  if(selection != "Resize image width" && selection != (current_width + " px")) {
                    var new_width = parseInt(selection.replace(/\spx/g,''));
                    
                    tree_obj.layout().width(new_width);
                    tree_obj.update();
                    d3.select("svg").attr("width", new_width + "px");
                    d3.select(".legend-line").attr("x2", new_width-30);
                    d3El.style("width", new_width + "px");
                    d3.select(".tnt_groupDiv").style("width", new_width + "px");
                    d3.select(".resize_menu").style("display", "none");
                    panel.drawResizeMenu(new_width);
                  }                  
                })
            });      

          } else {
            d3.select(".resize_menu").style("display", "none");
          }
        });
    };
    
    if($(".layout_switch").length) {
      d3.select(".layout_switch")
        .attr("id", "switch")
        .attr("title", "Switch between radial and vertical")
        .on("click", function() {
          var pos           = d3.select("#switch").attr("class");
          var current_width =  Math.floor(d3El.style("width").replace(/px/g,'') / 100) * 100;

          //just making sure all other menu are closed
          d3.selectAll(".toolbar_menu").each(function(d,i) {
            d3.select(this).style("display", "none");
            d3.select(".share_page").style("display", "none");
          });

          if(pos.match(/vertical/g)) {
            d3.select("#switch").attr("class", d3.select("#switch").attr("class").replace(/vertical/g,"radial"));
            tree_obj.layout(tnt.tree.layout.radial().width(current_width).scale(false)).duration(1000);
            tree_obj.update();
          } else {
            d3.select("#switch").attr("class", d3.select("#switch").attr("class").replace(/radial/g,"vertical"));
            tree_obj.layout(tnt.tree.layout.vertical().width(current_width).scale(false)).duration(1000);
            tree_obj.update();
          }
        });
    };
  },
   
  drawResizeMenu: function(new_width) {
    var resize_menu = d3.select(".resize_menu");

    if(resize_menu.text()) { resize_menu.selectAll("*").remove(); }

    resize_menu.append("div")
               .attr("class", "header")
               .text("Resize image width");

    for (var i = parseInt(new_width) - 300; i <= parseInt(new_width) + 300; i+=100) {
        var width_sel = resize_menu.append("div")
            .text(i + " px");
        if(i == new_width) { width_sel.classed("current", true); }
    };
  },    
  
  windowResize: function() {
    $(window).off("resize.tnt");
  },
  
  supported: function () {
    var  support = document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.1");
    return support ? 1 : 0;
//return 0;
  }  
});
  
 
