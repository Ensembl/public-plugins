Ensembl.SpeciesTree = {};
var _jspdf_available = false;
var _jspdf = $.Deferred();

Ensembl.SpeciesTree.displayTree = function(json, panel) {
  $.getScript( "https://cdnjs.cloudflare.com/ajax/libs/jspdf/1.3.2/jspdf.debug.js" )
  .done(function(script, textStatus) {
    _jspdf_available = true;
    _jspdf.resolve();
  })
  .fail(function() {
    console.log("Couldn't download jspdf.js");
  });

  var theme =  Ensembl.SpeciesTree.tnt_theme_tree_simple_species_tree(json);
  theme(tnt.tree(), document.getElementById("species_tree"));
},

Ensembl.SpeciesTree.tnt_theme_tree_simple_species_tree = function(species_details) {
    "use strict";

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

      function draw_layout_switch_menu() {
        var layout_switch_menu = d3.select(".layout_switch_menu");

        layout_switch_menu
          .append("div")
          .attr("class", "header")
          .text("Change tree layout");

        layout_switch_menu
          .append("div")
          .attr("class", "current layout_switch_menu_vertical layout_switch_menu_option")
          .text("Vertical");
        
        layout_switch_menu
          .append("div")
          .attr("class", "layout_switch_menu_radial layout_switch_menu_option")
          .text("Radial");
      }

      function update_layout_switch_menu(selected_layout) {
        d3.select(".layout_switch_menu_vertical").classed("current", selected_layout === "vertical" ? true : false);
        d3.select(".layout_switch_menu_radial").classed("current", selected_layout === "radial" ? true : false);
        d3.select(".layout_switch_menu").style("display", "none");
      }

      function draw_species_name_menu() {
        var species_name_menu = d3.select(".species_name_menu");

        species_name_menu
          .append("div")
          .attr("class", "header")
          .text("Change name type");

        species_name_menu
          .append("div")
          .attr("class", "current species_name_menu_scientific species_name_menu_option")
          .text("Scientific name");
        
        species_name_menu
          .append("div")
          .attr("class", "species_name_menu_common species_name_menu_option")
          .text("Common name");
      }

      function update_species_name_menu(selected_name_type) {
        d3.select(".species_name_menu_scientific").classed("current", selected_name_type === "scientific" ? true : false);
        d3.select(".species_name_menu_common").classed("current", selected_name_type === "common" ? true : false);
        d3.select(".species_name_menu").style("display", "none");
      }
      
      function update_tree_label() {
        var ensembl_ncbi  = d3.select(".tree_menu").select(".current").text().replace(/\stree/g,'');
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
          .attr("class", "toolbar_menu tree_menu");

      tree_menu.append("div")
          .attr("class", "header")
          .text("Choose tree");

      function update_tree_div(tree_name) {
          if(!d3.select(".tree_item." + tree_name).attr("class").match(/current/g)) {
              d3.selectAll(".tree_item").classed("current", false);
              d3.select(".tree_item." + tree_name).classed("current", true);
              var species_type = d3.select(".filter_menu").select(".current").attr("class").replace(/\scurrent/g,'');
              var tree_type    = (species_type.match(/all_species/g) ? "all" : species_type);
              tree_vis.data(species_details['trees'][tree_name]['objects'][tree_type]);
              tree_vis.update();
              update_tree_label();
          }
          d3.select(".tree_menu").style("display", "none");
      };

      function tree_item_click_handler(tree_name) {
          return function() {
              return update_tree_div(tree_name);
          }
      }

      function svgExport(container, exportType, element) {
        element && $(element).html(exportType + '...downloading');
        element && $(element).addClass('loading');

        var svg = container.querySelector("svg");
        var tree_label = $(container.querySelector('.tree_label')).html();
        var filename = tree_label.replace(/\s+/g,'_') + "." + exportType.toLowerCase();
        if (typeof window.XMLSerializer != "undefined") {
            var svgData = (new XMLSerializer()).serializeToString(svg);
        } else if (typeof svg.xml != "undefined") {
            var svgData = svg.xml;
        }

        var canvas = document.createElement("canvas");
        var svgSize = svg.getBoundingClientRect();
        canvas.width = svgSize.width;
        canvas.height = svgSize.height;
        var ctx = canvas.getContext("2d");

        var img = document.createElement("img");
        img.setAttribute("src", "data:image/svg+xml;base64," + btoa(unescape(encodeURIComponent(svgData))) );

        img.onload = function() {
          ctx.drawImage(img, 0, 0);
          var imgsrc = canvas.toDataURL("image/png");
          if (_jspdf_available && exportType == 'PDF') {
            // px to cm conversion
            var ht = svgSize.height * 0.02645833;
            var wd = svgSize.width * 0.02645833;
            var imgData = canvas.toDataURL("image/png", 1.0);
            var pdf = new jsPDF({
              orientation: ht > wd ? 'portrait' : 'landscape',
              unit: 'cm',
              format: [ht, wd]
            });
            pdf.addImage(imgsrc, 'PNG', 0, 0);
            pdf.setFontSize(12);
            pdf.text(0.5, 0.5, tree_label || '');
            pdf.save(filename);
          }
          else if(exportType == 'PNG') {
            var a = document.createElement("a");
            a.download = filename;
            a.href = imgsrc;
            document.body.appendChild(a);
            a.click();
            $(a).remove();          
          }
          else {
            var tree_type = d3.select(".tree_menu").select(".current").attr("class").replace(/current/g,'').replace(/tree_item/g,'').replace(/ /g,'');
            var newick = species_details['trees'][tree_type].newick;
            var a = document.createElement("a");
            a.download = filename;
            a.href="data:text/plain,"+encodeURIComponent(newick);
            a.click();
          }
          element && $(element).html(exportType);
          element && $(element).removeClass('loading');
        };
      }

      for(var j in species_details['trees']) {
          tree_menu.append("div")
              .attr("class", "tree_item " + j + (j == species_details['default_tree'] ? " current" : ""))
              .text(species_details['trees'][j]['label'] + " tree")
              .on("click", tree_item_click_handler(j));
      }

      d3.select("#species_tree").append("div").attr("class", "toolbar_menu resize_menu");
      draw_resize_menu(width);
      
      var filter_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "toolbar_menu filter_menu");

      filter_menu.append("div")
          .attr("class", "header")
          .text("View tree for");

      for(var j in species_details['filters']) {
        filter_menu.append("div")
            .attr("class", j)
            .text(species_details['filters'][j]);
      }

      filter_menu.append("div")
          .attr("class", "all_species current ")
          .text("All species");         

      var tree_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "tree_switch")
          .attr("title", "switch between the various trees")
          .on("click", function() {
              if(d3.select(".tree_menu").style("display") == 'none') {
                //just making sure all other menu are closed
                d3.selectAll(".toolbar_menu").each(function(d,i) {
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
              d3.selectAll(".toolbar_menu").each(function(d,i) {
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
                    var tree_type = d3.select(".tree_menu").select(".current").attr("class").replace(/current/g,'').replace(/tree_item/g,'').replace(/ /g,'');
                    var species_filter = (filter_class.match(/all_species/g) ? 'all' : filter_class);
                    tree_vis.data(species_details['trees'][tree_type]['objects'][species_filter]);

                    //check if node is part of a species with strains (expand_strains is the key) and if it is, show the strains when clicked                    
                    if(tree_vis.root().data().name && species_info[tree_vis.root().data().name]['expand_strains']) {
                      tree_vis.root().apply(function (node) {
                        if(node.is_leaf() ) {
                          if(node.is_collapsed()) { node.toggle(); }

                          //removing reference species from strains list
                          if(node.data().name.match(/reference/g)) {
                            var strain_data = node.parent().data();
                            var new_children = [];
                            strain_data.children.forEach(function(d) {
                              if (species_info[d.name].name && !d.name.match(/reference/g)) {
                                new_children.push(d);
                              }
                            });
                            strain_data.children = new_children;
                          }
                        }
                      });
                    } else { //just a precaution to collapse the nodes again not to show the strains
                      tree_vis.root().apply(function (node) {
                        if(species_info[node.data().name] && species_info[node.data().name]['has_strain'] && !node.is_collapsed()) { node.toggle(); }
                      });                      
                    }
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
          
      var layout_switch_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "layout_switch")
          .attr("title", "Switch between radial and vertical")
          .on("click", function() {
            if (d3.select(".layout_switch_menu").style("display") === 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".toolbar_menu").each(function(d, i) {
                d3.select(this).style("display", "none");
              });

              d3.select(".layout_switch_menu").style("display", "block");
            } else {
              d3.select(".layout_switch_menu").style("display", "none");
            }
          });

      var layout_switch_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "toolbar_menu layout_switch_menu")
          .on("click", function() {
            var current_width = Math.floor(d3.select("#species_tree").style("width").replace(/px/g, "") / 100) * 100;
            var selected_layout = d3.select(".layout_switch_menu_vertical").classed("current") ? "radial" : "vertical";

            if (selected_layout === "radial") {
              tree_vis.layout(tnt.tree.layout.radial().width(current_width).scale(scale)).duration(1000);
            } else {
              tree_vis.layout(tnt.tree.layout.vertical().width(current_width).scale(scale)).duration(1000);
            }

            update_layout_switch_menu(selected_layout);
            
            tree_vis.update();
          });
      
      draw_layout_switch_menu();

      var species_name_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "species_name_type")
          .attr("title", "Switch between scientific and common name")
          .on("click", function() {
            if (d3.select(".species_name_menu").style("display") === 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".toolbar_menu").each(function(d, i) {
                d3.select(this).style("display", "none");
              });


              d3.select(".species_name_menu").style("display", "block");
            } else {
              d3.select(".species_name_menu").style("display", "none");
            }
          });

      var species_name_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "toolbar_menu species_name_menu")
          .on("click", function() {
            var previous_species_name_type = d3.select(".species_name_menu_scientific").classed("current") ? "scientific" : "common";
            var current_species_name_type = previous_species_name_type === "scientific" ? "common" : "scientific";

            update_species_name_menu(current_species_name_type);

            tree_vis.update();
          });
  
      draw_species_name_menu();
          
      var resize_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "resize")
          .attr("title", "Resize this image")
          .on("click",function(){
            if(d3.select(".resize_menu").style("display") == 'none') {
              //just making sure all other menu are closed
              d3.selectAll(".toolbar_menu").each(function(d,i) {
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


      var export_menu = d3.select("#species_tree")
          .append("div")
          .attr("class", "toolbar_menu export_menu");

      export_menu.append("div")
          .attr("class", "header")
          .text("Choose download type");


      $.each(['Newick', 'PNG'], function(i, type) {
        export_menu.append("div")
          .attr("class", "Export_" + type)
          .text(type)
          .on("click", function(){
            var svgElement = $($('.js_tree'));
            svgExport(svgElement[0], type, this);
           });
      });

      $.when(_jspdf).done(function() {
        export_menu.append("div")
          .attr("class", "Export_PDF")
          .text('PDF')
          .on("click", function(){
            var svgElement = $($('.js_tree'));
            svgExport(svgElement[0], 'PDF', this);
          });
      })

      var export_icon = d3.select(".image_toolbar")
          .append("div")
          .attr("class", "export")
          .attr("title", "Export tree")
          .on("click", function() {
              if(d3.select(".export_menu").style("display") == 'none') {
                //just making sure all other menu are closed
                d3.selectAll(".toolbar_menu").each(function(d,i) {
                  d3.select(this).style("display", "none");
                });
                d3.select(".export_menu").style("display", "block");
              } else {
                d3.select(".export_menu").style("display", "none");
              }
          });

      var image_label = tnt.tree.label.img()
          .src(function(d) {
            if(d.is_leaf()) {
              return species_info[d.data().name]['icon'];
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
        var obj      = {};
        obj.header   = "Scientific Name: " + node.node_name();
        obj.rows     = [];
        var home_url = species_info[node.node_name()]['is_strain'] ? '/' + species_info[node.node_name()]['is_strain'] + '/Info/Strains' : '/' + species_info[node.node_name()]['ensembl_name']+'/Info/Index';

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
            value : '<a href="' + home_url + '" title="Click to go to species homepage">'+species_info[node.node_name()]['ensembl_name']+'</a>'
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
      for(var j in species_details['trees']) {

          var root_node = tnt.tree.node(tnt.tree.parse_newick(species_details['trees'][j]['newick'])); //making the tree object for each tree
          
          root_node.sort(function(node1, node2) { return species_info[node1.node_name()]['taxon_id'] - species_info[node2.node_name()]['taxon_id']; }); //sorting the tree obj based on taxonid
          
          species_details['trees'][j]['objects'] = {'all': root_node.data()};

          //populating the species_details obj with all possible trees
          for(var k in species_details['filters']) {
              species_details['trees'][j]['objects'][k] = root_node.find_node_by_name(k).data();
          }
          
          var hash = {};
          root_node.apply(function (node){
      
        if(hash[node.node_name()] == undefined ) { 
            hash[node.node_name()] = 1;
            node.property("unique_name", node.node_name());
        } else {        
          node.property("unique_name", node.node_name() + "_" + hash[node.node_name()]);
          hash[node.node_name()]++;
        }

          });
      }

      tree_vis
        .data(species_details['trees'][species_details['default_tree']]['objects']['all'], species_info)
        .id(function (node) { return node.unique_name; })
        .label(joined_label)
        .node_display(tree_vis.node_display().size(4))
        .on("click", node_tooltip)
	      .branch_color("black")
	      .layout(tnt.tree.layout.vertical()
          .width(width)
		      .scale(scale)
		    );
    
      var root = tree_vis.root();
      root.apply(function (node) {        
        //hiding strains (if node has strain then toggle it to hide the strains)
        if (node.data().name && species_info[node.data().name]['has_strain']) { node.toggle();}
      });
      
    	tree_vis(div);       
      d3.select(".image_toolbar").append("div").attr("class", "tree_label").text("Ensembl Species tree");
    }

    return tnt_theme;
};

  
