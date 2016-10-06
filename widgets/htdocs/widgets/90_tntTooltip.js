(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
if (typeof tnt === "undefined") {
    module.exports = tnt = {};
}
tnt.tooltip = require("./index.js");

},{"./index.js":2}],2:[function(require,module,exports){
module.exports = tooltip = require("./src/tooltip.js");

},{"./src/tooltip.js":5}],3:[function(require,module,exports){
module.exports = require("./src/api.js");

},{"./src/api.js":4}],4:[function(require,module,exports){
var api = function (who) {

    var _methods = function () {
	var m = [];

	m.add_batch = function (obj) {
	    m.unshift(obj);
	};

	m.update = function (method, value) {
	    for (var i=0; i<m.length; i++) {
		for (var p in m[i]) {
		    if (p === method) {
			m[i][p] = value;
			return true;
		    }
		}
	    }
	    return false;
	};

	m.add = function (method, value) {
	    if (m.update (method, value) ) {
	    } else {
		var reg = {};
		reg[method] = value;
		m.add_batch (reg);
	    }
	};

	m.get = function (method) {
	    for (var i=0; i<m.length; i++) {
		for (var p in m[i]) {
		    if (p === method) {
			return m[i][p];
		    }
		}
	    }
	};

	return m;
    };

    var methods    = _methods();
    var api = function () {};

    api.check = function (method, check, msg) {
	if (method instanceof Array) {
	    for (var i=0; i<method.length; i++) {
		api.check(method[i], check, msg);
	    }
	    return;
	}

	if (typeof (method) === 'function') {
	    method.check(check, msg);
	} else {
	    who[method].check(check, msg);
	}
	return api;
    };

    api.transform = function (method, cbak) {
	if (method instanceof Array) {
	    for (var i=0; i<method.length; i++) {
		api.transform (method[i], cbak);
	    }
	    return;
	}

	if (typeof (method) === 'function') {
	    method.transform (cbak);
	} else {
	    who[method].transform(cbak);
	}
	return api;
    };

    var attach_method = function (method, opts) {
	var checks = [];
	var transforms = [];

	var getter = opts.on_getter || function () {
	    return methods.get(method);
	};

	var setter = opts.on_setter || function (x) {
	    for (var i=0; i<transforms.length; i++) {
		x = transforms[i](x);
	    }

	    for (var j=0; j<checks.length; j++) {
		if (!checks[j].check(x)) {
		    var msg = checks[j].msg || 
			("Value " + x + " doesn't seem to be valid for this method");
		    throw (msg);
		}
	    }
	    methods.add(method, x);
	};

	var new_method = function (new_val) {
	    if (!arguments.length) {
		return getter();
	    }
	    setter(new_val);
	    return who; // Return this?
	};
	new_method.check = function (cbak, msg) {
	    if (!arguments.length) {
		return checks;
	    }
	    checks.push ({check : cbak,
			  msg   : msg});
	    return this;
	};
	new_method.transform = function (cbak) {
	    if (!arguments.length) {
		return transforms;
	    }
	    transforms.push(cbak);
	    return this;
	};

	who[method] = new_method;
    };

    var getset = function (param, opts) {
	if (typeof (param) === 'object') {
	    methods.add_batch (param);
	    for (var p in param) {
		attach_method (p, opts);
	    }
	} else {
	    methods.add (param, opts.default_value);
	    attach_method (param, opts);
	}
    };

    api.getset = function (param, def) {
	getset(param, {default_value : def});

	return api;
    };

    api.get = function (param, def) {
	var on_setter = function () {
	    throw ("Method defined only as a getter (you are trying to use it as a setter");
	};

	getset(param, {default_value : def,
		       on_setter : on_setter}
	      );

	return api;
    };

    api.set = function (param, def) {
	var on_getter = function () {
	    throw ("Method defined only as a setter (you are trying to use it as a getter");
	};

	getset(param, {default_value : def,
		       on_getter : on_getter}
	      );

	return api;
    };

    api.method = function (name, cbak) {
	if (typeof (name) === 'object') {
	    for (var p in name) {
		who[p] = name[p];
	    }
	} else {
	    who[name] = cbak;
	}
	return api;
    };

    return api;
    
};

module.exports = exports = api;
},{}],5:[function(require,module,exports){
var apijs = require("tnt.api");

var tooltip = function () {
    "use strict";

    var drag = d3.behavior.drag();
    var tooltip_div;

    var conf = {
	position : "right",
	allow_drag : true,
	show_closer : true,
	fill : function () { throw "fill is not defined in the base object"; },
	width : 180,
	id : 1
    };

    var t = function (data, event) {
	drag
	    .origin(function(){
		return {x:parseInt(d3.select(this).style("left")),
			y:parseInt(d3.select(this).style("top"))
		       };
	    })
	    .on("drag", function() {
		if (conf.allow_drag) {
		    d3.select(this)
			.style("left", d3.event.x + "px")
			.style("top", d3.event.y + "px");
		}
	    });

	// TODO: Why do we need the div element?
	// It looks like if we anchor the tooltip in the "body"
	// The tooltip is not located in the right place (appears at the bottom)
	// See clients/tooltips_test.html for an example
	var containerElem = selectAncestor (this, "div");
	if (containerElem === undefined) {
	    // We require a div element at some point to anchor the tooltip
	    return;
	}

	tooltip_div = d3.select(containerElem)
	    .append("div")
	    .attr("class", "tnt_tooltip")
	    .classed("tnt_tooltip_active", true)  // TODO: Is this needed/used???
	    .call(drag);

	// prev tooltips with the same header
	d3.select("#tnt_tooltip_" + conf.id).remove();

	if ((d3.event === null) && (event)) {
	    d3.event = event;
	}
	var d3mouse = d3.mouse(containerElem);
	d3.event = null;

	var offset = 0;
	if (conf.position === "left") {
	    offset = conf.width;
	}

	tooltip_div.attr("id", "tnt_tooltip_" + conf.id);

	// We place the tooltip
	tooltip_div
	    .style("left", (d3mouse[0]) + "px")
	    .style("top", (d3mouse[1]) + "px");

	// Close
    if (conf.show_closer) {
        tooltip_div
            .append("div")
            .attr("class", "tnt_tooltip_closer")
            .on ("click", function () {
                t.close();
            })
    }

	conf.fill.call(tooltip_div, data);

	// return this here?
	return t;
    };

    // gets the first ancestor of elem having tagname "type"
    // example : var mydiv = selectAncestor(myelem, "div");
    function selectAncestor (elem, type) {
	type = type.toLowerCase();
	if (elem.parentNode === null) {
	    console.log("No more parents");
	    return undefined;
	}
	var tagName = elem.parentNode.tagName;

	if ((tagName !== undefined) && (tagName.toLowerCase() === type)) {
	    return elem.parentNode;
	} else {
	    return selectAncestor (elem.parentNode, type);
	}
    }

    var api = apijs(t)
	.getset(conf);
    api.check('position', function (val) {
	return (val === 'left') || (val === 'right');
    }, "Only 'left' or 'right' values are allowed for position");

    api.method('close', function () {
        if (tooltip_div) {
            tooltip_div.remove();
        }
    });

    return t;
};

tooltip.list = function () {
    // list tooltip is based on general tooltips
    var t = tooltip();
    var width = 180;

    t.fill (function (obj) {
	var tooltip_div = this;
	var obj_info_list = tooltip_div
	    .append("table")
	    .attr("class", "tnt_zmenu")
	    .attr("border", "solid")
	    .style("width", t.width() + "px");

	// Tooltip header
    if (obj.header) {
        obj_info_list
	       .append("tr")
	       .attr("class", "tnt_zmenu_header")
           .append("th")
           .text(obj.header);
    }

	// Tooltip rows
	var table_rows = obj_info_list.selectAll(".tnt_zmenu_row")
	    .data(obj.rows)
	    .enter()
	    .append("tr")
	    .attr("class", "tnt_zmenu_row");

	table_rows
	    .append("td")
	    .style("text-align", "center")
	    .html(function(d,i) {
		return obj.rows[i].value;
	    })
	    .each(function (d) {
		if (d.link === undefined) {
		    return;
		}
		d3.select(this)
		    .classed("link", 1)
		    .on('click', function (d) {
			d.link(d.obj);
			t.close.call(this);
		    });
	    });
    });
    return t;
};

tooltip.table = function () {
    // table tooltips are based on general tooltips
    var t = tooltip();

    var width = 180;

    t.fill (function (obj) {
	var tooltip_div = this;

	var obj_info_table = tooltip_div
	    .append("table")
	    .attr("class", "tnt_zmenu")
	    .attr("border", "solid")
	    .style("width", t.width() + "px");

	// Tooltip header
    if (obj.header) {
        obj_info_table
            .append("tr")
            .attr("class", "tnt_zmenu_header")
            .append("th")
            .attr("colspan", 2)
            .text(obj.header);
    }

	// Tooltip rows
	var table_rows = obj_info_table.selectAll(".tnt_zmenu_row")
	    .data(obj.rows)
	    .enter()
	    .append("tr")
	    .attr("class", "tnt_zmenu_row");

	table_rows
	    .append("th")
	    .attr("colspan", function (d, i) {
		if (d.value === "") {
		    return 2;
		}
		return 1;
	    })
	    .attr("class", function (d) {
		if (d.value === "") {
		    return "tnt_zmenu_inner_header";
		}
		return "tnt_zmenu_cell";
	    })
	    .html(function(d,i) {
		return obj.rows[i].label;
	    });

	table_rows
	    .append("td")
	    .html(function(d,i) {
		if (typeof obj.rows[i].value === 'function') {
		    obj.rows[i].value.call(this, d);
		} else {
		    return obj.rows[i].value;
		}
	    })
	    .each(function (d) {
		if (d.value === "") {
		    d3.select(this).remove();
		}
	    })
	    .each(function (d) {
		if (d.link === undefined) {
		    return;
		}
		d3.select(this)
		    .classed("link", 1)
		    .on('click', function (d) {
			d.link(d.obj);
			t.close.call(this);
		    });
	    });
    });

    return t;
};

tooltip.plain = function () {
    // plain tooltips are based on general tooltips
    var t = tooltip();

    t.fill (function (obj) {
	var tooltip_div = this;

	var obj_info_table = tooltip_div
	    .append("table")
	    .attr("class", "tnt_zmenu")
	    .attr("border", "solid")
	    .style("width", t.width() + "px");

    if (obj.header) {
        obj_info_table
            .append("tr")
            .attr("class", "tnt_zmenu_header")
            .append("th")
            .text(obj.header);
    }

    if (obj.body) {
        obj_info_table
            .append("tr")
            .attr("class", "tnt_zmenu_row")
            .append("td")
            .style("text-align", "center")
            .html(obj.body);
    }
    });

    return t;
};

module.exports = exports = tooltip;

},{"tnt.api":3}]},{},[1])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudG9vbHRpcC9ub2RlX21vZHVsZXMvZ3VscC1icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRvb2x0aXAvZmFrZV9kZjA5MTU4ZS5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudG9vbHRpcC9pbmRleC5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudG9vbHRpcC9ub2RlX21vZHVsZXMvdG50LmFwaS9pbmRleC5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudG9vbHRpcC9ub2RlX21vZHVsZXMvdG50LmFwaS9zcmMvYXBpLmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50b29sdGlwL3NyYy90b29sdGlwLmpzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNKQTtBQUNBOztBQ0RBO0FBQ0E7O0FDREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUN4TEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbiBlKHQsbixyKXtmdW5jdGlvbiBzKG8sdSl7aWYoIW5bb10pe2lmKCF0W29dKXt2YXIgYT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2lmKCF1JiZhKXJldHVybiBhKG8sITApO2lmKGkpcmV0dXJuIGkobywhMCk7dGhyb3cgbmV3IEVycm9yKFwiQ2Fubm90IGZpbmQgbW9kdWxlICdcIitvK1wiJ1wiKX12YXIgZj1uW29dPXtleHBvcnRzOnt9fTt0W29dWzBdLmNhbGwoZi5leHBvcnRzLGZ1bmN0aW9uKGUpe3ZhciBuPXRbb11bMV1bZV07cmV0dXJuIHMobj9uOmUpfSxmLGYuZXhwb3J0cyxlLHQsbixyKX1yZXR1cm4gbltvXS5leHBvcnRzfXZhciBpPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7Zm9yKHZhciBvPTA7bzxyLmxlbmd0aDtvKyspcyhyW29dKTtyZXR1cm4gc30pIiwiaWYgKHR5cGVvZiB0bnQgPT09IFwidW5kZWZpbmVkXCIpIHtcbiAgICBtb2R1bGUuZXhwb3J0cyA9IHRudCA9IHt9O1xufVxudG50LnRvb2x0aXAgPSByZXF1aXJlKFwiLi9pbmRleC5qc1wiKTtcbiIsIm1vZHVsZS5leHBvcnRzID0gdG9vbHRpcCA9IHJlcXVpcmUoXCIuL3NyYy90b29sdGlwLmpzXCIpO1xuIiwibW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKFwiLi9zcmMvYXBpLmpzXCIpO1xuIiwidmFyIGFwaSA9IGZ1bmN0aW9uICh3aG8pIHtcblxuICAgIHZhciBfbWV0aG9kcyA9IGZ1bmN0aW9uICgpIHtcblx0dmFyIG0gPSBbXTtcblxuXHRtLmFkZF9iYXRjaCA9IGZ1bmN0aW9uIChvYmopIHtcblx0ICAgIG0udW5zaGlmdChvYmopO1xuXHR9O1xuXG5cdG0udXBkYXRlID0gZnVuY3Rpb24gKG1ldGhvZCwgdmFsdWUpIHtcblx0ICAgIGZvciAodmFyIGk9MDsgaTxtLmxlbmd0aDsgaSsrKSB7XG5cdFx0Zm9yICh2YXIgcCBpbiBtW2ldKSB7XG5cdFx0ICAgIGlmIChwID09PSBtZXRob2QpIHtcblx0XHRcdG1baV1bcF0gPSB2YWx1ZTtcblx0XHRcdHJldHVybiB0cnVlO1xuXHRcdCAgICB9XG5cdFx0fVxuXHQgICAgfVxuXHQgICAgcmV0dXJuIGZhbHNlO1xuXHR9O1xuXG5cdG0uYWRkID0gZnVuY3Rpb24gKG1ldGhvZCwgdmFsdWUpIHtcblx0ICAgIGlmIChtLnVwZGF0ZSAobWV0aG9kLCB2YWx1ZSkgKSB7XG5cdCAgICB9IGVsc2Uge1xuXHRcdHZhciByZWcgPSB7fTtcblx0XHRyZWdbbWV0aG9kXSA9IHZhbHVlO1xuXHRcdG0uYWRkX2JhdGNoIChyZWcpO1xuXHQgICAgfVxuXHR9O1xuXG5cdG0uZ2V0ID0gZnVuY3Rpb24gKG1ldGhvZCkge1xuXHQgICAgZm9yICh2YXIgaT0wOyBpPG0ubGVuZ3RoOyBpKyspIHtcblx0XHRmb3IgKHZhciBwIGluIG1baV0pIHtcblx0XHQgICAgaWYgKHAgPT09IG1ldGhvZCkge1xuXHRcdFx0cmV0dXJuIG1baV1bcF07XG5cdFx0ICAgIH1cblx0XHR9XG5cdCAgICB9XG5cdH07XG5cblx0cmV0dXJuIG07XG4gICAgfTtcblxuICAgIHZhciBtZXRob2RzICAgID0gX21ldGhvZHMoKTtcbiAgICB2YXIgYXBpID0gZnVuY3Rpb24gKCkge307XG5cbiAgICBhcGkuY2hlY2sgPSBmdW5jdGlvbiAobWV0aG9kLCBjaGVjaywgbXNnKSB7XG5cdGlmIChtZXRob2QgaW5zdGFuY2VvZiBBcnJheSkge1xuXHQgICAgZm9yICh2YXIgaT0wOyBpPG1ldGhvZC5sZW5ndGg7IGkrKykge1xuXHRcdGFwaS5jaGVjayhtZXRob2RbaV0sIGNoZWNrLCBtc2cpO1xuXHQgICAgfVxuXHQgICAgcmV0dXJuO1xuXHR9XG5cblx0aWYgKHR5cGVvZiAobWV0aG9kKSA9PT0gJ2Z1bmN0aW9uJykge1xuXHQgICAgbWV0aG9kLmNoZWNrKGNoZWNrLCBtc2cpO1xuXHR9IGVsc2Uge1xuXHQgICAgd2hvW21ldGhvZF0uY2hlY2soY2hlY2ssIG1zZyk7XG5cdH1cblx0cmV0dXJuIGFwaTtcbiAgICB9O1xuXG4gICAgYXBpLnRyYW5zZm9ybSA9IGZ1bmN0aW9uIChtZXRob2QsIGNiYWspIHtcblx0aWYgKG1ldGhvZCBpbnN0YW5jZW9mIEFycmF5KSB7XG5cdCAgICBmb3IgKHZhciBpPTA7IGk8bWV0aG9kLmxlbmd0aDsgaSsrKSB7XG5cdFx0YXBpLnRyYW5zZm9ybSAobWV0aG9kW2ldLCBjYmFrKTtcblx0ICAgIH1cblx0ICAgIHJldHVybjtcblx0fVxuXG5cdGlmICh0eXBlb2YgKG1ldGhvZCkgPT09ICdmdW5jdGlvbicpIHtcblx0ICAgIG1ldGhvZC50cmFuc2Zvcm0gKGNiYWspO1xuXHR9IGVsc2Uge1xuXHQgICAgd2hvW21ldGhvZF0udHJhbnNmb3JtKGNiYWspO1xuXHR9XG5cdHJldHVybiBhcGk7XG4gICAgfTtcblxuICAgIHZhciBhdHRhY2hfbWV0aG9kID0gZnVuY3Rpb24gKG1ldGhvZCwgb3B0cykge1xuXHR2YXIgY2hlY2tzID0gW107XG5cdHZhciB0cmFuc2Zvcm1zID0gW107XG5cblx0dmFyIGdldHRlciA9IG9wdHMub25fZ2V0dGVyIHx8IGZ1bmN0aW9uICgpIHtcblx0ICAgIHJldHVybiBtZXRob2RzLmdldChtZXRob2QpO1xuXHR9O1xuXG5cdHZhciBzZXR0ZXIgPSBvcHRzLm9uX3NldHRlciB8fCBmdW5jdGlvbiAoeCkge1xuXHQgICAgZm9yICh2YXIgaT0wOyBpPHRyYW5zZm9ybXMubGVuZ3RoOyBpKyspIHtcblx0XHR4ID0gdHJhbnNmb3Jtc1tpXSh4KTtcblx0ICAgIH1cblxuXHQgICAgZm9yICh2YXIgaj0wOyBqPGNoZWNrcy5sZW5ndGg7IGorKykge1xuXHRcdGlmICghY2hlY2tzW2pdLmNoZWNrKHgpKSB7XG5cdFx0ICAgIHZhciBtc2cgPSBjaGVja3Nbal0ubXNnIHx8IFxuXHRcdFx0KFwiVmFsdWUgXCIgKyB4ICsgXCIgZG9lc24ndCBzZWVtIHRvIGJlIHZhbGlkIGZvciB0aGlzIG1ldGhvZFwiKTtcblx0XHQgICAgdGhyb3cgKG1zZyk7XG5cdFx0fVxuXHQgICAgfVxuXHQgICAgbWV0aG9kcy5hZGQobWV0aG9kLCB4KTtcblx0fTtcblxuXHR2YXIgbmV3X21ldGhvZCA9IGZ1bmN0aW9uIChuZXdfdmFsKSB7XG5cdCAgICBpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0XHRyZXR1cm4gZ2V0dGVyKCk7XG5cdCAgICB9XG5cdCAgICBzZXR0ZXIobmV3X3ZhbCk7XG5cdCAgICByZXR1cm4gd2hvOyAvLyBSZXR1cm4gdGhpcz9cblx0fTtcblx0bmV3X21ldGhvZC5jaGVjayA9IGZ1bmN0aW9uIChjYmFrLCBtc2cpIHtcblx0ICAgIGlmICghYXJndW1lbnRzLmxlbmd0aCkge1xuXHRcdHJldHVybiBjaGVja3M7XG5cdCAgICB9XG5cdCAgICBjaGVja3MucHVzaCAoe2NoZWNrIDogY2Jhayxcblx0XHRcdCAgbXNnICAgOiBtc2d9KTtcblx0ICAgIHJldHVybiB0aGlzO1xuXHR9O1xuXHRuZXdfbWV0aG9kLnRyYW5zZm9ybSA9IGZ1bmN0aW9uIChjYmFrKSB7XG5cdCAgICBpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0XHRyZXR1cm4gdHJhbnNmb3Jtcztcblx0ICAgIH1cblx0ICAgIHRyYW5zZm9ybXMucHVzaChjYmFrKTtcblx0ICAgIHJldHVybiB0aGlzO1xuXHR9O1xuXG5cdHdob1ttZXRob2RdID0gbmV3X21ldGhvZDtcbiAgICB9O1xuXG4gICAgdmFyIGdldHNldCA9IGZ1bmN0aW9uIChwYXJhbSwgb3B0cykge1xuXHRpZiAodHlwZW9mIChwYXJhbSkgPT09ICdvYmplY3QnKSB7XG5cdCAgICBtZXRob2RzLmFkZF9iYXRjaCAocGFyYW0pO1xuXHQgICAgZm9yICh2YXIgcCBpbiBwYXJhbSkge1xuXHRcdGF0dGFjaF9tZXRob2QgKHAsIG9wdHMpO1xuXHQgICAgfVxuXHR9IGVsc2Uge1xuXHQgICAgbWV0aG9kcy5hZGQgKHBhcmFtLCBvcHRzLmRlZmF1bHRfdmFsdWUpO1xuXHQgICAgYXR0YWNoX21ldGhvZCAocGFyYW0sIG9wdHMpO1xuXHR9XG4gICAgfTtcblxuICAgIGFwaS5nZXRzZXQgPSBmdW5jdGlvbiAocGFyYW0sIGRlZikge1xuXHRnZXRzZXQocGFyYW0sIHtkZWZhdWx0X3ZhbHVlIDogZGVmfSk7XG5cblx0cmV0dXJuIGFwaTtcbiAgICB9O1xuXG4gICAgYXBpLmdldCA9IGZ1bmN0aW9uIChwYXJhbSwgZGVmKSB7XG5cdHZhciBvbl9zZXR0ZXIgPSBmdW5jdGlvbiAoKSB7XG5cdCAgICB0aHJvdyAoXCJNZXRob2QgZGVmaW5lZCBvbmx5IGFzIGEgZ2V0dGVyICh5b3UgYXJlIHRyeWluZyB0byB1c2UgaXQgYXMgYSBzZXR0ZXJcIik7XG5cdH07XG5cblx0Z2V0c2V0KHBhcmFtLCB7ZGVmYXVsdF92YWx1ZSA6IGRlZixcblx0XHQgICAgICAgb25fc2V0dGVyIDogb25fc2V0dGVyfVxuXHQgICAgICApO1xuXG5cdHJldHVybiBhcGk7XG4gICAgfTtcblxuICAgIGFwaS5zZXQgPSBmdW5jdGlvbiAocGFyYW0sIGRlZikge1xuXHR2YXIgb25fZ2V0dGVyID0gZnVuY3Rpb24gKCkge1xuXHQgICAgdGhyb3cgKFwiTWV0aG9kIGRlZmluZWQgb25seSBhcyBhIHNldHRlciAoeW91IGFyZSB0cnlpbmcgdG8gdXNlIGl0IGFzIGEgZ2V0dGVyXCIpO1xuXHR9O1xuXG5cdGdldHNldChwYXJhbSwge2RlZmF1bHRfdmFsdWUgOiBkZWYsXG5cdFx0ICAgICAgIG9uX2dldHRlciA6IG9uX2dldHRlcn1cblx0ICAgICAgKTtcblxuXHRyZXR1cm4gYXBpO1xuICAgIH07XG5cbiAgICBhcGkubWV0aG9kID0gZnVuY3Rpb24gKG5hbWUsIGNiYWspIHtcblx0aWYgKHR5cGVvZiAobmFtZSkgPT09ICdvYmplY3QnKSB7XG5cdCAgICBmb3IgKHZhciBwIGluIG5hbWUpIHtcblx0XHR3aG9bcF0gPSBuYW1lW3BdO1xuXHQgICAgfVxuXHR9IGVsc2Uge1xuXHQgICAgd2hvW25hbWVdID0gY2Jhaztcblx0fVxuXHRyZXR1cm4gYXBpO1xuICAgIH07XG5cbiAgICByZXR1cm4gYXBpO1xuICAgIFxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gYXBpOyIsInZhciBhcGlqcyA9IHJlcXVpcmUoXCJ0bnQuYXBpXCIpO1xuXG52YXIgdG9vbHRpcCA9IGZ1bmN0aW9uICgpIHtcbiAgICBcInVzZSBzdHJpY3RcIjtcblxuICAgIHZhciBkcmFnID0gZDMuYmVoYXZpb3IuZHJhZygpO1xuICAgIHZhciB0b29sdGlwX2RpdjtcblxuICAgIHZhciBjb25mID0ge1xuXHRwb3NpdGlvbiA6IFwicmlnaHRcIixcblx0YWxsb3dfZHJhZyA6IHRydWUsXG5cdHNob3dfY2xvc2VyIDogdHJ1ZSxcblx0ZmlsbCA6IGZ1bmN0aW9uICgpIHsgdGhyb3cgXCJmaWxsIGlzIG5vdCBkZWZpbmVkIGluIHRoZSBiYXNlIG9iamVjdFwiOyB9LFxuXHR3aWR0aCA6IDE4MCxcblx0aWQgOiAxXG4gICAgfTtcblxuICAgIHZhciB0ID0gZnVuY3Rpb24gKGRhdGEsIGV2ZW50KSB7XG5cdGRyYWdcblx0ICAgIC5vcmlnaW4oZnVuY3Rpb24oKXtcblx0XHRyZXR1cm4ge3g6cGFyc2VJbnQoZDMuc2VsZWN0KHRoaXMpLnN0eWxlKFwibGVmdFwiKSksXG5cdFx0XHR5OnBhcnNlSW50KGQzLnNlbGVjdCh0aGlzKS5zdHlsZShcInRvcFwiKSlcblx0XHQgICAgICAgfTtcblx0ICAgIH0pXG5cdCAgICAub24oXCJkcmFnXCIsIGZ1bmN0aW9uKCkge1xuXHRcdGlmIChjb25mLmFsbG93X2RyYWcpIHtcblx0XHQgICAgZDMuc2VsZWN0KHRoaXMpXG5cdFx0XHQuc3R5bGUoXCJsZWZ0XCIsIGQzLmV2ZW50LnggKyBcInB4XCIpXG5cdFx0XHQuc3R5bGUoXCJ0b3BcIiwgZDMuZXZlbnQueSArIFwicHhcIik7XG5cdFx0fVxuXHQgICAgfSk7XG5cblx0Ly8gVE9ETzogV2h5IGRvIHdlIG5lZWQgdGhlIGRpdiBlbGVtZW50P1xuXHQvLyBJdCBsb29rcyBsaWtlIGlmIHdlIGFuY2hvciB0aGUgdG9vbHRpcCBpbiB0aGUgXCJib2R5XCJcblx0Ly8gVGhlIHRvb2x0aXAgaXMgbm90IGxvY2F0ZWQgaW4gdGhlIHJpZ2h0IHBsYWNlIChhcHBlYXJzIGF0IHRoZSBib3R0b20pXG5cdC8vIFNlZSBjbGllbnRzL3Rvb2x0aXBzX3Rlc3QuaHRtbCBmb3IgYW4gZXhhbXBsZVxuXHR2YXIgY29udGFpbmVyRWxlbSA9IHNlbGVjdEFuY2VzdG9yICh0aGlzLCBcImRpdlwiKTtcblx0aWYgKGNvbnRhaW5lckVsZW0gPT09IHVuZGVmaW5lZCkge1xuXHQgICAgLy8gV2UgcmVxdWlyZSBhIGRpdiBlbGVtZW50IGF0IHNvbWUgcG9pbnQgdG8gYW5jaG9yIHRoZSB0b29sdGlwXG5cdCAgICByZXR1cm47XG5cdH1cblxuXHR0b29sdGlwX2RpdiA9IGQzLnNlbGVjdChjb250YWluZXJFbGVtKVxuXHQgICAgLmFwcGVuZChcImRpdlwiKVxuXHQgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF90b29sdGlwXCIpXG5cdCAgICAuY2xhc3NlZChcInRudF90b29sdGlwX2FjdGl2ZVwiLCB0cnVlKSAgLy8gVE9ETzogSXMgdGhpcyBuZWVkZWQvdXNlZD8/P1xuXHQgICAgLmNhbGwoZHJhZyk7XG5cblx0Ly8gcHJldiB0b29sdGlwcyB3aXRoIHRoZSBzYW1lIGhlYWRlclxuXHRkMy5zZWxlY3QoXCIjdG50X3Rvb2x0aXBfXCIgKyBjb25mLmlkKS5yZW1vdmUoKTtcblxuXHRpZiAoKGQzLmV2ZW50ID09PSBudWxsKSAmJiAoZXZlbnQpKSB7XG5cdCAgICBkMy5ldmVudCA9IGV2ZW50O1xuXHR9XG5cdHZhciBkM21vdXNlID0gZDMubW91c2UoY29udGFpbmVyRWxlbSk7XG5cdGQzLmV2ZW50ID0gbnVsbDtcblxuXHR2YXIgb2Zmc2V0ID0gMDtcblx0aWYgKGNvbmYucG9zaXRpb24gPT09IFwibGVmdFwiKSB7XG5cdCAgICBvZmZzZXQgPSBjb25mLndpZHRoO1xuXHR9XG5cblx0dG9vbHRpcF9kaXYuYXR0cihcImlkXCIsIFwidG50X3Rvb2x0aXBfXCIgKyBjb25mLmlkKTtcblxuXHQvLyBXZSBwbGFjZSB0aGUgdG9vbHRpcFxuXHR0b29sdGlwX2RpdlxuXHQgICAgLnN0eWxlKFwibGVmdFwiLCAoZDNtb3VzZVswXSkgKyBcInB4XCIpXG5cdCAgICAuc3R5bGUoXCJ0b3BcIiwgKGQzbW91c2VbMV0pICsgXCJweFwiKTtcblxuXHQvLyBDbG9zZVxuICAgIGlmIChjb25mLnNob3dfY2xvc2VyKSB7XG4gICAgICAgIHRvb2x0aXBfZGl2XG4gICAgICAgICAgICAuYXBwZW5kKFwiZGl2XCIpXG4gICAgICAgICAgICAuYXR0cihcImNsYXNzXCIsIFwidG50X3Rvb2x0aXBfY2xvc2VyXCIpXG4gICAgICAgICAgICAub24gKFwiY2xpY2tcIiwgZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgICAgIHQuY2xvc2UoKTtcbiAgICAgICAgICAgIH0pXG4gICAgfVxuXG5cdGNvbmYuZmlsbC5jYWxsKHRvb2x0aXBfZGl2LCBkYXRhKTtcblxuXHQvLyByZXR1cm4gdGhpcyBoZXJlP1xuXHRyZXR1cm4gdDtcbiAgICB9O1xuXG4gICAgLy8gZ2V0cyB0aGUgZmlyc3QgYW5jZXN0b3Igb2YgZWxlbSBoYXZpbmcgdGFnbmFtZSBcInR5cGVcIlxuICAgIC8vIGV4YW1wbGUgOiB2YXIgbXlkaXYgPSBzZWxlY3RBbmNlc3RvcihteWVsZW0sIFwiZGl2XCIpO1xuICAgIGZ1bmN0aW9uIHNlbGVjdEFuY2VzdG9yIChlbGVtLCB0eXBlKSB7XG5cdHR5cGUgPSB0eXBlLnRvTG93ZXJDYXNlKCk7XG5cdGlmIChlbGVtLnBhcmVudE5vZGUgPT09IG51bGwpIHtcblx0ICAgIGNvbnNvbGUubG9nKFwiTm8gbW9yZSBwYXJlbnRzXCIpO1xuXHQgICAgcmV0dXJuIHVuZGVmaW5lZDtcblx0fVxuXHR2YXIgdGFnTmFtZSA9IGVsZW0ucGFyZW50Tm9kZS50YWdOYW1lO1xuXG5cdGlmICgodGFnTmFtZSAhPT0gdW5kZWZpbmVkKSAmJiAodGFnTmFtZS50b0xvd2VyQ2FzZSgpID09PSB0eXBlKSkge1xuXHQgICAgcmV0dXJuIGVsZW0ucGFyZW50Tm9kZTtcblx0fSBlbHNlIHtcblx0ICAgIHJldHVybiBzZWxlY3RBbmNlc3RvciAoZWxlbS5wYXJlbnROb2RlLCB0eXBlKTtcblx0fVxuICAgIH1cblxuICAgIHZhciBhcGkgPSBhcGlqcyh0KVxuXHQuZ2V0c2V0KGNvbmYpO1xuICAgIGFwaS5jaGVjaygncG9zaXRpb24nLCBmdW5jdGlvbiAodmFsKSB7XG5cdHJldHVybiAodmFsID09PSAnbGVmdCcpIHx8ICh2YWwgPT09ICdyaWdodCcpO1xuICAgIH0sIFwiT25seSAnbGVmdCcgb3IgJ3JpZ2h0JyB2YWx1ZXMgYXJlIGFsbG93ZWQgZm9yIHBvc2l0aW9uXCIpO1xuXG4gICAgYXBpLm1ldGhvZCgnY2xvc2UnLCBmdW5jdGlvbiAoKSB7XG4gICAgICAgIGlmICh0b29sdGlwX2Rpdikge1xuICAgICAgICAgICAgdG9vbHRpcF9kaXYucmVtb3ZlKCk7XG4gICAgICAgIH1cbiAgICB9KTtcblxuICAgIHJldHVybiB0O1xufTtcblxudG9vbHRpcC5saXN0ID0gZnVuY3Rpb24gKCkge1xuICAgIC8vIGxpc3QgdG9vbHRpcCBpcyBiYXNlZCBvbiBnZW5lcmFsIHRvb2x0aXBzXG4gICAgdmFyIHQgPSB0b29sdGlwKCk7XG4gICAgdmFyIHdpZHRoID0gMTgwO1xuXG4gICAgdC5maWxsIChmdW5jdGlvbiAob2JqKSB7XG5cdHZhciB0b29sdGlwX2RpdiA9IHRoaXM7XG5cdHZhciBvYmpfaW5mb19saXN0ID0gdG9vbHRpcF9kaXZcblx0ICAgIC5hcHBlbmQoXCJ0YWJsZVwiKVxuXHQgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF96bWVudVwiKVxuXHQgICAgLmF0dHIoXCJib3JkZXJcIiwgXCJzb2xpZFwiKVxuXHQgICAgLnN0eWxlKFwid2lkdGhcIiwgdC53aWR0aCgpICsgXCJweFwiKTtcblxuXHQvLyBUb29sdGlwIGhlYWRlclxuICAgIGlmIChvYmouaGVhZGVyKSB7XG4gICAgICAgIG9ial9pbmZvX2xpc3Rcblx0ICAgICAgIC5hcHBlbmQoXCJ0clwiKVxuXHQgICAgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF96bWVudV9oZWFkZXJcIilcbiAgICAgICAgICAgLmFwcGVuZChcInRoXCIpXG4gICAgICAgICAgIC50ZXh0KG9iai5oZWFkZXIpO1xuICAgIH1cblxuXHQvLyBUb29sdGlwIHJvd3Ncblx0dmFyIHRhYmxlX3Jvd3MgPSBvYmpfaW5mb19saXN0LnNlbGVjdEFsbChcIi50bnRfem1lbnVfcm93XCIpXG5cdCAgICAuZGF0YShvYmoucm93cylcblx0ICAgIC5lbnRlcigpXG5cdCAgICAuYXBwZW5kKFwidHJcIilcblx0ICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfem1lbnVfcm93XCIpO1xuXG5cdHRhYmxlX3Jvd3Ncblx0ICAgIC5hcHBlbmQoXCJ0ZFwiKVxuXHQgICAgLnN0eWxlKFwidGV4dC1hbGlnblwiLCBcImNlbnRlclwiKVxuXHQgICAgLmh0bWwoZnVuY3Rpb24oZCxpKSB7XG5cdFx0cmV0dXJuIG9iai5yb3dzW2ldLnZhbHVlO1xuXHQgICAgfSlcblx0ICAgIC5lYWNoKGZ1bmN0aW9uIChkKSB7XG5cdFx0aWYgKGQubGluayA9PT0gdW5kZWZpbmVkKSB7XG5cdFx0ICAgIHJldHVybjtcblx0XHR9XG5cdFx0ZDMuc2VsZWN0KHRoaXMpXG5cdFx0ICAgIC5jbGFzc2VkKFwibGlua1wiLCAxKVxuXHRcdCAgICAub24oJ2NsaWNrJywgZnVuY3Rpb24gKGQpIHtcblx0XHRcdGQubGluayhkLm9iaik7XG5cdFx0XHR0LmNsb3NlLmNhbGwodGhpcyk7XG5cdFx0ICAgIH0pO1xuXHQgICAgfSk7XG4gICAgfSk7XG4gICAgcmV0dXJuIHQ7XG59O1xuXG50b29sdGlwLnRhYmxlID0gZnVuY3Rpb24gKCkge1xuICAgIC8vIHRhYmxlIHRvb2x0aXBzIGFyZSBiYXNlZCBvbiBnZW5lcmFsIHRvb2x0aXBzXG4gICAgdmFyIHQgPSB0b29sdGlwKCk7XG5cbiAgICB2YXIgd2lkdGggPSAxODA7XG5cbiAgICB0LmZpbGwgKGZ1bmN0aW9uIChvYmopIHtcblx0dmFyIHRvb2x0aXBfZGl2ID0gdGhpcztcblxuXHR2YXIgb2JqX2luZm9fdGFibGUgPSB0b29sdGlwX2RpdlxuXHQgICAgLmFwcGVuZChcInRhYmxlXCIpXG5cdCAgICAuYXR0cihcImNsYXNzXCIsIFwidG50X3ptZW51XCIpXG5cdCAgICAuYXR0cihcImJvcmRlclwiLCBcInNvbGlkXCIpXG5cdCAgICAuc3R5bGUoXCJ3aWR0aFwiLCB0LndpZHRoKCkgKyBcInB4XCIpO1xuXG5cdC8vIFRvb2x0aXAgaGVhZGVyXG4gICAgaWYgKG9iai5oZWFkZXIpIHtcbiAgICAgICAgb2JqX2luZm9fdGFibGVcbiAgICAgICAgICAgIC5hcHBlbmQoXCJ0clwiKVxuICAgICAgICAgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF96bWVudV9oZWFkZXJcIilcbiAgICAgICAgICAgIC5hcHBlbmQoXCJ0aFwiKVxuICAgICAgICAgICAgLmF0dHIoXCJjb2xzcGFuXCIsIDIpXG4gICAgICAgICAgICAudGV4dChvYmouaGVhZGVyKTtcbiAgICB9XG5cblx0Ly8gVG9vbHRpcCByb3dzXG5cdHZhciB0YWJsZV9yb3dzID0gb2JqX2luZm9fdGFibGUuc2VsZWN0QWxsKFwiLnRudF96bWVudV9yb3dcIilcblx0ICAgIC5kYXRhKG9iai5yb3dzKVxuXHQgICAgLmVudGVyKClcblx0ICAgIC5hcHBlbmQoXCJ0clwiKVxuXHQgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF96bWVudV9yb3dcIik7XG5cblx0dGFibGVfcm93c1xuXHQgICAgLmFwcGVuZChcInRoXCIpXG5cdCAgICAuYXR0cihcImNvbHNwYW5cIiwgZnVuY3Rpb24gKGQsIGkpIHtcblx0XHRpZiAoZC52YWx1ZSA9PT0gXCJcIikge1xuXHRcdCAgICByZXR1cm4gMjtcblx0XHR9XG5cdFx0cmV0dXJuIDE7XG5cdCAgICB9KVxuXHQgICAgLmF0dHIoXCJjbGFzc1wiLCBmdW5jdGlvbiAoZCkge1xuXHRcdGlmIChkLnZhbHVlID09PSBcIlwiKSB7XG5cdFx0ICAgIHJldHVybiBcInRudF96bWVudV9pbm5lcl9oZWFkZXJcIjtcblx0XHR9XG5cdFx0cmV0dXJuIFwidG50X3ptZW51X2NlbGxcIjtcblx0ICAgIH0pXG5cdCAgICAuaHRtbChmdW5jdGlvbihkLGkpIHtcblx0XHRyZXR1cm4gb2JqLnJvd3NbaV0ubGFiZWw7XG5cdCAgICB9KTtcblxuXHR0YWJsZV9yb3dzXG5cdCAgICAuYXBwZW5kKFwidGRcIilcblx0ICAgIC5odG1sKGZ1bmN0aW9uKGQsaSkge1xuXHRcdGlmICh0eXBlb2Ygb2JqLnJvd3NbaV0udmFsdWUgPT09ICdmdW5jdGlvbicpIHtcblx0XHQgICAgb2JqLnJvd3NbaV0udmFsdWUuY2FsbCh0aGlzLCBkKTtcblx0XHR9IGVsc2Uge1xuXHRcdCAgICByZXR1cm4gb2JqLnJvd3NbaV0udmFsdWU7XG5cdFx0fVxuXHQgICAgfSlcblx0ICAgIC5lYWNoKGZ1bmN0aW9uIChkKSB7XG5cdFx0aWYgKGQudmFsdWUgPT09IFwiXCIpIHtcblx0XHQgICAgZDMuc2VsZWN0KHRoaXMpLnJlbW92ZSgpO1xuXHRcdH1cblx0ICAgIH0pXG5cdCAgICAuZWFjaChmdW5jdGlvbiAoZCkge1xuXHRcdGlmIChkLmxpbmsgPT09IHVuZGVmaW5lZCkge1xuXHRcdCAgICByZXR1cm47XG5cdFx0fVxuXHRcdGQzLnNlbGVjdCh0aGlzKVxuXHRcdCAgICAuY2xhc3NlZChcImxpbmtcIiwgMSlcblx0XHQgICAgLm9uKCdjbGljaycsIGZ1bmN0aW9uIChkKSB7XG5cdFx0XHRkLmxpbmsoZC5vYmopO1xuXHRcdFx0dC5jbG9zZS5jYWxsKHRoaXMpO1xuXHRcdCAgICB9KTtcblx0ICAgIH0pO1xuICAgIH0pO1xuXG4gICAgcmV0dXJuIHQ7XG59O1xuXG50b29sdGlwLnBsYWluID0gZnVuY3Rpb24gKCkge1xuICAgIC8vIHBsYWluIHRvb2x0aXBzIGFyZSBiYXNlZCBvbiBnZW5lcmFsIHRvb2x0aXBzXG4gICAgdmFyIHQgPSB0b29sdGlwKCk7XG5cbiAgICB0LmZpbGwgKGZ1bmN0aW9uIChvYmopIHtcblx0dmFyIHRvb2x0aXBfZGl2ID0gdGhpcztcblxuXHR2YXIgb2JqX2luZm9fdGFibGUgPSB0b29sdGlwX2RpdlxuXHQgICAgLmFwcGVuZChcInRhYmxlXCIpXG5cdCAgICAuYXR0cihcImNsYXNzXCIsIFwidG50X3ptZW51XCIpXG5cdCAgICAuYXR0cihcImJvcmRlclwiLCBcInNvbGlkXCIpXG5cdCAgICAuc3R5bGUoXCJ3aWR0aFwiLCB0LndpZHRoKCkgKyBcInB4XCIpO1xuXG4gICAgaWYgKG9iai5oZWFkZXIpIHtcbiAgICAgICAgb2JqX2luZm9fdGFibGVcbiAgICAgICAgICAgIC5hcHBlbmQoXCJ0clwiKVxuICAgICAgICAgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF96bWVudV9oZWFkZXJcIilcbiAgICAgICAgICAgIC5hcHBlbmQoXCJ0aFwiKVxuICAgICAgICAgICAgLnRleHQob2JqLmhlYWRlcik7XG4gICAgfVxuXG4gICAgaWYgKG9iai5ib2R5KSB7XG4gICAgICAgIG9ial9pbmZvX3RhYmxlXG4gICAgICAgICAgICAuYXBwZW5kKFwidHJcIilcbiAgICAgICAgICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfem1lbnVfcm93XCIpXG4gICAgICAgICAgICAuYXBwZW5kKFwidGRcIilcbiAgICAgICAgICAgIC5zdHlsZShcInRleHQtYWxpZ25cIiwgXCJjZW50ZXJcIilcbiAgICAgICAgICAgIC5odG1sKG9iai5ib2R5KTtcbiAgICB9XG4gICAgfSk7XG5cbiAgICByZXR1cm4gdDtcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gZXhwb3J0cyA9IHRvb2x0aXA7XG4iXX0=
