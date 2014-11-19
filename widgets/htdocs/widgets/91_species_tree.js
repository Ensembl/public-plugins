var tnt_theme_tree_simple_species_tree = function(ncbi_tree) {
    "use strict";

    var pics_path     = "/i/species/48/";
    var width         = Math.floor(d3.select("#species_tree").style("width").replace(/px/g,'') / 100) * 100;
    var scale         = false;

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
                tree_vis.data(tnt.tree.parse_newick(ncbi_tree));
                tree_vis.update();
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
                tree_vis.data(tnt.tree.parse_newick(newick));
                tree_vis.update();
                d3.select(".tree_menu").style("display", "none");
              }
          });

      d3.select("#species_tree").append("div").attr("class", "image_resize_menu resize_menu");
      draw_resize_menu(width);

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
              var pic_name = ncbi_tree ? d.data().name.replace(/\s/g,'_') : d.data.name;
              return pics_path + pic_name + ".png";
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
              return node.node_name().replace(/_/g,' '); 
            } 
          }).fontsize(14);

      // The joined label shows a picture + the common name
      var joined_label = tnt.tree.label.composite()
        .add_label(image_label)
        .add_label(original_label);

	    tree_vis
	      .data(tnt.tree.parse_newick(newick))
        .label(joined_label)
	      .node_circle_size(2)
	      .node_color("black")
	      .link_color("black")
	      .layout(tnt.tree.layout.vertical()
          .width(width)
		      .scale(scale)
		    );

    	tree_vis(div);
    };

    return tnt_theme;
};

// newick tree
var newick = "(((Drosophila_melanogaster:1,Caenorhabditis_elegans:1):1,((Ciona_intestinalis:1,Ciona_savignyi:1):1,(((((((((Taeniopygia_guttata:1,Ficedula_albicollis:1):1,((Meleagris_gallopavo:1,Gallus_gallus:1):1,Anas_platyrhynchos:1):1):1,Pelodiscus_sinensis:1):1,Anolis_carolinensis:1):1,((((((Procavia_capensis:1,Loxodonta_africana:1):1,Echinops_telfairi:1):1,(Choloepus_hoffmanni:1,Dasypus_novemcinctus:1):1):1,((((Oryctolagus_cuniculus:1,Ochotona_princeps:1):1,((((Mus_musculus:1,Rattus_norvegicus:1):1,Dipodomys_ordii:1):1,Ictidomys_tridecemlineatus:1):1,Cavia_porcellus:1):1):1,(((Microcebus_murinus:1,Otolemur_garnettii:1):1,(((((Papio_anubis:1,Macaca_mulatta:1):1,Chlorocebus_sabaeus:1):1,((((Pan_troglodytes:1,Homo_sapiens:1):1,Gorilla_gorilla:1):1,Pongo_abelii:1):1,Nomascus_leucogenys:1):1):1,Callithrix_jacchus:1):1,Tarsius_syrichta:1):1):1,Tupaia_belangeri:1):1):1,((Sorex_araneus:1,Erinaceus_europaeus:1):1,(((Pteropus_vampyrus:1,Myotis_lucifugus:1):1,((((Mustela_putorius_furo:1,Ailuropoda_melanoleuca:1):1,Canis_familiaris:1):1,Felis_catus:1):1,Equus_caballus:1):1):1,((((Bos_taurus:1,Ovis_aries:1):1,Tursiops_truncatus:1):1,Vicugna_pacos:1):1,Sus_scrofa:1):1):1):1):1):1,((Macropus_eugenii:1,Sarcophilus_harrisii:1):1,Monodelphis_domestica:1):1):1,Ornithorhynchus_anatinus:1):1):1,Xenopus_tropicalis:1):1,Latimeria_chalumnae:1):1,(((Danio_rerio:1,Astyanax_mexicanus:1):1,(((Tetraodon_nigroviridis:1,Takifugu_rubripes:1):1,((((Poecilia_formosa:1,Xiphophorus_maculatus:1):1,Oryzias_latipes:1):1,Gasterosteus_aculeatus:1):1,Oreochromis_niloticus:1):1):1,Gadus_morhua:1):1):1,Lepisosteus_oculatus:1):1):1,Petromyzon_marinus:1):1):1):1,Saccharomyces_cerevisiae:1);"

