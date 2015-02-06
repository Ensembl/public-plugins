Ensembl.CafeTree = {};

Ensembl.CafeTree.displayTree = function(json,species_name, panel) {
  var tree_vis = tnt.tree();  
  var theme = Ensembl.CafeTree.tnt_theme_tree_cafe_tree()
                 .json_data(json)
                 .highlight(species_name);
  theme(tree_vis, document.getElementById('widget'), panel);  
};

Ensembl.CafeTree.tnt_theme_tree_cafe_tree = function() {
    "use strict";

    var json_data;
    var full;
    var lca;
    var color_grad;
    var min_n_members, max_n_members;
    var highlight;
    
    var width = Math.floor(d3.select("#widget").style("width").replace(/px/g,'') / 100) * 100;
    var pics_path = "/i/species/48/";

    var theme = function (tree_vis, div, panel) {
    
        var icons_classes = ["tree_switch", "layout_switch vertical", "resize"];        
        panel.imageToolbar(tree_vis, icons_classes);    //drawing the main toolbar and adding the icons, icons functionality below    
                
        // Switch between full tree and minimal tree
        var tree_icon = d3.select(".tree_switch")          
          .attr("title", "Choose between Full and Minimal tree")
          .on("click", function() {
              if(d3.select(".tree_menu").style("display") == 'none') {
                //just making sure all other menu are closed
                d3.selectAll(".iexport_menu").each(function(d,i) {
                  d3.select(this).style("display", "none");
                  d3.select(".iexport_menu").style("display", "none");
                  d3.select(".share_page").style("display", "none");
                });
                d3.select(".tree_menu").style("display", "block");
              } else {
                d3.select(".tree_menu").style("display", "none");
              }
          });
      var tree_menu = d3.select("#widget")
          .append("div")
          .attr("class", "iexport_menu tree_menu d3_menu");

      tree_menu.append("div")
          .attr("class", "header")
          .text("Choose tree");

      tree_menu.append("div")
          .attr("class", "full current")
          .text("Full Tree")
          .on("click", function() {
              if(d3.select(".full").attr("class").match(/current/g)) {
                d3.select(".tree_menu").style("display", "none");
                return;
              } else {
                d3.select(".full").classed("current", true);
                d3.select(".minimal").classed("current", false);
                tree_vis.data(full.data());
                // We also expand all parts of the tree that are collapsed
                var root = tree_vis.root();
                root.apply (function (node) {
                    if (node.is_collapsed()) {
                        node.toggle();
                    }
                });
                tree_vis.update();
                update_tree_label();
                d3.select(".tree_menu").style("display", "none");
              }
          });

      tree_menu.append("div")
          .attr("class", "minimal")
          .text("Minimal Tree")
          .on("click", function() {
              if(d3.select(".minimal").attr("class").match(/current/g)) {
                d3.select(".tree_menu").style("display", "none");
                return; 
              } else {
                d3.select(".minimal").classed("current", true);
                d3.select(".full").classed("current", false); 
                tree_vis.data(lca.data());
                // We also collapse all parts of the tree without members
                var root = tree_vis.root();
                root.apply (function (node) {
                    var has_members = false;
                    node.apply (function (n) {
                        if (n.property('n_members') > 0) {
                            has_members = true;
                        }
                    });
                    if (!node.is_leaf() && !has_members) {
                        node.toggle();
                    }
                });
                tree_vis.update();
                update_tree_label();
                d3.select(".tree_menu").style("display", "none");
              }
          });          

        // Label object for the tree
         var image_label = tnt.tree.label.img()          
          .src(function(d) {
            if(d.is_leaf()) {
              var species_icon = d.data().name.replace(/\./g,'_').substring(0, 1).toUpperCase() + d.data().name.replace(/\./g,'_').substring(1);  //capitalize first letter
              return d.is_collapsed() ? "" : pics_path + species_icon + ".png"; //don't return an img path for collapsed node as we dont have image for them
            }
          })
          .width(function() {
            return 30;
          })
          .height(function() {
            return 40;
          }); 
          
        var node_label = tnt.tree.label.text()
	        .color(function (node) {
            var d = node.data();
		        if (d.n_members === 0) {
		            return 'lightgrey'
		        }
            if (d.tax.scientific_name === highlight) {            
              return "red";
            }
		        return 'black';
	        })
          .text(function (node) {
            return node.data().n_members;
          })
          .fontsize(14);
        
      var root = tnt.tree.node(json_data.tree);
      var max_width_text1 = d3.max(root.get_all_leaves(), function (node) {
          return node_label.width()(node);
      });          
      
      var species_label = tnt.tree.label.text()
          .color(function (node) {
            var d = node.data();
		        if (d.n_members === 0) {
		            return 'lightgrey'
		        }
            if (d.tax.scientific_name === highlight) {            
              return "red";
            }
		        return 'black';          
          })
          .text(function (node) {
            if(node.is_leaf()) {
              return node.data().tax.alias_name;
            }
          })          
          .fontsize(14);
          
      var label = tnt.tree.label.composite()        
        .add_label(node_label.width(function () {return max_width_text1}))
        .add_label(image_label)
        .add_label(species_label);
	      
	    var cafe_tooltip = function (node) {
	        var node_data = node.data();
	        var obj = {};
          obj.header = "Taxon: " + node_data.tax.alias_name + (node_data.tax.timetree_mya ? (" ~ " + node_data.tax.timetree_mya + " MYA " ) : " ") + "(" + node_data.tax.scientific_name + ")";
          
	        obj.rows = [
		        { label : "Node ID",
		          value : node_data.id
		        },
		        { label : "Members",
		          value : node_data.n_members
		        },
		        { label : "p-value",
		          value : node_data.pvalue
		        },
		        { label : "Lambda",
		          value : node_data.lambda
		        },
		        { label : "Taxon ID",
		          value : node_data.tax.id
		        },
		        { label : "Scientific Name",
		          value : node_data.tax.scientific_name
		        }          
	        ];
          if (node.is_collapsed()) {
            obj.rows.push ({
              label : 'Action',
              link : function (node) {
                node.toggle();
                tree_vis.update();
              },
              obj : node,
              value : "Expand subtree"
            });
          }
          if (!node.is_leaf() && node.parent()) {
            obj.rows.push ({
              label : 'Action',
              link : function (node) {
                node.toggle();
                tree_vis.update();
              },
              obj : node,
              value : "Collapse subtree"
            });
            if (!tree_vis.has_focus (node)) {
              obj.rows.push ({
                label : "Action",
                link : function (node) {
                  tree_vis.focus_node(node).update();
                  tree_vis.update();
                },
                obj : node,
                value : "Focus on node"
              });            
            }
          }
          if (tree_vis.has_focus (node)) {
            obj.rows.push ({
              label : "Action",
              link : function (node) {
                tree_vis.release_focus();
                tree_vis.update();
              },
              obj : node,
              value : "Release focus"
            });
          }          
	        tnt.tooltip.table().id(node.id()).width(210).call(this, obj);
	    };

	    // TREE SIDE
	    var deploy_vis = function (tree_obj) { 
          if (tree_obj.pvalue_avg > 0.5) {
              d3.select(".info")
                  .append("h3")
                  .html("Info");
                  
              d3.select(".info")
                  .append("div")
                  .attr("class", "message-pad")
                  .append("p")
                  .html("This gene family does not have any significant gene gain or loss events (<i>pvalue</i> for the gene family is <b>" + tree_obj.pvalue_avg + "</b>).Click the tree nodes or the icons on the image blue bar to interact with the tree.");
          } else {
              d3.select(".info")
                  .append("h3")
                  .html("Info");
                  
              d3.select(".info")                    
                  .append("div")
                  .attr("class", "message-pad")
                  .append("p")
                  .html("This gene family has significant gene gain or loss events. Click the tree nodes or the icons on the image blue bar to interact with the tree.");
          }
          
          var expanded_node = tnt.tree.node_display.circle()
              .fill (function (node) {
                var n_genes = node.property('n_members'); // get the number of genes for a given node
                return n_genes === 0 ? "lightgrey" : color_grad(n_genes);
              });
              
          var collapsed_node = tnt.tree.node_display.triangle()              
              .fill (function (node) {
                var n_genes = node.property('n_members'); // get the number of genes for a given node
                return n_genes === 0 ? "lightgrey" : color_grad(n_genes);
              });

          var node_display = tnt.tree.node_display.cond()
              .add("collapsed", function (node) {
                return node.is_collapsed();
              }, collapsed_node)
              .add("rest", function () {
                return true;
              }, expanded_node);
              
          var root = tnt.tree.node(tree_obj.tree);
          root.sort(function(node1, node2) { return node1.data().tax.id - node2.data().tax.id; }); //sorting the tree obj based on taxonid
                    
	        tree_vis
            .node_display(node_display)
		        .data (root.data())
		        .label (label)
            .on_click (cafe_tooltip)
		        .link_color (function (from_node, to_node) {
		            var target  = to_node.data();
		            if (target && target.is_node_significant && target.n_members != 0) {
			            if (target.is_expansion) {
			                return "red";
			            } else {
			                return "green";
			            }
		            }
		            if (target.n_members === 0) {
			            return "lightgrey";
		            }
		            return "black";
		        })
		        .layout (tnt.tree.layout.vertical()
                    .width(width)                   
                    .scale(false)
			      );
		        
            // Calculate the n_members range
            var n_members_array = [];
            tree_vis.root().apply (function (node) {
                var n_members = node.property('n_members');
                if (n_members !== 0) {
                    n_members_array.push(n_members);
                }
            });
            var members_extent = d3.extent(n_members_array);
            
            min_n_members = members_extent[0];
            max_n_members = members_extent[1];
            
            color_grad = d3.scale.linear()
                .domain(members_extent)
                .range(["green", "red"]);

            // Calculate lca to use it in the Minimal Tree
            full = tree_vis.root();
            var present_leaves = full.get_all_leaves().filter(function (leaf) {return leaf.data().n_members > 0});
            lca = full.lca(present_leaves);

	        tree_vis(div);
	    }

        deploy_vis(json_data);
        update_tree_label();
 
        // We add the legend
        d3.select(div)
          .append("div")
          .append("svg")
          .attr("width", width)
          .attr("height", 150)
          .append("g")
          .call(legend()
                .min(min_n_members)
                .max(max_n_members)
               );

    }

    theme.json_data = function (str) {
        if (!arguments.length) {
            return json_data;
        }
        json_data = str;
        return theme;
    };

    theme.highlight = function (sp) {
        if (!arguments.length) {
            return highlight;
        }
        highlight = sp;
        return theme;
    };
    
    function update_tree_label() {
      var full_minimal  = d3.select(".tree_menu").select(".current").text().replace(/\sTree/g,'');     
      var new_label = full_minimal + " tree";
      d3.select(".tree_label").text(new_label);
    }    

    var legend = function () {
      var min, max;
      var l = function () {
        var svg = this;

        // Draw separator line
        var separator = svg
          .append("g")
          .attr("transform", "translate(10,10)");
            
        separator
          .append("line")
          .attr("x1", 0)
          .attr("y1", 0)
          .attr("x2", width)
          .attr("y2", 0)
          .attr("stroke", "black")
          .attr("class", "legend-line")
          .attr("stroke-width", 0.5);
        
        separator
          .append("text")
          .attr("x", 0)
          .attr("y", 15)
          .text("LEGEND")
          .style("font-weight", "bold");
            
        // -- branch. No significant change
        var branch_no_change = svg
          .append("g")
          .attr("transform", "translate(10,45)");
        branch_no_change
          .append("line")
          .attr("x1", 0)
          .attr("y1", 0)
          .attr("x2", 20)
          .attr("y2", 0)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        branch_no_change
          .append("text")
          .attr("x", 25)
          .attr("y", 5)
          .text("No significant change");

        // -- branch. Expansion
        var branch_expansion = svg
          .append("g")
          .attr("transform", "translate(10,65)");

        branch_expansion
          .append("line")
          .attr("x1", 0)
          .attr("y1", 0)
          .attr("x2", 20)
          .attr("y2", 0)
          .attr("stroke", "red")
          .attr("stroke-width", 2);

        branch_expansion
          .append("text")
          .attr("x", 25)
          .attr("y", 5)
          .text("Significant Expansion");

        // -- branch. Contraction
        var branch_contraction = svg
          .append("g")
          .attr("transform", "translate(10,85)");

        branch_contraction
          .append("line")
          .attr("x1", 0)
          .attr("y1", 0)
          .attr("x2", 20)
          .attr("y2", 0)
          .attr("stroke", "green")
          .attr("stroke-with", 2);

        branch_contraction
          .append("text")
          .attr("x", 25)
          .attr("y", 5)
          .text("Significant Contraction");

        // -- Internal Nodes. Number of members
        var n_members = svg
          .append("g")
          .attr("transform", "translate(10,97)");

        n_members
          .append("line")
          .attr("x1", 0)
          .attr("y1", 10)
          .attr("x2", 10)
          .attr("y2", 10)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        n_members
          .append("line")
          .attr("x1", 10)
          .attr("y1", 10)
          .attr("x2", 10)
          .attr("y2", 0)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        n_members
          .append("line")
          .attr("x1", 10)
          .attr("y1", 0)
          .attr("x2", 20)
          .attr("y2", 0)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        n_members
          .append("line")
          .attr("x1", 10)
          .attr("y1", 10)
          .attr("x2", 10)
          .attr("y2", 20)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        n_members
          .append("line")
          .attr("x1", 10)
          .attr("y1", 20)
          .attr("x2", 20)
          .attr("y2", 20)
          .attr("stroke", "black")
          .attr("stroke-width", 2);

        n_members
          .append("text")
          .attr("x", 15)
          .attr("y", 12)
          .attr("font-size", 9)
          .text("N");

        n_members
          .append("text")
          .attr("x", 25)
          .attr("y", 15)
          .text("Number of Members");

        // Nodes with zero members
        var zero_members = svg
          .append("g")
          .attr("transform", "translate(250,45)")

        zero_members
          .append("circle")
          .attr("r", 5)
          .attr("fill", "lightgrey");

        zero_members
          .append("text")
          .attr("x", 10)
          .attr("y", 5)
          .text("Nodes with 0 members");

        // Minimum number of Members
        var min_members = svg
          .append("g")
          .attr("transform", "translate(250, 65)");

        min_members
          .append("circle")
          .attr("r", 5)
          .attr("fill", "green");

        min_members
          .append("text")
          .attr("x", 10)
          .attr("y", 5)
          .text("Nodes with " + min + " members");

        // Maximum number of members
        var max_members = svg
          .append("g")
          .attr("transform", "translate(250, 85)");

        max_members
          .append("circle")
          .attr("r", 5)
          .attr("fill", "red");

        max_members
          .append("text")
          .attr("x", 10)
          .attr("y", 5)
          .text("Nodes with " + max + " members");

        // Species No Members
        var species_no_members = svg
          .append("g")
          .attr("transform", "translate(500, 45)");

        species_no_members
          .append("text")
          .attr("x", 0)
          .attr("y", 5)
          .style("fill", "lightgrey")
          .text("Species");

        species_no_members
          .append("text")
          .attr("x", 70)
          .attr("y", 5)
          .text("Species with no genes");

        // Species Interest
        var species_interest = svg
          .append("g")
          .attr("transform", "translate(500, 65)");

        species_interest
          .append("text")
          .attr("x", 0)
          .attr("y", 5)
          .style("fill", "red")
          .text("Species");

        species_interest
          .append("text")
          .attr("x", 70)
          .attr("y", 5)
          .text("Queried species");
    };

    l.min = function (val) {
      min = val
      return l;
    };

    l.max = function (val) {
      max = val;
      return l;
    }
    return l;
  };
    return theme;
};

