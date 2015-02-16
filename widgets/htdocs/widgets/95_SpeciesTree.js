Ensembl.SpeciesTree = {};

Ensembl.SpeciesTree.displayTree = function(json, panel) {
    this.panel = panel;
  var theme =  Ensembl.SpeciesTree.tnt_theme_tree_simple_species_tree(json);
  theme(tnt.tree(), document.getElementById("species_tree"));
}

Ensembl.SpeciesTree.tnt_theme_tree_simple_species_tree = function(species_details) {
    "use strict";

    var pics_path     = "/i/species/48/";
    var width         = Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;
    var scale         = false;
    var species_info  = species_details['species_tooltip'];    

    var tnt_theme = function (tree_vis, div) {
      var tntResize = function () {
        $(window).off("resize.tnt");
        window.setTimeout(function () {
          $(window).on("resize.tnt", tntResize);
          $(".tnt_groupDiv").width(Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100);
          tree_vis.layout().width(Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100);
          tree_vis.update();
        }, 100);
      }
      $(window).on("resize.tnt", tntResize);

      function draw_resize_menu(new_width) {
        var resize_menu = d3.select(".resize_menu");

        if(resize_menu.text()) { resize_menu.selectAll("*").remove(); }

        resize_menu.append("div")
                   .attr("class", "header")
                   .text("Resize image width");

        for (var i = parseInt(new_width) - 300; i <= parseInt(new_width) + 300; i+=100) {
            var width_sel = resize_menu.append("div")
                                       .text(i + " px");
            if(i == new_width) { width_sel.classed("current", true); }
        }

      }
      
      function update_tree_label() {
        var ensembl_ncbi  = d3.select(".tree_menu").select(".current").text().replace(/\sTree/g,'');
        var species_clade = d3.select(".filter_menu").select(".current").text().match(/All species/g) ? "Species" : d3.select(".filter_menu").select(".current").text();
        var new_label = ensembl_ncbi + " " + species_clade + " tree";
        d3.select(".tree_label").text(new_label);
      }
    
      // In the div, we set up a "select" to transition between a radial and a vertical tree
      var menu_pane = d3.select(div)
          .append("div")
          .attr("class", "image_toolbar");          

      var tree_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "iexport_menu tree_menu");

      tree_menu.append("div")
          .attr("class", "header")
          .text("Choose tree");

      function update_tree_div(tree_name) {
          if(!d3.select(".tree_item." + tree_name).attr("class").match(/current/g)) {
              d3.selectAll(".tree_item").classed("current", false);
              d3.select(".tree_item." + tree_name).classed("current", true);
              var species_type = d3.select(".filter_menu").select(".current").attr("class").replace(/\scurrent/g,'');
              var tree_type    = tree_name + (species_type.match(/all_species/g) ? "" : "_" + species_type) + "_tree_obj";
              tree_vis.data(species_details[tree_type]);
              tree_vis.update();
              update_tree_label();
          }
          d3.select(".tree_menu").style("display", "none");
      };

      tree_menu.append("div")
          .attr("class", "tree_item ncbi")
          .text("NCBI Taxonomy Tree")
          .on("click", function() {
              return update_tree_div("ncbi");
          });

      tree_menu.append("div")
          .attr("class", "tree_item ensembl current")
          .text("Ensembl Tree")
          .on("click", function() {
              return update_tree_div("ensembl");
          });

      d3.select("#species_tree").append("div").attr("class", "iexport_menu resize_menu");
      draw_resize_menu(width);
      
      var filter_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "iexport_menu filter_menu");

      filter_menu.append("div")
          .attr("class", "header")
          .text("View tree for");

      filter_menu.append("div")
          .attr("class", "mammalia")
          .text("Mammals")

      filter_menu.append("div")
          .attr("class", "sauria")
          .text("Sauropsids");         

      filter_menu.append("div")
          .attr("class", "amniota")
          .text("Amniotes");

      filter_menu.append("div")
          .attr("class", "neopterygii")
          .text("Fish");
          
      filter_menu.append("div")
          .attr("class", "all_species current ")
          .text("All species");         

      var tree_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "tree_switch")
          .attr("title", "switch between NCBI and Ensembl tree")
          .on("click", function() {
              if(d3.select(".tree_menu").style("display") == 'none') {
                //just making sure all other menu are closed
                d3.selectAll(".iexport_menu").each(function(d,i) {
                  d3.select(this).style("display", "none");
                });
                d3.select(".tree_menu").style("display", "block");
              } else {
                d3.select(".tree_menu").style("display", "none");
              }
          });
          
      var filter_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "filter_switch")
          .attr("title", "Filter species tree by mammal, fish,...")          
          .on("click", function() {
            if(d3.select(".filter_menu").style("display") == 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".iexport_menu").each(function(d,i) {
                d3.select(this).style("display", "none");
              }); 
              
              d3.select(".filter_menu").style("display", "block");         
              filter_menu.selectAll("div").each(function(d,i) { 
                var filter_class = d3.select(this).attr("class");
                
                if(filter_class.match(/header/g))  return false;
                
                d3.select(this).on("click", function() {  
                  if(filter_class.match(/current/g)) {
                    d3.select(".filter_menu").style("display", "none");
                    return;
                  } else {          
                    d3.select(".filter_menu").selectAll("div").classed("current", false);   //remove current from the corresponding div
                    d3.select(this).classed("current", true);                
                    var tree = d3.select(".tree_menu").select(".current").attr("class").match(/ensembl/g) ? tree = filter_class.match(/all_species/g) ? 'ensembl_tree_obj' : 'ensembl_'+ filter_class + "_tree_obj"
                               : filter_class.match(/all_species/g) ? 'ncbi_tree_obj' : 'ncbi_'+ filter_class + "_tree_obj";
                    tree_vis.data(species_details[tree]);
                    tree_vis.update();
                    update_tree_label();
                    d3.select(".filter_menu").style("display", "none");  
                  }
                });
              });              
            } else {
              d3.select(".filter_menu").style("display", "none");
            }          
          });
          
      var layout_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("id", "switch")
          .attr("class", "layout_switch vertical")     
          .attr("title", "Switch between radial and vertical")
          .on("click", function() {
            var pos           = d3.select("#switch").attr("class");
            var current_width =  Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;

            //just making sure all other menu are closed
            d3.selectAll(".iexport_menu").each(function(d,i) {
              d3.select(this).style("display", "none");
            });

            if(pos.match(/vertical/g)) {
              d3.select("#switch").attr("class", d3.select("#switch").attr("class").replace(/vertical/g,"radial"));

              tree_vis.layout(tnt.tree.layout.radial().width(current_width).scale(scale)).duration(1000);
              tree_vis.update();
            } else {
              d3.select("#switch").attr("class", d3.select("#switch").attr("class").replace(/radial/g,"vertical"));

              tree_vis.layout(tnt.tree.layout.vertical().width(current_width).scale(scale)).duration(1000);
              tree_vis.update();
            }
          });
          
      var resize_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "resize")
          .attr("title", "Resize this image")
          .on("click",function(){
            if(d3.select(".resize_menu").style("display") == 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".iexport_menu").each(function(d,i) {
                d3.select(this).style("display", "none");
              });
            
              d3.select(".resize_menu").style("display", "block");

              d3.select(".resize_menu").selectAll("div").each(function(d, i) {                                  
                  d3.select(this).on("click", function () { 
                    var current_width = Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;
                    var selection = d3.select(this).text();
                    if(selection != "Resize image width" && selection != (current_width + " px")) {
                      var new_width = parseInt(selection.replace(/\spx/g,''));
                      
                      tree_vis.layout().width(new_width);
                      tree_vis.update();
                      d3.select("svg").attr("width", new_width + "px");
                      d3.select("#species_tree").style("width", new_width + "px");
                      d3.select(".tnt_groupDiv").style("width", new_width + "px");
                      d3.select(".resize_menu").style("display", "none");
                      draw_resize_menu(new_width);
                    }                  
                  })
              });      

            } else {
              d3.select(".resize_menu").style("display", "none");
            }
          });


      var image_label = tnt.tree.label.img()
          .src(function(d) {
            if(d.is_leaf()) {
              return pics_path + species_info[d.data().name]['production_name'] + ".png";
            }
          })
          .width(function() {
            return 30;
          })
          .height(function() {
            return 40;
          });

      var original_label = tnt.tree.label.text()
          .text(function (node) { 
            if(node.is_leaf()) { 
              return node.node_name(); 
            } 
          }).fontsize(14);

      // The joined label shows a picture + the common name
      var joined_label = tnt.tree.label.composite()
        .add_label(image_label)
        .add_label(original_label);

      var node_tooltip = function (node) {
        var obj    = {};
        obj.header = "Scientific Name: " + node.node_name();
        obj.rows   = [];
       
        obj.rows.push ({
          label : 'Ensembl Name',
          value : species_info[node.node_name()]['ensembl_name']
        });          
        obj.rows.push ({
          label : 'Taxon ID',
          value : species_info[node.node_name()]['taxon_id']          
        });

        if (node.is_leaf()) {        
          obj.rows.push ({
            label : "Assembly", 
            value : species_info[node.node_name()]['assembly']    
          });
          obj.rows.push ({
            label : "Species Homepage",            
            value : '<a href="/'+species_info[node.node_name()]['ensembl_name']+'/Info/Index" title="Click to go to species homepage">'+species_info[node.node_name()]['ensembl_name']+'</a>'
          });          
        } else {
          obj.rows.push ({
            label : 'Divergence Time<br>(million Years)',
            value : species_info[node.node_name()]['timetree']
          });        
        }

        tnt.tooltip.table().width(210).call (this, obj);
      };
      
      // the point of this code is to create tree obj for the different type of trees data and just use the obj key to get the data for the specific tree
      for(var j in species_details) {
        if(species_details.hasOwnProperty(j) && j.match(/_tree$/)) {
          var tree_key = j + "_obj";      
          var root_node = tnt.tree.node(tnt.tree.parse_newick(species_details[j])); //making the tree object for each tree
          
          root_node.sort(function(node1, node2) { return species_info[node1.node_name()]['taxon_id'] - species_info[node2.node_name()]['taxon_id']; }); //sorting the tree obj based on taxonid
          
          //populating the species_details obj with all possible trees
          species_details[j.replace(/_tree/g,'')+'_mammalia_tree_obj']    = root_node.find_node_by_name('Mammalia').data();
          species_details[j.replace(/_tree/g,'')+'_sauria_tree_obj']      = root_node.find_node_by_name('Sauria').data();
          species_details[j.replace(/_tree/g,'')+'_amniota_tree_obj']     = root_node.find_node_by_name('Amniota').data();
          species_details[j.replace(/_tree/g,'')+'_neopterygii_tree_obj'] = root_node.find_node_by_name('Neopterygii').data();
          
          species_details[tree_key] = root_node.data();          
        }
      }
      

    var hash = {};
    tnt.tree.node(species_details['ensembl_tree_obj']).apply(function (node){
        if(hash[node.node_name()] == undefined ) { 
            hash[node.node_name()] = 1;
            node.property("unique_name", node.node_name());
        } else {        
          node.property("unique_name", node.node_name() + "_" + hash[node.node_name()]);
          hash[node.node_name()]++;
        }
      });
      
      tnt.tree.node(species_details['ncbi_tree_obj']).apply(function (node) {
        node.property("unique_name", node.node_name());
      });

	    tree_vis
	      .data(species_details['ensembl_tree_obj'])
        .id("unique_name")
        .label(joined_label)
        .node_display(tree_vis.node_display().size(4))
        .on_click(node_tooltip)
	      .link_color("black")
	      .layout(tnt.tree.layout.vertical()
          .width(width)
		      .scale(scale)
		    );
      
    	tree_vis(div);      
      d3.select(".image_toolbar").append("div").attr("class", "tree_label").text("Ensembl Species tree");
    };

    return tnt_theme;
};

  
