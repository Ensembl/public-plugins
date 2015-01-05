Ensembl.NewTree = Base.extend({
  constructor: function(tree_id) { 
    this.tree_id = d3.select(tree_id);      
  },

  /*
    drawing the image toolbar, already have resize functionality if resize class pass through
    classes are icon classes that you want on the toolbar. The icon functionality should be in each view unless it is a generic one and can go in here
  */
  imageToolbar: function(tree_id, tree_obj, classes) {
    var tree       = this;
    var tree_id    = d3.select(tree_id);    
    var width      = Math.floor(tree_id.style("width").replace(/px/g,'') / 100) * 100; 
    var menu_panel = tree_id.append("div").attr("class", "image_toolbar");   
    
    //adding classes for the other icons
    for	(var i = 0; i < classes.length; i++) {
      d3.select(".image_toolbar").append("div").attr("class", classes[i]);
    };    
    d3.select(".image_toolbar").append("div").attr("class", "tree_label");
    
    if($(".resize").length) {    
      tree_id.append("div").attr("class", "image_resize_menu resize_menu");    
      tree.drawResizeMenu(width);   
          
      menu_panel.select(".resize")
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
                  var current_width = Math.floor(tree_id.style("width").replace(/px/g,'') / 100) * 100;
                  var selection = d3.select(this).text();
                  if(selection != "Resize image width" && selection != (current_width + " px")) {
                    var new_width = parseInt(selection.replace(/\spx/g,''));
                    
                    tree_obj.layout().width(new_width);
                    tree_obj.update();
                    d3.select("svg").attr("width", new_width + "px");
                    tree_id.style("width", new_width + "px");
                    d3.select(".tnt_groupDiv").style("width", new_width + "px");
                    d3.select(".resize_menu").style("display", "none");
                    tree.drawResizeMenu(new_width);
                  }                  
                })
            });      

          } else {
            d3.select(".resize_menu").style("display", "none");
          }
        });
    };
    
    if($(".layout_switch").length) {
      menu_panel.select(".layout_switch")
        .attr("id", "switch")
        .attr("title", "Switch between radial and vertical")
        .on("click", function() {
          var pos           = d3.select("#switch").attr("class");
          var current_width =  Math.floor(tree_id.style("width").replace(/px/g,'') / 100) * 100;

          //just making sure all other menu are closed
          d3.selectAll(".image_resize_menu").each(function(d,i) {
            d3.select(this).style("display", "none");
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
  }

});
