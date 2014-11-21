var tnt_theme_tree_simple_species_tree = function(species_details) {
    "use strict";

    var pics_path     = "/i/species/48/";
    var width         = Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;
    var scale         = false;
    var species_info  = species_details['species_tooltip'];    

    var tnt_theme = function (tree_vis, div) {

/* this is not working, causing the browser to freeze
      d3.select(window).on("resize", function resize () {
//console.log(width);
              tree_vis.layout().width(500);
              tree_vis.update();
      });
*/
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
          .attr("class", "image_toolbar")          
          .append("div")
          .attr("id", "switch")
          .attr("class", "layout_switch vertical")     
          .attr("title", "Switch between radial and vertical")
          .on("click", function() {
            var pos           = d3.select("#switch").attr("class");
            var current_width =  Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;

            //just making sure all other menu are closed
            d3.selectAll(".image_resize_menu").each(function(d,i) {
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

      var tree_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "image_resize_menu tree_menu");

      tree_menu.append("div")
          .attr("class", "header")
          .text("Choose tree");

      tree_menu.append("div")
          .attr("class", "ncbi")
          .text("NCBI Tree")
          .on("click", function() {
              if(d3.select(".ncbi").attr("class").match(/current/g)) {
                d3.select(".tree_menu").style("display", "none");
                return;
              } else {
                d3.select(".ncbi").classed("current", true);
                d3.select(".ensembl").classed("current", false);
                var species_type = d3.select(".filter_menu").select(".current").attr("class").replace(/\scurrent/g,'');
                var tree_type    = species_type.match(/all_species/g) ? "ncbi_tree" : "ncbi_" + species_type;                
                tree_vis.data(tnt.tree.parse_newick(species_details[tree_type]));
                tree_vis.update();
                update_tree_label();
                d3.select(".tree_menu").style("display", "none");
              }
          });

      tree_menu.append("div")
          .attr("class", "ensembl current")
          .text("Ensembl Tree")
          .on("click", function() {
              if(d3.select(".ensembl").attr("class").match(/current/g)) {
                d3.select(".tree_menu").style("display", "none");
                return; 
              } else {
                d3.select(".ensembl").classed("current", true);
                d3.select(".ncbi").classed("current", false); 
                var species_type = d3.select(".filter_menu").select(".current").attr("class").replace(/\scurrent/g,'');
                var tree_type    = species_type.match(/all_species/g) ? "newick_tree" : "newick_" + species_type;                
                tree_vis.data(tnt.tree.parse_newick(species_details[tree_type]));
                tree_vis.update();
                update_tree_label();
                d3.select(".tree_menu").style("display", "none");
              }
          });

      d3.select("#species_tree").append("div").attr("class", "image_resize_menu resize_menu");
      draw_resize_menu(width);
      
      var filter_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "image_resize_menu filter_menu");

      filter_menu.append("div")
          .attr("class", "header")
          .text("View tree for");

      filter_menu.append("div")
          .attr("class", "mammals")
          .text("Mammals")

      filter_menu.append("div")
          .attr("class", "sauria")
          .text("Sauropsids");         

      filter_menu.append("div")
          .attr("class", "amniota")
          .text("Amniotes");

      filter_menu.append("div")
          .attr("class", "fish")
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
                d3.selectAll(".image_resize_menu").each(function(d,i) {
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
              d3.selectAll(".image_resize_menu").each(function(d,i) {
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
                    var tree = d3.select(".tree_menu").select(".current").attr("class").match(/ensembl/g) ? tree = filter_class.match(/all_species/g) ? 'newick_tree' : 'newick_'+ filter_class
                               : filter_class.match(/all_species/g) ? 'ncbi_tree' : 'ncbi_'+ filter_class;
                    tree_vis.data(tnt.tree.parse_newick(species_details[tree]));
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

      var resize_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "resize")
          .attr("title", "Resize this image")
          .on("click",function(){
            if(d3.select(".resize_menu").style("display") == 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".image_resize_menu").each(function(d,i) {
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
        var obj = {};
        obj.header = {
          label : "Ensembl Name",
          value : species_info[node.node_name()]['ensembl_name']
        };

        obj.rows = [];
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
            label : 'Timetree(million Years)',
            value : species_info[node.node_name()]['timetree']
          });        
        }

        tnt.tooltip.table().call (this, obj);
      };
 

	    tree_vis
	      .data(tnt.tree.parse_newick(species_details['newick_tree']))
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