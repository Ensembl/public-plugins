(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
if (typeof tnt === "undefined") {
    module.exports = tnt = {};
}
tnt.tree = require("./index.js");
tnt.tree.node = require("tnt.tree.node");
tnt.tree.parse_newick = require("tnt.newick").parse_newick;
tnt.tree.parse_nhx = require("tnt.newick").parse_nhx;


},{"./index.js":2,"tnt.newick":8,"tnt.tree.node":10}],2:[function(require,module,exports){
// if (typeof tnt === "undefined") {
//     module.exports = tnt = {}
// }
module.exports = tree = require("./src/index.js");
var eventsystem = require("biojs-events");
eventsystem.mixin(tree);
//tnt.utils = require("tnt.utils");
//tnt.tooltip = require("tnt.tooltip");
//tnt.tree = require("./src/index.js");


},{"./src/index.js":17,"biojs-events":3}],3:[function(require,module,exports){
var events = require("backbone-events-standalone");

events.onAll = function(callback,context){
  this.on("all", callback,context);
  return this;
};

// Mixin utility
events.oldMixin = events.mixin;
events.mixin = function(proto) {
  events.oldMixin(proto);
  // add custom onAll
  var exports = ['onAll'];
  for(var i=0; i < exports.length;i++){
    var name = exports[i];
    proto[name] = this[name];
  }
  return proto;
};

module.exports = events;

},{"backbone-events-standalone":5}],4:[function(require,module,exports){
/**
 * Standalone extraction of Backbone.Events, no external dependency required.
 * Degrades nicely when Backone/underscore are already available in the current
 * global context.
 *
 * Note that docs suggest to use underscore's `_.extend()` method to add Events
 * support to some given object. A `mixin()` method has been added to the Events
 * prototype to avoid using underscore for that sole purpose:
 *
 *     var myEventEmitter = BackboneEvents.mixin({});
 *
 * Or for a function constructor:
 *
 *     function MyConstructor(){}
 *     MyConstructor.prototype.foo = function(){}
 *     BackboneEvents.mixin(MyConstructor.prototype);
 *
 * (c) 2009-2013 Jeremy Ashkenas, DocumentCloud Inc.
 * (c) 2013 Nicolas Perriault
 */
/* global exports:true, define, module */
(function() {
  var root = this,
      nativeForEach = Array.prototype.forEach,
      hasOwnProperty = Object.prototype.hasOwnProperty,
      slice = Array.prototype.slice,
      idCounter = 0;

  // Returns a partial implementation matching the minimal API subset required
  // by Backbone.Events
  function miniscore() {
    return {
      keys: Object.keys || function (obj) {
        if (typeof obj !== "object" && typeof obj !== "function" || obj === null) {
          throw new TypeError("keys() called on a non-object");
        }
        var key, keys = [];
        for (key in obj) {
          if (obj.hasOwnProperty(key)) {
            keys[keys.length] = key;
          }
        }
        return keys;
      },

      uniqueId: function(prefix) {
        var id = ++idCounter + '';
        return prefix ? prefix + id : id;
      },

      has: function(obj, key) {
        return hasOwnProperty.call(obj, key);
      },

      each: function(obj, iterator, context) {
        if (obj == null) return;
        if (nativeForEach && obj.forEach === nativeForEach) {
          obj.forEach(iterator, context);
        } else if (obj.length === +obj.length) {
          for (var i = 0, l = obj.length; i < l; i++) {
            iterator.call(context, obj[i], i, obj);
          }
        } else {
          for (var key in obj) {
            if (this.has(obj, key)) {
              iterator.call(context, obj[key], key, obj);
            }
          }
        }
      },

      once: function(func) {
        var ran = false, memo;
        return function() {
          if (ran) return memo;
          ran = true;
          memo = func.apply(this, arguments);
          func = null;
          return memo;
        };
      }
    };
  }

  var _ = miniscore(), Events;

  // Backbone.Events
  // ---------------

  // A module that can be mixed in to *any object* in order to provide it with
  // custom events. You may bind with `on` or remove with `off` callback
  // functions to an event; `trigger`-ing an event fires all callbacks in
  // succession.
  //
  //     var object = {};
  //     _.extend(object, Backbone.Events);
  //     object.on('expand', function(){ alert('expanded'); });
  //     object.trigger('expand');
  //
  Events = {

    // Bind an event to a `callback` function. Passing `"all"` will bind
    // the callback to all events fired.
    on: function(name, callback, context) {
      if (!eventsApi(this, 'on', name, [callback, context]) || !callback) return this;
      this._events || (this._events = {});
      var events = this._events[name] || (this._events[name] = []);
      events.push({callback: callback, context: context, ctx: context || this});
      return this;
    },

    // Bind an event to only be triggered a single time. After the first time
    // the callback is invoked, it will be removed.
    once: function(name, callback, context) {
      if (!eventsApi(this, 'once', name, [callback, context]) || !callback) return this;
      var self = this;
      var once = _.once(function() {
        self.off(name, once);
        callback.apply(this, arguments);
      });
      once._callback = callback;
      return this.on(name, once, context);
    },

    // Remove one or many callbacks. If `context` is null, removes all
    // callbacks with that function. If `callback` is null, removes all
    // callbacks for the event. If `name` is null, removes all bound
    // callbacks for all events.
    off: function(name, callback, context) {
      var retain, ev, events, names, i, l, j, k;
      if (!this._events || !eventsApi(this, 'off', name, [callback, context])) return this;
      if (!name && !callback && !context) {
        this._events = {};
        return this;
      }

      names = name ? [name] : _.keys(this._events);
      for (i = 0, l = names.length; i < l; i++) {
        name = names[i];
        if (events = this._events[name]) {
          this._events[name] = retain = [];
          if (callback || context) {
            for (j = 0, k = events.length; j < k; j++) {
              ev = events[j];
              if ((callback && callback !== ev.callback && callback !== ev.callback._callback) ||
                  (context && context !== ev.context)) {
                retain.push(ev);
              }
            }
          }
          if (!retain.length) delete this._events[name];
        }
      }

      return this;
    },

    // Trigger one or many events, firing all bound callbacks. Callbacks are
    // passed the same arguments as `trigger` is, apart from the event name
    // (unless you're listening on `"all"`, which will cause your callback to
    // receive the true name of the event as the first argument).
    trigger: function(name) {
      if (!this._events) return this;
      var args = slice.call(arguments, 1);
      if (!eventsApi(this, 'trigger', name, args)) return this;
      var events = this._events[name];
      var allEvents = this._events.all;
      if (events) triggerEvents(events, args);
      if (allEvents) triggerEvents(allEvents, arguments);
      return this;
    },

    // Tell this object to stop listening to either specific events ... or
    // to every object it's currently listening to.
    stopListening: function(obj, name, callback) {
      var listeners = this._listeners;
      if (!listeners) return this;
      var deleteListener = !name && !callback;
      if (typeof name === 'object') callback = this;
      if (obj) (listeners = {})[obj._listenerId] = obj;
      for (var id in listeners) {
        listeners[id].off(name, callback, this);
        if (deleteListener) delete this._listeners[id];
      }
      return this;
    }

  };

  // Regular expression used to split event strings.
  var eventSplitter = /\s+/;

  // Implement fancy features of the Events API such as multiple event
  // names `"change blur"` and jQuery-style event maps `{change: action}`
  // in terms of the existing API.
  var eventsApi = function(obj, action, name, rest) {
    if (!name) return true;

    // Handle event maps.
    if (typeof name === 'object') {
      for (var key in name) {
        obj[action].apply(obj, [key, name[key]].concat(rest));
      }
      return false;
    }

    // Handle space separated event names.
    if (eventSplitter.test(name)) {
      var names = name.split(eventSplitter);
      for (var i = 0, l = names.length; i < l; i++) {
        obj[action].apply(obj, [names[i]].concat(rest));
      }
      return false;
    }

    return true;
  };

  // A difficult-to-believe, but optimized internal dispatch function for
  // triggering events. Tries to keep the usual cases speedy (most internal
  // Backbone events have 3 arguments).
  var triggerEvents = function(events, args) {
    var ev, i = -1, l = events.length, a1 = args[0], a2 = args[1], a3 = args[2];
    switch (args.length) {
      case 0: while (++i < l) (ev = events[i]).callback.call(ev.ctx); return;
      case 1: while (++i < l) (ev = events[i]).callback.call(ev.ctx, a1); return;
      case 2: while (++i < l) (ev = events[i]).callback.call(ev.ctx, a1, a2); return;
      case 3: while (++i < l) (ev = events[i]).callback.call(ev.ctx, a1, a2, a3); return;
      default: while (++i < l) (ev = events[i]).callback.apply(ev.ctx, args);
    }
  };

  var listenMethods = {listenTo: 'on', listenToOnce: 'once'};

  // Inversion-of-control versions of `on` and `once`. Tell *this* object to
  // listen to an event in another object ... keeping track of what it's
  // listening to.
  _.each(listenMethods, function(implementation, method) {
    Events[method] = function(obj, name, callback) {
      var listeners = this._listeners || (this._listeners = {});
      var id = obj._listenerId || (obj._listenerId = _.uniqueId('l'));
      listeners[id] = obj;
      if (typeof name === 'object') callback = this;
      obj[implementation](name, callback, this);
      return this;
    };
  });

  // Aliases for backwards compatibility.
  Events.bind   = Events.on;
  Events.unbind = Events.off;

  // Mixin utility
  Events.mixin = function(proto) {
    var exports = ['on', 'once', 'off', 'trigger', 'stopListening', 'listenTo',
                   'listenToOnce', 'bind', 'unbind'];
    _.each(exports, function(name) {
      proto[name] = this[name];
    }, this);
    return proto;
  };

  // Export Events as BackboneEvents depending on current context
  if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports) {
      exports = module.exports = Events;
    }
    exports.BackboneEvents = Events;
  }else if (typeof define === "function"  && typeof define.amd == "object") {
    define(function() {
      return Events;
    });
  } else {
    root.BackboneEvents = Events;
  }
})(this);

},{}],5:[function(require,module,exports){
module.exports = require('./backbone-events-standalone');

},{"./backbone-events-standalone":4}],6:[function(require,module,exports){
module.exports = require("./src/api.js");

},{"./src/api.js":7}],7:[function(require,module,exports){
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
},{}],8:[function(require,module,exports){
module.exports = require("./src/newick.js");

},{"./src/newick.js":9}],9:[function(require,module,exports){
/**
 * Newick and nhx formats parser in JavaScript.
 *
 * Copyright (c) Jason Davies 2010 and Miguel Pignatelli
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Example tree (from http://en.wikipedia.org/wiki/Newick_format):
 *
 * +--0.1--A
 * F-----0.2-----B            +-------0.3----C
 * +------------------0.5-----E
 *                            +---------0.4------D
 *
 * Newick format:
 * (A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;
 *
 * Converted to JSON:
 * {
 *   name: "F",
 *   branchset: [
 *     {name: "A", length: 0.1},
 *     {name: "B", length: 0.2},
 *     {
 *       name: "E",
 *       length: 0.5,
 *       branchset: [
 *         {name: "C", length: 0.3},
 *         {name: "D", length: 0.4}
 *       ]
 *     }
 *   ]
 * }
 *
 * Converted to JSON, but with no names or lengths:
 * {
 *   branchset: [
 *     {}, {}, {
 *       branchset: [{}, {}]
 *     }
 *   ]
 * }
 */

module.exports = {
    parse_newick : function(s) {
	var ancestors = [];
	var tree = {};
	var tokens = s.split(/\s*(;|\(|\)|,|:)\s*/);
	var subtree;
	for (var i=0; i<tokens.length; i++) {
	    var token = tokens[i];
	    switch (token) {
            case '(': // new branchset
		subtree = {};
		tree.children = [subtree];
		ancestors.push(tree);
		tree = subtree;
		break;
            case ',': // another branch
		subtree = {};
		ancestors[ancestors.length-1].children.push(subtree);
		tree = subtree;
		break;
            case ')': // optional name next
		tree = ancestors.pop();
		break;
            case ':': // optional length next
		break;
            default:
		var x = tokens[i-1];
		if (x == ')' || x == '(' || x == ',') {
		    tree.name = token;
		} else if (x == ':') {
		    tree.branch_length = parseFloat(token);
		}
	    }
	}
	return tree;
    },

    parse_nhx : function (s) {
	var ancestors = [];
	var tree = {};
	var subtree;

	var tokens = s.split( /\s*(;|\(|\)|\[|\]|,|:|=)\s*/ );
	for (var i=0; i<tokens.length; i++) {
	    var token = tokens[i];
	    switch (token) {
            case '(': // new children
		subtree = {};
		tree.children = [subtree];
		ancestors.push(tree);
		tree = subtree;
		break;
            case ',': // another branch
		subtree = {};
		ancestors[ancestors.length-1].children.push(subtree);
		tree = subtree;
		break;
            case ')': // optional name next
		tree = ancestors.pop();
		break;
            case ':': // optional length next
		break;
            default:
		var x = tokens[i-1];
		if (x == ')' || x == '(' || x == ',') {
		    tree.name = token;
		}
		else if (x == ':') {
		    var test_type = typeof token;
		    if(!isNaN(token)){
			tree.branch_length = parseFloat(token);
		    }
		}
		else if (x == '='){
		    var x2 = tokens[i-2];
		    switch(x2){
		    case 'D':
			tree.duplication = token;
			break;
		    case 'G':
			tree.gene_id = token;
			break;
		    case 'T':
			tree.taxon_id = token;
			break;
		    default :
			tree[tokens[i-2]] = token;
		    }
		}
		else {
		    var test;

		}
	    }
	}
	return tree;
    }
};

},{}],10:[function(require,module,exports){
var node = require("./src/node.js");
module.exports = exports = node;

},{"./src/node.js":15}],11:[function(require,module,exports){
module.exports = require("./src/index.js");

},{"./src/index.js":12}],12:[function(require,module,exports){
// require('fs').readdirSync(__dirname + '/').forEach(function(file) {
//     if (file.match(/.+\.js/g) !== null && file !== __filename) {
// 	var name = file.replace('.js', '');
// 	module.exports[name] = require('./' + file);
//     }
// });

// Same as
var utils = require("./utils.js");
utils.reduce = require("./reduce.js");
module.exports = exports = utils;

},{"./reduce.js":13,"./utils.js":14}],13:[function(require,module,exports){
var reduce = function () {
    var smooth = 5;
    var value = 'val';
    var redundant = function (a, b) {
	if (a < b) {
	    return ((b-a) <= (b * 0.2));
	}
	return ((a-b) <= (a * 0.2));
    };
    var perform_reduce = function (arr) {return arr;};

    var reduce = function (arr) {
	if (!arr.length) {
	    return arr;
	}
	var smoothed = perform_smooth(arr);
	var reduced  = perform_reduce(smoothed);
	return reduced;
    };

    var median = function (v, arr) {
	arr.sort(function (a, b) {
	    return a[value] - b[value];
	});
	if (arr.length % 2) {
	    v[value] = arr[~~(arr.length / 2)][value];	    
	} else {
	    var n = ~~(arr.length / 2) - 1;
	    v[value] = (arr[n][value] + arr[n+1][value]) / 2;
	}

	return v;
    };

    var clone = function (source) {
	var target = {};
	for (var prop in source) {
	    if (source.hasOwnProperty(prop)) {
		target[prop] = source[prop];
	    }
	}
	return target;
    };

    var perform_smooth = function (arr) {
	if (smooth === 0) { // no smooth
	    return arr;
	}
	var smooth_arr = [];
	for (var i=0; i<arr.length; i++) {
	    var low = (i < smooth) ? 0 : (i - smooth);
	    var high = (i > (arr.length - smooth)) ? arr.length : (i + smooth);
	    smooth_arr[i] = median(clone(arr[i]), arr.slice(low,high+1));
	}
	return smooth_arr;
    };

    reduce.reducer = function (cbak) {
	if (!arguments.length) {
	    return perform_reduce;
	}
	perform_reduce = cbak;
	return reduce;
    };

    reduce.redundant = function (cbak) {
	if (!arguments.length) {
	    return redundant;
	}
	redundant = cbak;
	return reduce;
    };

    reduce.value = function (val) {
	if (!arguments.length) {
	    return value;
	}
	value = val;
	return reduce;
    };

    reduce.smooth = function (val) {
	if (!arguments.length) {
	    return smooth;
	}
	smooth = val;
	return reduce;
    };

    return reduce;
};

var block = function () {
    var red = reduce()
	.value('start');

    var value2 = 'end';

    var join = function (obj1, obj2) {
        return {
            'object' : {
                'start' : obj1.object[red.value()],
                'end'   : obj2[value2]
            },
            'value'  : obj2[value2]
        };
    };

    // var join = function (obj1, obj2) { return obj1 };

    red.reducer( function (arr) {
	var value = red.value();
	var redundant = red.redundant();
	var reduced_arr = [];
	var curr = {
	    'object' : arr[0],
	    'value'  : arr[0][value2]
	};
	for (var i=1; i<arr.length; i++) {
	    if (redundant (arr[i][value], curr.value)) {
		curr = join(curr, arr[i]);
		continue;
	    }
	    reduced_arr.push (curr.object);
	    curr.object = arr[i];
	    curr.value = arr[i].end;
	}
	reduced_arr.push(curr.object);

	// reduced_arr.push(arr[arr.length-1]);
	return reduced_arr;
    });

    reduce.join = function (cbak) {
	if (!arguments.length) {
	    return join;
	}
	join = cbak;
	return red;
    };

    reduce.value2 = function (field) {
	if (!arguments.length) {
	    return value2;
	}
	value2 = field;
	return red;
    };

    return red;
};

var line = function () {
    var red = reduce();

    red.reducer ( function (arr) {
	var redundant = red.redundant();
	var value = red.value();
	var reduced_arr = [];
	var curr = arr[0];
	for (var i=1; i<arr.length-1; i++) {
	    if (redundant (arr[i][value], curr[value])) {
		continue;
	    }
	    reduced_arr.push (curr);
	    curr = arr[i];
	}
	reduced_arr.push(curr);
	reduced_arr.push(arr[arr.length-1]);
	return reduced_arr;
    });

    return red;

};

module.exports = reduce;
module.exports.line = line;
module.exports.block = block;


},{}],14:[function(require,module,exports){

module.exports = {
    iterator : function(init_val) {
	var i = init_val || 0;
	var iter = function () {
	    return i++;
	};
	return iter;
    },

    script_path : function (script_name) { // script_name is the filename
	var script_scaped = script_name.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
	var script_re = new RegExp(script_scaped + '$');
	var script_re_sub = new RegExp('(.*)' + script_scaped + '$');

	// TODO: This requires phantom.js or a similar headless webkit to work (document)
	var scripts = document.getElementsByTagName('script');
	var path = "";  // Default to current path
	if(scripts !== undefined) {
            for(var i in scripts) {
		if(scripts[i].src && scripts[i].src.match(script_re)) {
                    return scripts[i].src.replace(script_re_sub, '$1');
		}
            }
	}
	return path;
    },

    defer_cancel : function (cbak, time) {
        var tick;

        var defer_cancel = function () {
            var args = Array.prototype.slice.call(arguments);
            var that = this;
            clearTimeout(tick);
            tick = setTimeout (function () {
                cbak.apply (that, args);
            }, time);
        };

        return defer_cancel;
    }
};

},{}],15:[function(require,module,exports){
var apijs = require("tnt.api");
var iterator = require("tnt.utils").iterator;

var tnt_node = function (data) {
//tnt.tree.node = function (data) {
    "use strict";

    var node = function () {
    };

    var api = apijs (node);

    // API
//     node.nodes = function() {
// 	if (cluster === undefined) {
// 	    cluster = d3.layout.cluster()
// 	    // TODO: length and children should be exposed in the API
// 	    // i.e. the user should be able to change this defaults via the API
// 	    // children is the defaults for parse_newick, but maybe we should change that
// 	    // or at least not assume this is always the case for the data provided
// 		.value(function(d) {return d.length})
// 		.children(function(d) {return d.children});
// 	}
// 	nodes = cluster.nodes(data);
// 	return nodes;
//     };

    var apply_to_data = function (data, cbak) {
	cbak(data);
	if (data.children !== undefined) {
	    for (var i=0; i<data.children.length; i++) {
		apply_to_data(data.children[i], cbak);
	    }
	}
    };

    var create_ids = function () {
	var i = iterator(1);
	// We can't use apply because apply creates new trees on every node
	// We should use the direct data instead
	apply_to_data (data, function (d) {
	    if (d._id === undefined) {
		d._id = i();
		// TODO: Not sure _inSubTree is strictly necessary
		// d._inSubTree = {prev:true, curr:true};
	    }
	});
    };

    var link_parents = function (data) {
	if (data === undefined) {
	    return;
	}
	if (data.children === undefined) {
	    return;
	}
	for (var i=0; i<data.children.length; i++) {
	    // _parent?
	    data.children[i]._parent = data;
	    link_parents(data.children[i]);
	}
    };

    var compute_root_dists = function (data) {
	apply_to_data (data, function (d) {
	    var l;
	    if (d._parent === undefined) {
		d._root_dist = 0;
	    } else {
		var l = 0;
		if (d.branch_length) {
		    l = d.branch_length
		}
		d._root_dist = l + d._parent._root_dist;
	    }
	});
    };

    // TODO: data can't be rewritten used the api yet. We need finalizers
    node.data = function(new_data) {
	if (!arguments.length) {
	    return data
	}
	data = new_data;
	create_ids();
	link_parents(data);
	compute_root_dists(data);
	return node;
    };
    // We bind the data that has been passed
    node.data(data);

    api.method ('find_all', function (cbak, deep) {
	var nodes = [];
	node.apply (function (n) {
	    if (cbak(n)) {
		nodes.push (n);
	    }
	});
	return nodes;
    });
    
    api.method ('find_node', function (cbak, deep) {
	if (cbak(node)) {
	    return node;
	}

	if (data.children !== undefined) {
	    for (var j=0; j<data.children.length; j++) {
		var found = tnt_node(data.children[j]).find_node(cbak, deep);
		if (found) {
		    return found;
		}
	    }
	}

	if (deep && (data._children !== undefined)) {
	    for (var i=0; i<data._children.length; i++) {
		tnt_node(data._children[i]).find_node(cbak, deep)
		var found = tnt_node(data._children[i]).find_node(cbak, deep);
		if (found) {
		    return found;
		}
	    }
	}
    });

    api.method ('find_node_by_name', function(name, deep) {
	return node.find_node (function (node) {
	    return node.node_name() === name
	}, deep);
    });

    api.method ('toggle', function() {
	if (data) {
	    if (data.children) { // Uncollapsed -> collapse
		var hidden = 0;
		node.apply (function (n) {
		    var hidden_here = n.n_hidden() || 0;
		    hidden += (n.n_hidden() || 0) + 1;
		});
		node.n_hidden (hidden-1);
		data._children = data.children;
		data.children = undefined;
	    } else {             // Collapsed -> uncollapse
		node.n_hidden(0);
		data.children = data._children;
		data._children = undefined;
	    }
	}
	return this;
    });

    api.method ('is_collapsed', function () {
	return (data._children !== undefined && data.children === undefined);
    });

    var has_ancestor = function(n, ancestor) {
	// It is better to work at the data level
	n = n.data();
	ancestor = ancestor.data();
	if (n._parent === undefined) {
	    return false
	}
	n = n._parent
	for (;;) {
	    if (n === undefined) {
		return false;
	    }
	    if (n === ancestor) {
		return true;
	    }
	    n = n._parent;
	}
    };

    // This is the easiest way to calculate the LCA I can think of. But it is very inefficient too.
    // It is working fine by now, but in case it needs to be more performant we can implement the LCA
    // algorithm explained here:
    // http://community.topcoder.com/tc?module=Static&d1=tutorials&d2=lowestCommonAncestor
    api.method ('lca', function (nodes) {
	if (nodes.length === 1) {
	    return nodes[0];
	}
	var lca_node = nodes[0];
	for (var i = 1; i<nodes.length; i++) {
	    lca_node = _lca(lca_node, nodes[i]);
	}
	return lca_node;
	// return tnt_node(lca_node);
    });

    var _lca = function(node1, node2) {
	if (node1.data() === node2.data()) {
	    return node1;
	}
	if (has_ancestor(node1, node2)) {
	    return node2;
	}
	return _lca(node1, node2.parent());
    };

    api.method('n_hidden', function (val) {
	if (!arguments.length) {
	    return node.property('_hidden');
	}
	node.property('_hidden', val);
	return node
    });

    api.method ('get_all_nodes', function (deep) {
	var nodes = [];
	node.apply(function (n) {
	    nodes.push(n);
	}, deep);
	return nodes;
    });

    api.method ('get_all_leaves', function (deep) {
	var leaves = [];
	node.apply(function (n) {
	    if (n.is_leaf(deep)) {
		leaves.push(n);
	    }
	}, deep);
	return leaves;
    });

    api.method ('upstream', function(cbak) {
	cbak(node);
	var parent = node.parent();
	if (parent !== undefined) {
	    parent.upstream(cbak);
	}
//	tnt_node(parent).upstream(cbak);
// 	node.upstream(node._parent, cbak);
    });

    api.method ('subtree', function(nodes, keep_singletons) {
	if (keep_singletons === undefined) {
	    keep_singletons = false;
	}
    	var node_counts = {};
    	for (var i=0; i<nodes.length; i++) {
	    var n = nodes[i];
	    if (n !== undefined) {
		n.upstream (function (this_node){
		    var id = this_node.id();
		    if (node_counts[id] === undefined) {
			node_counts[id] = 0;
		    }
		    node_counts[id]++
    		});
	    }
    	}
    
	var is_singleton = function (node_data) {
	    var n_children = 0;
	    if (node_data.children === undefined) {
		return false;
	    }
	    for (var i=0; i<node_data.children.length; i++) {
		var id = node_data.children[i]._id;
		if (node_counts[id] > 0) {
		    n_children++;
		}
	    }
	    return n_children === 1;
	};

	var subtree = {};
	copy_data (data, subtree, 0, function (node_data) {
	    var node_id = node_data._id;
	    var counts = node_counts[node_id];
	    
	    // Is in path
	    if (counts > 0) {
		if (is_singleton(node_data) && !keep_singletons) {
		    return false; 
		}
		return true;
	    }
	    // Is not in path
	    return false;
	});

	return tnt_node(subtree.children[0]);
    });

    var copy_data = function (orig_data, subtree, currBranchLength, condition) {
        if (orig_data === undefined) {
	    return;
        }

        if (condition(orig_data)) {
	    var copy = copy_node(orig_data, currBranchLength);
	    if (subtree.children === undefined) {
                subtree.children = [];
	    }
	    subtree.children.push(copy);
	    if (orig_data.children === undefined) {
                return;
	    }
	    for (var i = 0; i < orig_data.children.length; i++) {
                copy_data (orig_data.children[i], copy, 0, condition);
	    }
        } else {
	    if (orig_data.children === undefined) {
                return;
	    }
	    currBranchLength += orig_data.branch_length || 0;
	    for (var i = 0; i < orig_data.children.length; i++) {
                copy_data(orig_data.children[i], subtree, currBranchLength, condition);
	    }
        }
    };

    var copy_node = function (node_data, extraBranchLength) {
	var copy = {};
	// copy all the own properties excepts links to other nodes or depth
	for (var param in node_data) {
	    if ((param === "children") ||
		(param === "_children") ||
		(param === "_parent") ||
		(param === "depth")) {
		continue;
	    }
	    if (node_data.hasOwnProperty(param)) {
		copy[param] = node_data[param];
	    }
	}
	if ((copy.branch_length !== undefined) && (extraBranchLength !== undefined)) {
	    copy.branch_length += extraBranchLength;
	}
	return copy;
    };

    
    // TODO: This method visits all the nodes
    // a more performant version should return true
    // the first time cbak(node) is true
    api.method ('present', function (cbak) {
	// cbak should return true/false
	var is_true = false;
	node.apply (function (n) {
	    if (cbak(n) === true) {
		is_true = true;
	    }
	});
	return is_true;
    });

    // cbak is called with two nodes
    // and should return a negative number, 0 or a positive number
    api.method ('sort', function (cbak) {
	if (data.children === undefined) {
	    return;
	}

	var new_children = [];
	for (var i=0; i<data.children.length; i++) {
	    new_children.push(tnt_node(data.children[i]));
	}

	new_children.sort(cbak);

	data.children = [];
	for (var i=0; i<new_children.length; i++) {
	    data.children.push(new_children[i].data());
	}

	for (var i=0; i<data.children.length; i++) {
	    tnt_node(data.children[i]).sort(cbak);
	}
    });

    api.method ('flatten', function (preserve_internal) {
	if (node.is_leaf()) {
	    return node;
	}
	var data = node.data();
	var newroot = copy_node(data);
	var nodes;
	if (preserve_internal) {
	    nodes = node.get_all_nodes();
	    nodes.shift(); // the self node is also included
	} else {
	    nodes = node.get_all_leaves();
	}
	newroot.children = [];
	for (var i=0; i<nodes.length; i++) {
	    delete (nodes[i].children);
	    newroot.children.push(copy_node(nodes[i].data()));
	}

	return tnt_node(newroot);
    });

    
    // TODO: This method only 'apply's to non collapsed nodes (ie ._children is not visited)
    // Would it be better to have an extra flag (true/false) to visit also collapsed nodes?
    api.method ('apply', function(cbak, deep) {
	if (deep === undefined) {
	    deep = false;
	}
	cbak(node);
	if (data.children !== undefined) {
	    for (var i=0; i<data.children.length; i++) {
		var n = tnt_node(data.children[i])
		n.apply(cbak, deep);
	    }
	}

	if ((data._children !== undefined) && deep) {
	    for (var j=0; j<data._children.length; j++) {
		var n = tnt_node(data._children[j]);
		n.apply(cbak, deep);
	    }
	}
    });

    // TODO: Not sure if it makes sense to set via a callback:
    // root.property (function (node, val) {
    //    node.deeper.field = val
    // }, 'new_value')
    api.method ('property', function(prop, value) {
	if (arguments.length === 1) {
	    if ((typeof prop) === 'function') {
		return prop(data)	
	    }
	    return data[prop]
	}
	if ((typeof prop) === 'function') {
	    prop(data, value);   
	}
	data[prop] = value;
	return node;
    });

    api.method ('is_leaf', function(deep) {
	if (deep) {
	    return ((data.children === undefined) && (data._children === undefined));
	}
	return data.children === undefined;
    });

    // It looks like the cluster can't be used for anything useful here
    // It is now included as an optional parameter to the tnt.tree() method call
    // so I'm commenting the getter
    // node.cluster = function() {
    // 	return cluster;
    // };

    // node.depth = function (node) {
    //     return node.depth;
    // };

//     node.name = function (node) {
//         return node.name;
//     };

    api.method ('id', function () {
	return node.property('_id');
    });

    api.method ('node_name', function () {
	return node.property('name');
    });

    api.method ('branch_length', function () {
	return node.property('branch_length');
    });

    api.method ('root_dist', function () {
	return node.property('_root_dist');
    });

    api.method ('children', function (deep) {
	var children = [];

	if (data.children) {
	    for (var i=0; i<data.children.length; i++) {
		children.push(tnt_node(data.children[i]));
	    }
	}
	if ((data._children) && deep) {
	    for (var j=0; j<data._children.length; j++) {
		children.push(tnt_node(data._children[j]));
	    }
	}
	if (children.length === 0) {
	    return undefined;
	}
	return children;
    });

    api.method ('parent', function () {
	if (data._parent === undefined) {
	    return undefined;
	}
	return tnt_node(data._parent);
    });

    return node;

};

module.exports = exports = tnt_node;


},{"tnt.api":6,"tnt.utils":11}],16:[function(require,module,exports){
var apijs = require('tnt.api');
var tree = {};

tree.diagonal = function () {
    var d = function (diagonalPath) {
        var source = diagonalPath.source;
        var target = diagonalPath.target;
        var midpointX = (source.x + target.x) / 2;
        var midpointY = (source.y + target.y) / 2;
        var pathData = [source, {x: target.x, y: source.y}, target];
        pathData = pathData.map(d.projection());
        return d.path()(pathData, radial_calc.call(this,pathData));
    };

    var api = apijs (d)
    	.getset ('projection')
    	.getset ('path');

    var coordinateToAngle = function (coord, radius) {
      	var wholeAngle = 2 * Math.PI,
        quarterAngle = wholeAngle / 4;

      	var coordQuad = coord[0] >= 0 ? (coord[1] >= 0 ? 1 : 2) : (coord[1] >= 0 ? 4 : 3),
        coordBaseAngle = Math.abs(Math.asin(coord[1] / radius));

      	// Since this is just based on the angle of the right triangle formed
      	// by the coordinate and the origin, each quad will have different
      	// offsets
      	var coordAngle;
      	switch (coordQuad) {
      	case 1:
      	    coordAngle = quarterAngle - coordBaseAngle;
      	    break;
      	case 2:
      	    coordAngle = quarterAngle + coordBaseAngle;
      	    break;
      	case 3:
      	    coordAngle = 2*quarterAngle + quarterAngle - coordBaseAngle;
      	    break;
      	case 4:
      	    coordAngle = 3*quarterAngle + coordBaseAngle;
      	}
      	return coordAngle;
    };

    var radial_calc = function (pathData) {
        var src = pathData[0];
        var mid = pathData[1];
        var dst = pathData[2];
        var radius = Math.sqrt(src[0]*src[0] + src[1]*src[1]);
        var srcAngle = coordinateToAngle(src, radius);
        var midAngle = coordinateToAngle(mid, radius);
        var clockwise = Math.abs(midAngle - srcAngle) > Math.PI ? midAngle <= srcAngle : midAngle > srcAngle;
        return {
            radius   : radius,
            clockwise : clockwise
        };
    };

    return d;
};

// vertical diagonal for rect branches
tree.diagonal.vertical = function (useArc) {
    var path = function(pathData, obj) {
        var src = pathData[0];
        var mid = pathData[1];
        var dst = pathData[2];
        var radius = (mid[1] - src[1]) * 2000;

        return "M" + src + " A" + [radius,radius] + " 0 0,0 " + mid + "M" + mid + "L" + dst;
        // return "M" + src + " L" + mid + " L" + dst;
    };

    var projection = function(d) {
        return [d.y, d.x];
    };

    return tree.diagonal()
      	.path(path)
      	.projection(projection);
};

tree.diagonal.radial = function () {
    var path = function(pathData, obj) {
        var src = pathData[0];
        var mid = pathData[1];
        var dst = pathData[2];
        var radius = obj.radius;
        var clockwise = obj.clockwise;

        if (clockwise) {
            return "M" + src + " A" + [radius,radius] + " 0 0,0 " + mid + "M" + mid + "L" + dst;
        } else {
            return "M" + mid + " A" + [radius,radius] + " 0 0,0 " + src + "M" + mid + "L" + dst;
        }
    };

    var projection = function(d) {
      	var r = d.y, a = (d.x - 90) / 180 * Math.PI;
      	return [r * Math.cos(a), r * Math.sin(a)];
    };

    return tree.diagonal()
      	.path(path)
      	.projection(projection);
};

module.exports = exports = tree.diagonal;

},{"tnt.api":6}],17:[function(require,module,exports){
var tree = require ("./tree.js");
tree.label = require("./label.js");
tree.diagonal = require("./diagonal.js");
tree.layout = require("./layout.js");
tree.node_display = require("./node_display.js");
// tree.node = require("tnt.tree.node");
// tree.parse_newick = require("tnt.newick").parse_newick;
// tree.parse_nhx = require("tnt.newick").parse_nhx;

module.exports = exports = tree;


},{"./diagonal.js":16,"./label.js":18,"./layout.js":19,"./node_display.js":20,"./tree.js":21}],18:[function(require,module,exports){
var apijs = require("tnt.api");
var tree = {};

tree.label = function () {
    "use strict";

    var dispatch = d3.dispatch ("click", "dblclick", "mouseover", "mouseout")

    // TODO: Not sure if we should be removing by default prev labels
    // or it would be better to have a separate remove method called by the vis
    // on update
    // We also have the problem that we may be transitioning from
    // text to img labels and we need to remove the label of a different type
    var label = function (node, layout_type, node_size) {
        if (typeof (node) !== 'function') {
            throw(node);
        }

        label.display().call(this, node, layout_type)
            .attr("class", "tnt_tree_label")
            .attr("transform", function (d) {
                var t = label.transform()(node, layout_type);
                return "translate (" + (t.translate[0] + node_size) + " " + t.translate[1] + ")rotate(" + t.rotate + ")";
            })
        // TODO: this click event is probably never fired since there is an onclick event in the node g element?
            .on("click", function () {
                dispatch.click.call(this, node)
            })
            .on("dblclick", function () {
                dispatch.dblclick.call(this, node)
            })
            .on("mouseover", function () {
                dispatch.mouseover.call(this, node)
            })
            .on("mouseout", function () {
                dispatch.mouseout.call(this, node)
            })
    };

    var api = apijs (label)
        .getset ('width', function () { throw "Need a width callback" })
        .getset ('height', function () { throw "Need a height callback" })
        .getset ('display', function () { throw "Need a display callback" })
        .getset ('transform', function () { throw "Need a transform callback" })
        //.getset ('on_click');

    return d3.rebind (label, dispatch, "on");
};

// Text based labels
tree.label.text = function () {
    var label = tree.label();

    var api = apijs (label)
        .getset ('fontsize', 10)
        .getset ('fontweight', "normal")
        .getset ('color', "#000")
        .getset ('text', function (d) {
            return d.data().name;
        })

    label.display (function (node, layout_type) {
        var l = d3.select(this)
            .append("text")
            .attr("text-anchor", function (d) {
                if (layout_type === "radial") {
                    return (d.x%360 < 180) ? "start" : "end";
                }
                return "start";
            })
            .text(function(){
                return label.text()(node)
            })
            .style('font-size', function () {
                return d3.functor(label.fontsize())(node) + "px";
            })
            .style('font-weight', function () {
                return d3.functor(label.fontweight())(node);
            })
            .style('fill', d3.functor(label.color())(node));

        return l;
    });

    label.transform (function (node, layout_type) {
        var d = node.data();
        var t = {
            translate : [5, 5],
            rotate : 0
        };
        if (layout_type === "radial") {
            t.translate[1] = t.translate[1] - (d.x%360 < 180 ? 0 : label.fontsize())
            t.rotate = (d.x%360 < 180 ? 0 : 180)
        }
        return t;
    });


    // label.transform (function (node) {
    // 	var d = node.data();
    // 	return "translate(10 5)rotate(" + (d.x%360 < 180 ? 0 : 180) + ")";
    // });

    label.width (function (node) {
        var svg = d3.select("body")
            .append("svg")
            .attr("height", 0)
            .style('visibility', 'hidden');

        var text = svg
            .append("text")
            .style('font-size', d3.functor(label.fontsize())(node) + "px")
            .text(label.text()(node));

        var width = text.node().getBBox().width;
        svg.remove();

        return width;
    });

    label.height (function (node) {
        return d3.functor(label.fontsize())(node);
    });

    return label;
};

// Image based labels
tree.label.img = function () {
    var label = tree.label();

    var api = apijs (label)
        .getset ('src', function () {})

    label.display (function (node, layout_type) {
        if (label.src()(node)) {
            var l = d3.select(this)
                .append("image")
                .attr("width", label.width()())
                .attr("height", label.height()())
                .attr("xlink:href", label.src()(node));
            return l;
        }
        // fallback text in case the img is not found?
        return d3.select(this)
            .append("text")
            .text("");
    });

    label.transform (function (node, layout_type) {
        var d = node.data();
        var t = {
            translate : [10, (-label.height()() / 2)],
            rotate : 0
        };

        if (layout_type === 'radial') {
            t.translate[0] = t.translate[0] + (d.x%360 < 180 ? 0 : label.width()()),
            t.translate[1] = t.translate[1] + (d.x%360 < 180 ? 0 : label.height()()),
            t.rotate = (d.x%360 < 180 ? 0 : 180)
        }

        return t;
    });

    return label;
};

// Labels made of 2+ simple labels
tree.label.composite = function () {
    var labels = [];

    var label = function (node, layout_type, node_size) {
        var curr_xoffset = 0;

        for (var i=0; i<labels.length; i++) {
            var display = labels[i];

            (function (offset) {
                display.transform (function (node, layout_type) {
                    var tsuper = display._super_.transform()(node, layout_type);
                    var t = {
                        translate : [offset + tsuper.translate[0], tsuper.translate[1]],
                        rotate : tsuper.rotate
                    };
                    return t;
                })
            })(curr_xoffset);

            curr_xoffset += 10;
            curr_xoffset += display.width()(node);

            display.call(this, node, layout_type, node_size);
        }
    };

    var api = apijs (label)

    api.method ('add_label', function (display, node) {
        display._super_ = {};
        apijs (display._super_)
            .get ('transform', display.transform());

        labels.push(display);
        return label;
    });

    api.method ('width', function () {
        return function (node) {
            var tot_width = 0;
            for (var i=0; i<labels.length; i++) {
                tot_width += parseInt(labels[i].width()(node));
                tot_width += parseInt(labels[i]._super_.transform()(node).translate[0]);
            }

            return tot_width;
        }
    });

    api.method ('height', function () {
        return function (node) {
            var max_height = 0;
            for (var i=0; i<labels.length; i++) {
                var curr_height = labels[i].height()(node);
                if ( curr_height > max_height) {
                    max_height = curr_height;
                }
            }
            return max_height;
        }
    });

    return label;
};

module.exports = exports = tree.label;

},{"tnt.api":6}],19:[function(require,module,exports){
// Based on the code by Ken-ichi Ueda in http://bl.ocks.org/kueda/1036776#d3.phylogram.js

var apijs = require("tnt.api");
var diagonal = require("./diagonal.js");
var tree = {};

tree.layout = function () {

    var l = function () {
    };

    var cluster = d3.layout.cluster()
    	.sort(null)
    	.value(function (d) {return d.length;} )
    	.separation(function () {return 1;});

    var api = apijs (l)
    	.getset ('scale', true)
    	.getset ('max_leaf_label_width', 0)
    	.method ("cluster", cluster)
    	.method('yscale', function () {throw "yscale is not defined in the base object";})
    	.method('adjust_cluster_size', function () {throw "adjust_cluster_size is not defined in the base object"; })
    	.method('width', function () {throw "width is not defined in the base object";})
    	.method('height', function () {throw "height is not defined in the base object";});

    api.method('scale_branch_lengths', function (curr) {
    	if (l.scale() === false) {
    	    return;
    	}

    	var nodes = curr.nodes;
    	var tree = curr.tree;

    	var root_dists = nodes.map (function (d) {
    	    return d._root_dist;
    	});

    	var yscale = l.yscale(root_dists);
    	tree.apply (function (node) {
    	    node.property("y", yscale(node.root_dist()));
    	});
    });

    return l;
};

tree.layout.vertical = function () {
    var layout = tree.layout();
    // Elements like 'labels' depend on the layout type. This exposes a way of identifying the layout type
    layout.type = "vertical";

    var api = apijs (layout)
    	.getset ('width', 360)
    	.get ('translate_vis', [20,20])
    	.method ('diagonal', diagonal.vertical)
    	.method ('transform_node', function (d) {
        	    return "translate(" + d.y + "," + d.x + ")";
    	});

    api.method('height', function (params) {
    	return (params.n_leaves * params.label_height);
    });

    api.method('yscale', function (dists) {
    	return d3.scale.linear()
    	    .domain([0, d3.max(dists)])
    	    .range([0, layout.width() - 20 - layout.max_leaf_label_width()]);
    });

    api.method('adjust_cluster_size', function (params) {
    	var h = layout.height(params);
    	var w = layout.width() - layout.max_leaf_label_width() - layout.translate_vis()[0] - params.label_padding;
    	layout.cluster.size ([h,w]);
    	return layout;
    });

    return layout;
};

tree.layout.radial = function () {
    var layout = tree.layout();
    // Elements like 'labels' depend on the layout type. This exposes a way of identifying the layout type
    layout.type = 'radial';

    var default_width = 360;
    var r = default_width / 2;

    var conf = {
    	width : 360
    };

    var api = apijs (layout)
    	.getset (conf)
    	.getset ('translate_vis', [r, r]) // TODO: 1.3 should be replaced by a sensible value
    	.method ('transform_node', function (d) {
    	    return "rotate(" + (d.x - 90) + ")translate(" + d.y + ")";
    	})
    	.method ('diagonal', diagonal.radial)
    	.method ('height', function () { return conf.width; });

    // Changes in width affect changes in r
    layout.width.transform (function (val) {
    	r = val / 2;
    	layout.cluster.size([360, r]);
    	layout.translate_vis([r, r]);
    	return val;
    });

    api.method ("yscale",  function (dists) {
	return d3.scale.linear()
	    .domain([0,d3.max(dists)])
	    .range([0, r]);
    });

    api.method ("adjust_cluster_size", function (params) {
    	r = (layout.width()/2) - layout.max_leaf_label_width() - 20;
    	layout.cluster.size([360, r]);
    	return layout;
    });

    return layout;
};

module.exports = exports = tree.layout;

},{"./diagonal.js":16,"tnt.api":6}],20:[function(require,module,exports){
var apijs = require("tnt.api");
var tree = {};

tree.node_display = function () {
    "use strict";

    var n = function (node) {
        var proxy;
        var thisProxy = d3.select(this).select(".tnt_tree_node_proxy");
        if (thisProxy[0][0] === null) {
            var size = d3.functor(n.size())(node);
            proxy = d3.select(this)
                .append("rect")
                .attr("class", "tnt_tree_node_proxy");
        } else {
            proxy = thisProxy;
        }

    	n.display().call(this, node);
        var dim = this.getBBox();
        proxy
            .attr("x", dim.x)
            .attr("y", dim.y)
            .attr("width", dim.width)
            .attr("height", dim.height);
    };

    var api = apijs (n)
    	.getset("size", 4.4)
    	.getset("fill", "black")
    	.getset("stroke", "black")
    	.getset("stroke_width", "1px")
    	.getset("display", function () {
            throw "display is not defined in the base object";
        });
    api.method("reset", function () {
        d3.select(this)
            .selectAll("*:not(.tnt_tree_node_proxy)")
            .remove();
    });

    return n;
};

tree.node_display.circle = function () {
    var n = tree.node_display();

    n.display (function (node) {
    	d3.select(this)
            .append("circle")
            .attr("r", function (d) {
                return d3.functor(n.size())(node);
            })
            .attr("fill", function (d) {
                return d3.functor(n.fill())(node);
            })
            .attr("stroke", function (d) {
                return d3.functor(n.stroke())(node);
            })
            .attr("stroke-width", function (d) {
                return d3.functor(n.stroke_width())(node);
            })
            .attr("class", "tnt_node_display_elem");
    });

    return n;
};

tree.node_display.square = function () {
    var n = tree.node_display();

    n.display (function (node) {
	var s = d3.functor(n.size())(node);
	d3.select(this)
        .append("rect")
        .attr("x", function (d) {
            return -s;
        })
        .attr("y", function (d) {
            return -s;
        })
        .attr("width", function (d) {
            return s*2;
        })
        .attr("height", function (d) {
            return s*2;
        })
        .attr("fill", function (d) {
            return d3.functor(n.fill())(node);
        })
        .attr("stroke", function (d) {
            return d3.functor(n.stroke())(node);
        })
        .attr("stroke-width", function (d) {
            return d3.functor(n.stroke_width())(node);
        })
        .attr("class", "tnt_node_display_elem");
    });

    return n;
};

tree.node_display.triangle = function () {
    var n = tree.node_display();

    n.display (function (node) {
	var s = d3.functor(n.size())(node);
	d3.select(this)
        .append("polygon")
        .attr("points", (-s) + ",0 " + s + "," + (-s) + " " + s + "," + s)
        .attr("fill", function (d) {
            return d3.functor(n.fill())(node);
        })
        .attr("stroke", function (d) {
            return d3.functor(n.stroke())(node);
        })
        .attr("stroke-width", function (d) {
            return d3.functor(n.stroke_width())(node);
        })
        .attr("class", "tnt_node_display_elem");
    });

    return n;
};

// tree.node_display.cond = function () {
//     var n = tree.node_display();
//
//     // conditions are objects with
//     // name : a name for this display
//     // callback: the condition to apply (receives a tnt.node)
//     // display: a node_display
//     var conds = [];
//
//     n.display (function (node) {
//         var s = d3.functor(n.size())(node);
//         for (var i=0; i<conds.length; i++) {
//             var cond = conds[i];
//             // For each node, the first condition met is used
//             if (d3.functor(cond.callback).call(this, node) === true) {
//                 cond.display.call(this, node);
//                 break;
//             }
//         }
//     });
//
//     var api = apijs(n);
//
//     api.method("add", function (name, cbak, node_display) {
//         conds.push({ name : name,
//             callback : cbak,
//             display : node_display
//         });
//         return n;
//     });
//
//     api.method("reset", function () {
//         conds = [];
//         return n;
//     });
//
//     api.method("update", function (name, cbak, new_display) {
//         for (var i=0; i<conds.length; i++) {
//             if (conds[i].name === name) {
//                 conds[i].callback = cbak;
//                 conds[i].display = new_display;
//             }
//         }
//         return n;
//     });
//
//     return n;
//
// };

module.exports = exports = tree.node_display;

},{"tnt.api":6}],21:[function(require,module,exports){
var apijs = require("tnt.api");
var tnt_tree_node = require("tnt.tree.node");

var tree = function () {
    "use strict";

    var dispatch = d3.dispatch ("click", "dblclick", "mouseover", "mouseout");

    var conf = {
        duration         : 500,      // Duration of the transitions
        node_display     : tree.node_display.circle(),
        label            : tree.label.text(),
        layout           : tree.layout.vertical(),
        // on_click         : function () {},
        // on_dbl_click     : function () {},
        // on_mouseover     : function () {},
        branch_color     : 'black',
        id               : function (d) {
            return d._id;
        }
    };

    // Keep track of the focused node
    // TODO: Would it be better to have multiple focused nodes? (ie use an array)
    // var focused_node;

    // Extra delay in the transitions (TODO: Needed?)
    var delay = 0;

    // Ease of the transitions
    var ease = "cubic-in-out";

    // The id of the tree container
    var div_id;

    // The tree visualization (svg)
    var svg;
    var vis;
    var links_g;
    var nodes_g;

    // TODO: For now, counts are given only for leaves
    // but it may be good to allow counts for internal nodes
    var counts = {};

    // The full tree
    var base = {
        tree : undefined,
        data : undefined,
        nodes : undefined,
        links : undefined
    };

    // The curr tree. Needed to re-compute the links / nodes positions of subtrees
    var curr = {
        tree : undefined,
        data : undefined,
        nodes : undefined,
        links : undefined
    };

    // The cbak returned
    var t = function (div) {
    	div_id = d3.select(div).attr("id");

        var tree_div = d3.select(div)
            .append("div")
            .style("width", (conf.layout.width() +  "px"))
            .attr("class", "tnt_groupDiv");

    	var cluster = conf.layout.cluster;

    	var n_leaves = curr.tree.get_all_leaves().length;

    	var max_leaf_label_length = function (tree) {
    	    var max = 0;
    	    var leaves = tree.get_all_leaves();
    	    for (var i=0; i<leaves.length; i++) {
                var label_width = conf.label.width()(leaves[i]) + d3.functor (conf.node_display.size())(leaves[i]);
                if (label_width > max) {
                    max = label_width;
                }
    	    }
    	    return max;
    	};

        var max_leaf_node_height = function (tree) {
            var max = 0;
            var leaves = tree.get_all_leaves();
            for (var i=0; i<leaves.length; i++) {
                var node_height = d3.functor(conf.node_display.size())(leaves[i]) * 2;
                var label_height = d3.functor(conf.label.height())(leaves[i]);

                max = d3.max([max, node_height, label_height]);
            }
            return max;
        };

    	var max_label_length = max_leaf_label_length(curr.tree);
    	conf.layout.max_leaf_label_width(max_label_length);

    	var max_node_height = max_leaf_node_height(curr.tree);

    	// Cluster size is the result of...
    	// total width of the vis - transform for the tree - max_leaf_label_width - horizontal transform of the label
    	// TODO: Substitute 15 by the horizontal transform of the nodes
    	var cluster_size_params = {
    	    n_leaves : n_leaves,
    	    label_height : max_node_height,
    	    label_padding : 15
    	};

    	conf.layout.adjust_cluster_size(cluster_size_params);

    	var diagonal = conf.layout.diagonal();
    	var transform = conf.layout.transform_node;

    	svg = tree_div
    	    .append("svg")
    	    .attr("width", conf.layout.width())
    	    .attr("height", conf.layout.height(cluster_size_params) + 30)
    	    .attr("fill", "none");

    	vis = svg
    	    .append("g")
    	    .attr("id", "tnt_st_" + div_id)
    	    .attr("transform",
    		  "translate(" +
    		  conf.layout.translate_vis()[0] +
    		  "," +
    		  conf.layout.translate_vis()[1] +
    		  ")");

    	curr.nodes = cluster.nodes(curr.data);
    	conf.layout.scale_branch_lengths(curr);
    	curr.links = cluster.links(curr.nodes);

    	// LINKS
    	// All the links are grouped in a g element
    	links_g = vis
    	    .append("g")
    	    .attr("class", "links");
    	nodes_g = vis
    	    .append("g")
    	    .attr("class", "nodes");

    	//var link = vis
    	var link = links_g
    	    .selectAll("path.tnt_tree_link")
    	    .data(curr.links, function(d){
                return conf.id(d.target);
            });

    	link
    	    .enter()
    	    .append("path")
    	    .attr("class", "tnt_tree_link")
    	    .attr("id", function(d) {
    	    	return "tnt_tree_link_" + div_id + "_" + conf.id(d.target);
    	    })
    	    .style("stroke", function (d) {
                return d3.functor(conf.branch_color)(tnt_tree_node(d.source), tnt_tree_node(d.target));
    	    })
    	    .attr("d", diagonal);

    	// NODES
    	//var node = vis
    	var node = nodes_g
    	    .selectAll("g.tnt_tree_node")
    	    .data(curr.nodes, function(d) {
                return conf.id(d);
            });

    	var new_node = node
    	    .enter().append("g")
    	    .attr("class", function(n) {
        		if (n.children) {
        		    if (n.depth === 0) {
            			return "root tnt_tree_node";
        		    } else {
            			return "inner tnt_tree_node";
        		    }
        		} else {
        		    return "leaf tnt_tree_node";
        		}
        	})
    	    .attr("id", function(d) {
        		return "tnt_tree_node_" + div_id + "_" + d._id;
    	    })
    	    .attr("transform", transform);

    	// display node shape
    	new_node
    	    .each (function (d) {
        		conf.node_display.call(this, tnt_tree_node(d));
    	    });

    	// display node label
    	new_node
    	    .each (function (d) {
    	    	conf.label.call(this, tnt_tree_node(d), conf.layout.type, d3.functor(conf.node_display.size())(tnt_tree_node(d)));
    	    });

        new_node.on("click", function (node) {
            var my_node = tnt_tree_node(node);
            tree.trigger("node:click", my_node);
            dispatch.click.call(this, my_node);
        });
        new_node.on("dblclick", function (node) {
            var my_node = tnt_tree_node(node);
            tree.trigger("node:dblclick", my_node);
            dispatch.dblclick.call(this, my_node);
        });
        new_node.on("mouseover", function (node) {
            var my_node = tnt_tree_node(node);
            tree.trigger("node:hover", tnt_tree_node(node));
            dispatch.mouseover.call(this, my_node);
        });
        new_node.on("mouseout", function (node) {
            var my_node = tnt_tree_node(node);
            tree.trigger("node:mouseout", tnt_tree_node(node));
            dispatch.mouseout.call(this, my_node);
        });


    	// Update plots an updated tree
        api.method ('update', function() {
            tree_div
                .style("width", (conf.layout.width() + "px"));
    	    svg.attr("width", conf.layout.width());

    	    var cluster = conf.layout.cluster;
    	    var diagonal = conf.layout.diagonal();
    	    var transform = conf.layout.transform_node;

    	    var max_label_length = max_leaf_label_length(curr.tree);
    	    conf.layout.max_leaf_label_width(max_label_length);

    	    var max_node_height = max_leaf_node_height(curr.tree);

    	    // Cluster size is the result of...
    	    // total width of the vis - transform for the tree - max_leaf_label_width - horizontal transform of the label
        	// TODO: Substitute 15 by the transform of the nodes (probably by selecting one node assuming all the nodes have the same transform
    	    var n_leaves = curr.tree.get_all_leaves().length;
    	    var cluster_size_params = {
        		n_leaves : n_leaves,
        		label_height : max_node_height,
        		label_padding : 15
    	    };
    	    conf.layout.adjust_cluster_size(cluster_size_params);

            svg
                .transition()
                .duration(conf.duration)
                .ease(ease)
                .attr("height", conf.layout.height(cluster_size_params) + 30); // height is in the layout

    	    vis
                .transition()
                .duration(conf.duration)
                .attr("transform",
                "translate(" +
                conf.layout.translate_vis()[0] +
                "," +
                conf.layout.translate_vis()[1] +
                ")");

            curr.nodes = cluster.nodes(curr.data);
            conf.layout.scale_branch_lengths(curr);
            curr.links = cluster.links(curr.nodes);

    	    // LINKS
    	    var link = links_g
        		.selectAll("path.tnt_tree_link")
        		.data(curr.links, function(d){
                    return conf.id(d.target);
                });

            // NODES
    	    var node = nodes_g
        		.selectAll("g.tnt_tree_node")
        		.data(curr.nodes, function(d) {
                    return conf.id(d);
                });

    	    var exit_link = link
        		.exit()
        		.remove();

    	    link
        		.enter()
        		.append("path")
        		.attr("class", "tnt_tree_link")
        		.attr("id", function (d) {
        		    return "tnt_tree_link_" + div_id + "_" + conf.id(d.target);
        		})
        		.attr("stroke", function (d) {
        		    return d3.functor(conf.branch_color)(tnt_tree_node(d.source), tnt_tree_node(d.target));
        		})
        		.attr("d", diagonal);

    	    link
    	    	.transition()
        		.ease(ease)
    	    	.duration(conf.duration)
    	    	.attr("d", diagonal);


    	    // Nodes
    	    var new_node = node
        		.enter()
        		.append("g")
        		.attr("class", function(n) {
        		    if (n.children) {
            			if (n.depth === 0) {
                            return "root tnt_tree_node";
            			} else {
                            return "inner tnt_tree_node";
            			}
        		    } else {
                        return "leaf tnt_tree_node";
        		    }
        		})
        		.attr("id", function (d) {
        		    return "tnt_tree_node_" + div_id + "_" + d._id;
        		})
        		.attr("transform", transform);

    	    // Exiting nodes are just removed
    	    node
        		.exit()
        		.remove();

            new_node.on("click", function (node) {
                var my_node = tnt_tree_node(node);
                tree.trigger("node:click", my_node);
                dispatch.click.call(this, my_node);
            });
            new_node.on("dblclick", function (node) {
                var my_node = tnt_tree_node(node);
                tree.trigger("node:dblclick", my_node);
                dispatch.dblclick.call(this, my_node);
            });
            new_node.on("mouseover", function (node) {
                var my_node = tnt_tree_node(node);
                tree.trigger("node:hover", tnt_tree_node(node));
                dispatch.mouseover.call(this, my_node);
            });
            new_node.on("mouseout", function (node) {
                var my_node = tnt_tree_node(node);
                tree.trigger("node:mouseout", tnt_tree_node(node));
                dispatch.mouseout.call(this, my_node);
            });

    	    // // We need to re-create all the nodes again in case they have changed lively (or the layout)
    	    // node.selectAll("*").remove();
    	    // new_node
    		//     .each(function (d) {
        	// 		conf.node_display.call(this, tnt_tree_node(d));
    		//     });
            //
    	    // // We need to re-create all the labels again in case they have changed lively (or the layout)
    	    // new_node
    		//     .each (function (d) {
        	// 		conf.label.call(this, tnt_tree_node(d), conf.layout.type, d3.functor(conf.node_display.size())(tnt_tree_node(d)));
    		//     });

            t.update_nodes();

    	    node
        		.transition()
        		.ease(ease)
        		.duration(conf.duration)
        		.attr("transform", transform);

    	});

        api.method('update_nodes', function () {
            var node = nodes_g
                .selectAll("g.tnt_tree_node");

            // re-create all the nodes again
            // node.selectAll("*").remove();
            node
                .each(function () {
                    conf.node_display.reset.call(this);
                });

            node
                .each(function (d) {
                    //console.log(conf.node_display());
                    conf.node_display.call(this, tnt_tree_node(d));
                });

            // re-create all the labels again
            node
                .each (function (d) {
                    conf.label.call(this, tnt_tree_node(d), conf.layout.type, d3.functor(conf.node_display.size())(tnt_tree_node(d)));
                });

        });
    };

    // API
    var api = apijs (t)
    	.getset (conf);

    // n is the number to interpolate, the second argument can be either "tree" or "pixel" depending
    // if n is set to tree units or pixels units
    api.method ('scale_bar', function (n, units) {
        if (!t.layout().scale()) {
            return;
        }
        if (!units) {
            units = "pixel";
        }
        var val;
        links_g.select("path")
            .each(function (p) {
                var d = this.getAttribute("d");

                var pathParts = d.split(/[MLA]/);
                var toStr = pathParts.pop();
                var fromStr = pathParts.pop();

                var from = fromStr.split(",");
                var to = toStr.split(",");

                var deltaX = to[0] - from[0];
                var deltaY = to[1] - from[1];
                var pixelsDist = Math.sqrt(deltaX*deltaX + deltaY*deltaY);

                var source = p.source;
                var target = p.target;

                var branchDist = target._root_dist - source._root_dist;

                // Supposing pixelsDist has been passed
                if (units === "pixel") {
                    val = (branchDist / pixelsDist) * n;
                } else if (units === "tree") {
                    val = (pixelsDist / branchDist) * n;
                }
            });
            if (isNaN(val)) {
                return;
            }
            return val;
        });

    // TODO: Rewrite data using getset / finalizers & transforms
    api.method ('data', function (d) {
        if (!arguments.length) {
            return base.data;
        }

        // The original data is stored as the base and curr data
        base.data = d;
        curr.data = d;

        // Set up a new tree based on the data
        var newtree = tnt_tree_node(base.data);

        t.root(newtree);
        base.tree = newtree;
        curr.tree = base.tree;

        tree.trigger("data:hasChanged", base.data);

        return this;
    });

    // TODO: This is only a getter
    api.method ('root', function () {
        return curr.tree;
    });

    // api.method ('subtree', function (curr_nodes, keepSingletons) {
    //     var subtree = base.tree.subtree(curr_nodes, keepSingletons);
    //     curr.data = subtree.data();
    //     curr.tree = subtree;
    //
    //     return this;
    // });

    // api.method ('reroot', function (node, keepSingletons) {
    //     // find
    //     var root = t.root();
    //     var found_node = t.root().find_node(function (n) {
    //         return node.id() === n.id();
    //     });
    //     var subtree = root.subtree(found_node.get_all_leaves(), keepSingletons);
    //
    //     return subtree;
    // });

    return d3.rebind (t, dispatch, "on");
};

module.exports = exports = tree;

},{"tnt.api":6,"tnt.tree.node":10}]},{},[1]);
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvZ3VscC1icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRyZWUvZmFrZV9mZDljMzkwNi5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9pbmRleC5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvYmlvanMtZXZlbnRzL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy9iaW9qcy1ldmVudHMvbm9kZV9tb2R1bGVzL2JhY2tib25lLWV2ZW50cy1zdGFuZGFsb25lL2JhY2tib25lLWV2ZW50cy1zdGFuZGFsb25lLmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy9iaW9qcy1ldmVudHMvbm9kZV9tb2R1bGVzL2JhY2tib25lLWV2ZW50cy1zdGFuZGFsb25lL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy90bnQuYXBpL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy90bnQuYXBpL3NyYy9hcGkuanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRyZWUvbm9kZV9tb2R1bGVzL3RudC5uZXdpY2svaW5kZXguanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRyZWUvbm9kZV9tb2R1bGVzL3RudC5uZXdpY2svc3JjL25ld2ljay5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvdG50LnRyZWUubm9kZS9pbmRleC5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvdG50LnRyZWUubm9kZS9ub2RlX21vZHVsZXMvdG50LnV0aWxzL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy90bnQudHJlZS5ub2RlL25vZGVfbW9kdWxlcy90bnQudXRpbHMvc3JjL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL25vZGVfbW9kdWxlcy90bnQudHJlZS5ub2RlL25vZGVfbW9kdWxlcy90bnQudXRpbHMvc3JjL3JlZHVjZS5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvdG50LnRyZWUubm9kZS9ub2RlX21vZHVsZXMvdG50LnV0aWxzL3NyYy91dGlscy5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9ub2RlX21vZHVsZXMvdG50LnRyZWUubm9kZS9zcmMvbm9kZS5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9zcmMvZGlhZ29uYWwuanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRyZWUvc3JjL2luZGV4LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL3NyYy9sYWJlbC5qcyIsIi9Vc2Vycy9waWduYXRlbGxpL3NyYy9yZXBvcy90bnQudHJlZS9zcmMvbGF5b3V0LmpzIiwiL1VzZXJzL3BpZ25hdGVsbGkvc3JjL3JlcG9zL3RudC50cmVlL3NyYy9ub2RlX2Rpc3BsYXkuanMiLCIvVXNlcnMvcGlnbmF0ZWxsaS9zcmMvcmVwb3MvdG50LnRyZWUvc3JjL3RyZWUuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDUkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNWQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNyQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDcFJBO0FBQ0E7O0FDREE7QUFDQTs7QUNEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3hMQTtBQUNBOztBQ0RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM5SkE7QUFDQTtBQUNBOztBQ0ZBO0FBQ0E7O0FDREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ1hBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3BMQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzNDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDN2ZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDN0dBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNYQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDNU9BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDNUhBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNoTEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3Rocm93IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIil9dmFyIGY9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGYuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sZixmLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsImlmICh0eXBlb2YgdG50ID09PSBcInVuZGVmaW5lZFwiKSB7XG4gICAgbW9kdWxlLmV4cG9ydHMgPSB0bnQgPSB7fTtcbn1cbnRudC50cmVlID0gcmVxdWlyZShcIi4vaW5kZXguanNcIik7XG50bnQudHJlZS5ub2RlID0gcmVxdWlyZShcInRudC50cmVlLm5vZGVcIik7XG50bnQudHJlZS5wYXJzZV9uZXdpY2sgPSByZXF1aXJlKFwidG50Lm5ld2lja1wiKS5wYXJzZV9uZXdpY2s7XG50bnQudHJlZS5wYXJzZV9uaHggPSByZXF1aXJlKFwidG50Lm5ld2lja1wiKS5wYXJzZV9uaHg7XG5cbiIsIi8vIGlmICh0eXBlb2YgdG50ID09PSBcInVuZGVmaW5lZFwiKSB7XG4vLyAgICAgbW9kdWxlLmV4cG9ydHMgPSB0bnQgPSB7fVxuLy8gfVxubW9kdWxlLmV4cG9ydHMgPSB0cmVlID0gcmVxdWlyZShcIi4vc3JjL2luZGV4LmpzXCIpO1xudmFyIGV2ZW50c3lzdGVtID0gcmVxdWlyZShcImJpb2pzLWV2ZW50c1wiKTtcbmV2ZW50c3lzdGVtLm1peGluKHRyZWUpO1xuLy90bnQudXRpbHMgPSByZXF1aXJlKFwidG50LnV0aWxzXCIpO1xuLy90bnQudG9vbHRpcCA9IHJlcXVpcmUoXCJ0bnQudG9vbHRpcFwiKTtcbi8vdG50LnRyZWUgPSByZXF1aXJlKFwiLi9zcmMvaW5kZXguanNcIik7XG5cbiIsInZhciBldmVudHMgPSByZXF1aXJlKFwiYmFja2JvbmUtZXZlbnRzLXN0YW5kYWxvbmVcIik7XG5cbmV2ZW50cy5vbkFsbCA9IGZ1bmN0aW9uKGNhbGxiYWNrLGNvbnRleHQpe1xuICB0aGlzLm9uKFwiYWxsXCIsIGNhbGxiYWNrLGNvbnRleHQpO1xuICByZXR1cm4gdGhpcztcbn07XG5cbi8vIE1peGluIHV0aWxpdHlcbmV2ZW50cy5vbGRNaXhpbiA9IGV2ZW50cy5taXhpbjtcbmV2ZW50cy5taXhpbiA9IGZ1bmN0aW9uKHByb3RvKSB7XG4gIGV2ZW50cy5vbGRNaXhpbihwcm90byk7XG4gIC8vIGFkZCBjdXN0b20gb25BbGxcbiAgdmFyIGV4cG9ydHMgPSBbJ29uQWxsJ107XG4gIGZvcih2YXIgaT0wOyBpIDwgZXhwb3J0cy5sZW5ndGg7aSsrKXtcbiAgICB2YXIgbmFtZSA9IGV4cG9ydHNbaV07XG4gICAgcHJvdG9bbmFtZV0gPSB0aGlzW25hbWVdO1xuICB9XG4gIHJldHVybiBwcm90bztcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gZXZlbnRzO1xuIiwiLyoqXG4gKiBTdGFuZGFsb25lIGV4dHJhY3Rpb24gb2YgQmFja2JvbmUuRXZlbnRzLCBubyBleHRlcm5hbCBkZXBlbmRlbmN5IHJlcXVpcmVkLlxuICogRGVncmFkZXMgbmljZWx5IHdoZW4gQmFja29uZS91bmRlcnNjb3JlIGFyZSBhbHJlYWR5IGF2YWlsYWJsZSBpbiB0aGUgY3VycmVudFxuICogZ2xvYmFsIGNvbnRleHQuXG4gKlxuICogTm90ZSB0aGF0IGRvY3Mgc3VnZ2VzdCB0byB1c2UgdW5kZXJzY29yZSdzIGBfLmV4dGVuZCgpYCBtZXRob2QgdG8gYWRkIEV2ZW50c1xuICogc3VwcG9ydCB0byBzb21lIGdpdmVuIG9iamVjdC4gQSBgbWl4aW4oKWAgbWV0aG9kIGhhcyBiZWVuIGFkZGVkIHRvIHRoZSBFdmVudHNcbiAqIHByb3RvdHlwZSB0byBhdm9pZCB1c2luZyB1bmRlcnNjb3JlIGZvciB0aGF0IHNvbGUgcHVycG9zZTpcbiAqXG4gKiAgICAgdmFyIG15RXZlbnRFbWl0dGVyID0gQmFja2JvbmVFdmVudHMubWl4aW4oe30pO1xuICpcbiAqIE9yIGZvciBhIGZ1bmN0aW9uIGNvbnN0cnVjdG9yOlxuICpcbiAqICAgICBmdW5jdGlvbiBNeUNvbnN0cnVjdG9yKCl7fVxuICogICAgIE15Q29uc3RydWN0b3IucHJvdG90eXBlLmZvbyA9IGZ1bmN0aW9uKCl7fVxuICogICAgIEJhY2tib25lRXZlbnRzLm1peGluKE15Q29uc3RydWN0b3IucHJvdG90eXBlKTtcbiAqXG4gKiAoYykgMjAwOS0yMDEzIEplcmVteSBBc2hrZW5hcywgRG9jdW1lbnRDbG91ZCBJbmMuXG4gKiAoYykgMjAxMyBOaWNvbGFzIFBlcnJpYXVsdFxuICovXG4vKiBnbG9iYWwgZXhwb3J0czp0cnVlLCBkZWZpbmUsIG1vZHVsZSAqL1xuKGZ1bmN0aW9uKCkge1xuICB2YXIgcm9vdCA9IHRoaXMsXG4gICAgICBuYXRpdmVGb3JFYWNoID0gQXJyYXkucHJvdG90eXBlLmZvckVhY2gsXG4gICAgICBoYXNPd25Qcm9wZXJ0eSA9IE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHksXG4gICAgICBzbGljZSA9IEFycmF5LnByb3RvdHlwZS5zbGljZSxcbiAgICAgIGlkQ291bnRlciA9IDA7XG5cbiAgLy8gUmV0dXJucyBhIHBhcnRpYWwgaW1wbGVtZW50YXRpb24gbWF0Y2hpbmcgdGhlIG1pbmltYWwgQVBJIHN1YnNldCByZXF1aXJlZFxuICAvLyBieSBCYWNrYm9uZS5FdmVudHNcbiAgZnVuY3Rpb24gbWluaXNjb3JlKCkge1xuICAgIHJldHVybiB7XG4gICAgICBrZXlzOiBPYmplY3Qua2V5cyB8fCBmdW5jdGlvbiAob2JqKSB7XG4gICAgICAgIGlmICh0eXBlb2Ygb2JqICE9PSBcIm9iamVjdFwiICYmIHR5cGVvZiBvYmogIT09IFwiZnVuY3Rpb25cIiB8fCBvYmogPT09IG51bGwpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgVHlwZUVycm9yKFwia2V5cygpIGNhbGxlZCBvbiBhIG5vbi1vYmplY3RcIik7XG4gICAgICAgIH1cbiAgICAgICAgdmFyIGtleSwga2V5cyA9IFtdO1xuICAgICAgICBmb3IgKGtleSBpbiBvYmopIHtcbiAgICAgICAgICBpZiAob2JqLmhhc093blByb3BlcnR5KGtleSkpIHtcbiAgICAgICAgICAgIGtleXNba2V5cy5sZW5ndGhdID0ga2V5O1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICByZXR1cm4ga2V5cztcbiAgICAgIH0sXG5cbiAgICAgIHVuaXF1ZUlkOiBmdW5jdGlvbihwcmVmaXgpIHtcbiAgICAgICAgdmFyIGlkID0gKytpZENvdW50ZXIgKyAnJztcbiAgICAgICAgcmV0dXJuIHByZWZpeCA/IHByZWZpeCArIGlkIDogaWQ7XG4gICAgICB9LFxuXG4gICAgICBoYXM6IGZ1bmN0aW9uKG9iaiwga2V5KSB7XG4gICAgICAgIHJldHVybiBoYXNPd25Qcm9wZXJ0eS5jYWxsKG9iaiwga2V5KTtcbiAgICAgIH0sXG5cbiAgICAgIGVhY2g6IGZ1bmN0aW9uKG9iaiwgaXRlcmF0b3IsIGNvbnRleHQpIHtcbiAgICAgICAgaWYgKG9iaiA9PSBudWxsKSByZXR1cm47XG4gICAgICAgIGlmIChuYXRpdmVGb3JFYWNoICYmIG9iai5mb3JFYWNoID09PSBuYXRpdmVGb3JFYWNoKSB7XG4gICAgICAgICAgb2JqLmZvckVhY2goaXRlcmF0b3IsIGNvbnRleHQpO1xuICAgICAgICB9IGVsc2UgaWYgKG9iai5sZW5ndGggPT09ICtvYmoubGVuZ3RoKSB7XG4gICAgICAgICAgZm9yICh2YXIgaSA9IDAsIGwgPSBvYmoubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgICAgICAgICBpdGVyYXRvci5jYWxsKGNvbnRleHQsIG9ialtpXSwgaSwgb2JqKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZm9yICh2YXIga2V5IGluIG9iaikge1xuICAgICAgICAgICAgaWYgKHRoaXMuaGFzKG9iaiwga2V5KSkge1xuICAgICAgICAgICAgICBpdGVyYXRvci5jYWxsKGNvbnRleHQsIG9ialtrZXldLCBrZXksIG9iaik7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9LFxuXG4gICAgICBvbmNlOiBmdW5jdGlvbihmdW5jKSB7XG4gICAgICAgIHZhciByYW4gPSBmYWxzZSwgbWVtbztcbiAgICAgICAgcmV0dXJuIGZ1bmN0aW9uKCkge1xuICAgICAgICAgIGlmIChyYW4pIHJldHVybiBtZW1vO1xuICAgICAgICAgIHJhbiA9IHRydWU7XG4gICAgICAgICAgbWVtbyA9IGZ1bmMuYXBwbHkodGhpcywgYXJndW1lbnRzKTtcbiAgICAgICAgICBmdW5jID0gbnVsbDtcbiAgICAgICAgICByZXR1cm4gbWVtbztcbiAgICAgICAgfTtcbiAgICAgIH1cbiAgICB9O1xuICB9XG5cbiAgdmFyIF8gPSBtaW5pc2NvcmUoKSwgRXZlbnRzO1xuXG4gIC8vIEJhY2tib25lLkV2ZW50c1xuICAvLyAtLS0tLS0tLS0tLS0tLS1cblxuICAvLyBBIG1vZHVsZSB0aGF0IGNhbiBiZSBtaXhlZCBpbiB0byAqYW55IG9iamVjdCogaW4gb3JkZXIgdG8gcHJvdmlkZSBpdCB3aXRoXG4gIC8vIGN1c3RvbSBldmVudHMuIFlvdSBtYXkgYmluZCB3aXRoIGBvbmAgb3IgcmVtb3ZlIHdpdGggYG9mZmAgY2FsbGJhY2tcbiAgLy8gZnVuY3Rpb25zIHRvIGFuIGV2ZW50OyBgdHJpZ2dlcmAtaW5nIGFuIGV2ZW50IGZpcmVzIGFsbCBjYWxsYmFja3MgaW5cbiAgLy8gc3VjY2Vzc2lvbi5cbiAgLy9cbiAgLy8gICAgIHZhciBvYmplY3QgPSB7fTtcbiAgLy8gICAgIF8uZXh0ZW5kKG9iamVjdCwgQmFja2JvbmUuRXZlbnRzKTtcbiAgLy8gICAgIG9iamVjdC5vbignZXhwYW5kJywgZnVuY3Rpb24oKXsgYWxlcnQoJ2V4cGFuZGVkJyk7IH0pO1xuICAvLyAgICAgb2JqZWN0LnRyaWdnZXIoJ2V4cGFuZCcpO1xuICAvL1xuICBFdmVudHMgPSB7XG5cbiAgICAvLyBCaW5kIGFuIGV2ZW50IHRvIGEgYGNhbGxiYWNrYCBmdW5jdGlvbi4gUGFzc2luZyBgXCJhbGxcImAgd2lsbCBiaW5kXG4gICAgLy8gdGhlIGNhbGxiYWNrIHRvIGFsbCBldmVudHMgZmlyZWQuXG4gICAgb246IGZ1bmN0aW9uKG5hbWUsIGNhbGxiYWNrLCBjb250ZXh0KSB7XG4gICAgICBpZiAoIWV2ZW50c0FwaSh0aGlzLCAnb24nLCBuYW1lLCBbY2FsbGJhY2ssIGNvbnRleHRdKSB8fCAhY2FsbGJhY2spIHJldHVybiB0aGlzO1xuICAgICAgdGhpcy5fZXZlbnRzIHx8ICh0aGlzLl9ldmVudHMgPSB7fSk7XG4gICAgICB2YXIgZXZlbnRzID0gdGhpcy5fZXZlbnRzW25hbWVdIHx8ICh0aGlzLl9ldmVudHNbbmFtZV0gPSBbXSk7XG4gICAgICBldmVudHMucHVzaCh7Y2FsbGJhY2s6IGNhbGxiYWNrLCBjb250ZXh0OiBjb250ZXh0LCBjdHg6IGNvbnRleHQgfHwgdGhpc30pO1xuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIC8vIEJpbmQgYW4gZXZlbnQgdG8gb25seSBiZSB0cmlnZ2VyZWQgYSBzaW5nbGUgdGltZS4gQWZ0ZXIgdGhlIGZpcnN0IHRpbWVcbiAgICAvLyB0aGUgY2FsbGJhY2sgaXMgaW52b2tlZCwgaXQgd2lsbCBiZSByZW1vdmVkLlxuICAgIG9uY2U6IGZ1bmN0aW9uKG5hbWUsIGNhbGxiYWNrLCBjb250ZXh0KSB7XG4gICAgICBpZiAoIWV2ZW50c0FwaSh0aGlzLCAnb25jZScsIG5hbWUsIFtjYWxsYmFjaywgY29udGV4dF0pIHx8ICFjYWxsYmFjaykgcmV0dXJuIHRoaXM7XG4gICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICB2YXIgb25jZSA9IF8ub25jZShmdW5jdGlvbigpIHtcbiAgICAgICAgc2VsZi5vZmYobmFtZSwgb25jZSk7XG4gICAgICAgIGNhbGxiYWNrLmFwcGx5KHRoaXMsIGFyZ3VtZW50cyk7XG4gICAgICB9KTtcbiAgICAgIG9uY2UuX2NhbGxiYWNrID0gY2FsbGJhY2s7XG4gICAgICByZXR1cm4gdGhpcy5vbihuYW1lLCBvbmNlLCBjb250ZXh0KTtcbiAgICB9LFxuXG4gICAgLy8gUmVtb3ZlIG9uZSBvciBtYW55IGNhbGxiYWNrcy4gSWYgYGNvbnRleHRgIGlzIG51bGwsIHJlbW92ZXMgYWxsXG4gICAgLy8gY2FsbGJhY2tzIHdpdGggdGhhdCBmdW5jdGlvbi4gSWYgYGNhbGxiYWNrYCBpcyBudWxsLCByZW1vdmVzIGFsbFxuICAgIC8vIGNhbGxiYWNrcyBmb3IgdGhlIGV2ZW50LiBJZiBgbmFtZWAgaXMgbnVsbCwgcmVtb3ZlcyBhbGwgYm91bmRcbiAgICAvLyBjYWxsYmFja3MgZm9yIGFsbCBldmVudHMuXG4gICAgb2ZmOiBmdW5jdGlvbihuYW1lLCBjYWxsYmFjaywgY29udGV4dCkge1xuICAgICAgdmFyIHJldGFpbiwgZXYsIGV2ZW50cywgbmFtZXMsIGksIGwsIGosIGs7XG4gICAgICBpZiAoIXRoaXMuX2V2ZW50cyB8fCAhZXZlbnRzQXBpKHRoaXMsICdvZmYnLCBuYW1lLCBbY2FsbGJhY2ssIGNvbnRleHRdKSkgcmV0dXJuIHRoaXM7XG4gICAgICBpZiAoIW5hbWUgJiYgIWNhbGxiYWNrICYmICFjb250ZXh0KSB7XG4gICAgICAgIHRoaXMuX2V2ZW50cyA9IHt9O1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICAgIH1cblxuICAgICAgbmFtZXMgPSBuYW1lID8gW25hbWVdIDogXy5rZXlzKHRoaXMuX2V2ZW50cyk7XG4gICAgICBmb3IgKGkgPSAwLCBsID0gbmFtZXMubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgICAgIG5hbWUgPSBuYW1lc1tpXTtcbiAgICAgICAgaWYgKGV2ZW50cyA9IHRoaXMuX2V2ZW50c1tuYW1lXSkge1xuICAgICAgICAgIHRoaXMuX2V2ZW50c1tuYW1lXSA9IHJldGFpbiA9IFtdO1xuICAgICAgICAgIGlmIChjYWxsYmFjayB8fCBjb250ZXh0KSB7XG4gICAgICAgICAgICBmb3IgKGogPSAwLCBrID0gZXZlbnRzLmxlbmd0aDsgaiA8IGs7IGorKykge1xuICAgICAgICAgICAgICBldiA9IGV2ZW50c1tqXTtcbiAgICAgICAgICAgICAgaWYgKChjYWxsYmFjayAmJiBjYWxsYmFjayAhPT0gZXYuY2FsbGJhY2sgJiYgY2FsbGJhY2sgIT09IGV2LmNhbGxiYWNrLl9jYWxsYmFjaykgfHxcbiAgICAgICAgICAgICAgICAgIChjb250ZXh0ICYmIGNvbnRleHQgIT09IGV2LmNvbnRleHQpKSB7XG4gICAgICAgICAgICAgICAgcmV0YWluLnB1c2goZXYpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICAgIGlmICghcmV0YWluLmxlbmd0aCkgZGVsZXRlIHRoaXMuX2V2ZW50c1tuYW1lXTtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgLy8gVHJpZ2dlciBvbmUgb3IgbWFueSBldmVudHMsIGZpcmluZyBhbGwgYm91bmQgY2FsbGJhY2tzLiBDYWxsYmFja3MgYXJlXG4gICAgLy8gcGFzc2VkIHRoZSBzYW1lIGFyZ3VtZW50cyBhcyBgdHJpZ2dlcmAgaXMsIGFwYXJ0IGZyb20gdGhlIGV2ZW50IG5hbWVcbiAgICAvLyAodW5sZXNzIHlvdSdyZSBsaXN0ZW5pbmcgb24gYFwiYWxsXCJgLCB3aGljaCB3aWxsIGNhdXNlIHlvdXIgY2FsbGJhY2sgdG9cbiAgICAvLyByZWNlaXZlIHRoZSB0cnVlIG5hbWUgb2YgdGhlIGV2ZW50IGFzIHRoZSBmaXJzdCBhcmd1bWVudCkuXG4gICAgdHJpZ2dlcjogZnVuY3Rpb24obmFtZSkge1xuICAgICAgaWYgKCF0aGlzLl9ldmVudHMpIHJldHVybiB0aGlzO1xuICAgICAgdmFyIGFyZ3MgPSBzbGljZS5jYWxsKGFyZ3VtZW50cywgMSk7XG4gICAgICBpZiAoIWV2ZW50c0FwaSh0aGlzLCAndHJpZ2dlcicsIG5hbWUsIGFyZ3MpKSByZXR1cm4gdGhpcztcbiAgICAgIHZhciBldmVudHMgPSB0aGlzLl9ldmVudHNbbmFtZV07XG4gICAgICB2YXIgYWxsRXZlbnRzID0gdGhpcy5fZXZlbnRzLmFsbDtcbiAgICAgIGlmIChldmVudHMpIHRyaWdnZXJFdmVudHMoZXZlbnRzLCBhcmdzKTtcbiAgICAgIGlmIChhbGxFdmVudHMpIHRyaWdnZXJFdmVudHMoYWxsRXZlbnRzLCBhcmd1bWVudHMpO1xuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuICAgIC8vIFRlbGwgdGhpcyBvYmplY3QgdG8gc3RvcCBsaXN0ZW5pbmcgdG8gZWl0aGVyIHNwZWNpZmljIGV2ZW50cyAuLi4gb3JcbiAgICAvLyB0byBldmVyeSBvYmplY3QgaXQncyBjdXJyZW50bHkgbGlzdGVuaW5nIHRvLlxuICAgIHN0b3BMaXN0ZW5pbmc6IGZ1bmN0aW9uKG9iaiwgbmFtZSwgY2FsbGJhY2spIHtcbiAgICAgIHZhciBsaXN0ZW5lcnMgPSB0aGlzLl9saXN0ZW5lcnM7XG4gICAgICBpZiAoIWxpc3RlbmVycykgcmV0dXJuIHRoaXM7XG4gICAgICB2YXIgZGVsZXRlTGlzdGVuZXIgPSAhbmFtZSAmJiAhY2FsbGJhY2s7XG4gICAgICBpZiAodHlwZW9mIG5hbWUgPT09ICdvYmplY3QnKSBjYWxsYmFjayA9IHRoaXM7XG4gICAgICBpZiAob2JqKSAobGlzdGVuZXJzID0ge30pW29iai5fbGlzdGVuZXJJZF0gPSBvYmo7XG4gICAgICBmb3IgKHZhciBpZCBpbiBsaXN0ZW5lcnMpIHtcbiAgICAgICAgbGlzdGVuZXJzW2lkXS5vZmYobmFtZSwgY2FsbGJhY2ssIHRoaXMpO1xuICAgICAgICBpZiAoZGVsZXRlTGlzdGVuZXIpIGRlbGV0ZSB0aGlzLl9saXN0ZW5lcnNbaWRdO1xuICAgICAgfVxuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gIH07XG5cbiAgLy8gUmVndWxhciBleHByZXNzaW9uIHVzZWQgdG8gc3BsaXQgZXZlbnQgc3RyaW5ncy5cbiAgdmFyIGV2ZW50U3BsaXR0ZXIgPSAvXFxzKy87XG5cbiAgLy8gSW1wbGVtZW50IGZhbmN5IGZlYXR1cmVzIG9mIHRoZSBFdmVudHMgQVBJIHN1Y2ggYXMgbXVsdGlwbGUgZXZlbnRcbiAgLy8gbmFtZXMgYFwiY2hhbmdlIGJsdXJcImAgYW5kIGpRdWVyeS1zdHlsZSBldmVudCBtYXBzIGB7Y2hhbmdlOiBhY3Rpb259YFxuICAvLyBpbiB0ZXJtcyBvZiB0aGUgZXhpc3RpbmcgQVBJLlxuICB2YXIgZXZlbnRzQXBpID0gZnVuY3Rpb24ob2JqLCBhY3Rpb24sIG5hbWUsIHJlc3QpIHtcbiAgICBpZiAoIW5hbWUpIHJldHVybiB0cnVlO1xuXG4gICAgLy8gSGFuZGxlIGV2ZW50IG1hcHMuXG4gICAgaWYgKHR5cGVvZiBuYW1lID09PSAnb2JqZWN0Jykge1xuICAgICAgZm9yICh2YXIga2V5IGluIG5hbWUpIHtcbiAgICAgICAgb2JqW2FjdGlvbl0uYXBwbHkob2JqLCBba2V5LCBuYW1lW2tleV1dLmNvbmNhdChyZXN0KSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuXG4gICAgLy8gSGFuZGxlIHNwYWNlIHNlcGFyYXRlZCBldmVudCBuYW1lcy5cbiAgICBpZiAoZXZlbnRTcGxpdHRlci50ZXN0KG5hbWUpKSB7XG4gICAgICB2YXIgbmFtZXMgPSBuYW1lLnNwbGl0KGV2ZW50U3BsaXR0ZXIpO1xuICAgICAgZm9yICh2YXIgaSA9IDAsIGwgPSBuYW1lcy5sZW5ndGg7IGkgPCBsOyBpKyspIHtcbiAgICAgICAgb2JqW2FjdGlvbl0uYXBwbHkob2JqLCBbbmFtZXNbaV1dLmNvbmNhdChyZXN0KSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRydWU7XG4gIH07XG5cbiAgLy8gQSBkaWZmaWN1bHQtdG8tYmVsaWV2ZSwgYnV0IG9wdGltaXplZCBpbnRlcm5hbCBkaXNwYXRjaCBmdW5jdGlvbiBmb3JcbiAgLy8gdHJpZ2dlcmluZyBldmVudHMuIFRyaWVzIHRvIGtlZXAgdGhlIHVzdWFsIGNhc2VzIHNwZWVkeSAobW9zdCBpbnRlcm5hbFxuICAvLyBCYWNrYm9uZSBldmVudHMgaGF2ZSAzIGFyZ3VtZW50cykuXG4gIHZhciB0cmlnZ2VyRXZlbnRzID0gZnVuY3Rpb24oZXZlbnRzLCBhcmdzKSB7XG4gICAgdmFyIGV2LCBpID0gLTEsIGwgPSBldmVudHMubGVuZ3RoLCBhMSA9IGFyZ3NbMF0sIGEyID0gYXJnc1sxXSwgYTMgPSBhcmdzWzJdO1xuICAgIHN3aXRjaCAoYXJncy5sZW5ndGgpIHtcbiAgICAgIGNhc2UgMDogd2hpbGUgKCsraSA8IGwpIChldiA9IGV2ZW50c1tpXSkuY2FsbGJhY2suY2FsbChldi5jdHgpOyByZXR1cm47XG4gICAgICBjYXNlIDE6IHdoaWxlICgrK2kgPCBsKSAoZXYgPSBldmVudHNbaV0pLmNhbGxiYWNrLmNhbGwoZXYuY3R4LCBhMSk7IHJldHVybjtcbiAgICAgIGNhc2UgMjogd2hpbGUgKCsraSA8IGwpIChldiA9IGV2ZW50c1tpXSkuY2FsbGJhY2suY2FsbChldi5jdHgsIGExLCBhMik7IHJldHVybjtcbiAgICAgIGNhc2UgMzogd2hpbGUgKCsraSA8IGwpIChldiA9IGV2ZW50c1tpXSkuY2FsbGJhY2suY2FsbChldi5jdHgsIGExLCBhMiwgYTMpOyByZXR1cm47XG4gICAgICBkZWZhdWx0OiB3aGlsZSAoKytpIDwgbCkgKGV2ID0gZXZlbnRzW2ldKS5jYWxsYmFjay5hcHBseShldi5jdHgsIGFyZ3MpO1xuICAgIH1cbiAgfTtcblxuICB2YXIgbGlzdGVuTWV0aG9kcyA9IHtsaXN0ZW5UbzogJ29uJywgbGlzdGVuVG9PbmNlOiAnb25jZSd9O1xuXG4gIC8vIEludmVyc2lvbi1vZi1jb250cm9sIHZlcnNpb25zIG9mIGBvbmAgYW5kIGBvbmNlYC4gVGVsbCAqdGhpcyogb2JqZWN0IHRvXG4gIC8vIGxpc3RlbiB0byBhbiBldmVudCBpbiBhbm90aGVyIG9iamVjdCAuLi4ga2VlcGluZyB0cmFjayBvZiB3aGF0IGl0J3NcbiAgLy8gbGlzdGVuaW5nIHRvLlxuICBfLmVhY2gobGlzdGVuTWV0aG9kcywgZnVuY3Rpb24oaW1wbGVtZW50YXRpb24sIG1ldGhvZCkge1xuICAgIEV2ZW50c1ttZXRob2RdID0gZnVuY3Rpb24ob2JqLCBuYW1lLCBjYWxsYmFjaykge1xuICAgICAgdmFyIGxpc3RlbmVycyA9IHRoaXMuX2xpc3RlbmVycyB8fCAodGhpcy5fbGlzdGVuZXJzID0ge30pO1xuICAgICAgdmFyIGlkID0gb2JqLl9saXN0ZW5lcklkIHx8IChvYmouX2xpc3RlbmVySWQgPSBfLnVuaXF1ZUlkKCdsJykpO1xuICAgICAgbGlzdGVuZXJzW2lkXSA9IG9iajtcbiAgICAgIGlmICh0eXBlb2YgbmFtZSA9PT0gJ29iamVjdCcpIGNhbGxiYWNrID0gdGhpcztcbiAgICAgIG9ialtpbXBsZW1lbnRhdGlvbl0obmFtZSwgY2FsbGJhY2ssIHRoaXMpO1xuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcbiAgfSk7XG5cbiAgLy8gQWxpYXNlcyBmb3IgYmFja3dhcmRzIGNvbXBhdGliaWxpdHkuXG4gIEV2ZW50cy5iaW5kICAgPSBFdmVudHMub247XG4gIEV2ZW50cy51bmJpbmQgPSBFdmVudHMub2ZmO1xuXG4gIC8vIE1peGluIHV0aWxpdHlcbiAgRXZlbnRzLm1peGluID0gZnVuY3Rpb24ocHJvdG8pIHtcbiAgICB2YXIgZXhwb3J0cyA9IFsnb24nLCAnb25jZScsICdvZmYnLCAndHJpZ2dlcicsICdzdG9wTGlzdGVuaW5nJywgJ2xpc3RlblRvJyxcbiAgICAgICAgICAgICAgICAgICAnbGlzdGVuVG9PbmNlJywgJ2JpbmQnLCAndW5iaW5kJ107XG4gICAgXy5lYWNoKGV4cG9ydHMsIGZ1bmN0aW9uKG5hbWUpIHtcbiAgICAgIHByb3RvW25hbWVdID0gdGhpc1tuYW1lXTtcbiAgICB9LCB0aGlzKTtcbiAgICByZXR1cm4gcHJvdG87XG4gIH07XG5cbiAgLy8gRXhwb3J0IEV2ZW50cyBhcyBCYWNrYm9uZUV2ZW50cyBkZXBlbmRpbmcgb24gY3VycmVudCBjb250ZXh0XG4gIGlmICh0eXBlb2YgZXhwb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICBpZiAodHlwZW9mIG1vZHVsZSAhPT0gJ3VuZGVmaW5lZCcgJiYgbW9kdWxlLmV4cG9ydHMpIHtcbiAgICAgIGV4cG9ydHMgPSBtb2R1bGUuZXhwb3J0cyA9IEV2ZW50cztcbiAgICB9XG4gICAgZXhwb3J0cy5CYWNrYm9uZUV2ZW50cyA9IEV2ZW50cztcbiAgfWVsc2UgaWYgKHR5cGVvZiBkZWZpbmUgPT09IFwiZnVuY3Rpb25cIiAgJiYgdHlwZW9mIGRlZmluZS5hbWQgPT0gXCJvYmplY3RcIikge1xuICAgIGRlZmluZShmdW5jdGlvbigpIHtcbiAgICAgIHJldHVybiBFdmVudHM7XG4gICAgfSk7XG4gIH0gZWxzZSB7XG4gICAgcm9vdC5CYWNrYm9uZUV2ZW50cyA9IEV2ZW50cztcbiAgfVxufSkodGhpcyk7XG4iLCJtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoJy4vYmFja2JvbmUtZXZlbnRzLXN0YW5kYWxvbmUnKTtcbiIsIm1vZHVsZS5leHBvcnRzID0gcmVxdWlyZShcIi4vc3JjL2FwaS5qc1wiKTtcbiIsInZhciBhcGkgPSBmdW5jdGlvbiAod2hvKSB7XG5cbiAgICB2YXIgX21ldGhvZHMgPSBmdW5jdGlvbiAoKSB7XG5cdHZhciBtID0gW107XG5cblx0bS5hZGRfYmF0Y2ggPSBmdW5jdGlvbiAob2JqKSB7XG5cdCAgICBtLnVuc2hpZnQob2JqKTtcblx0fTtcblxuXHRtLnVwZGF0ZSA9IGZ1bmN0aW9uIChtZXRob2QsIHZhbHVlKSB7XG5cdCAgICBmb3IgKHZhciBpPTA7IGk8bS5sZW5ndGg7IGkrKykge1xuXHRcdGZvciAodmFyIHAgaW4gbVtpXSkge1xuXHRcdCAgICBpZiAocCA9PT0gbWV0aG9kKSB7XG5cdFx0XHRtW2ldW3BdID0gdmFsdWU7XG5cdFx0XHRyZXR1cm4gdHJ1ZTtcblx0XHQgICAgfVxuXHRcdH1cblx0ICAgIH1cblx0ICAgIHJldHVybiBmYWxzZTtcblx0fTtcblxuXHRtLmFkZCA9IGZ1bmN0aW9uIChtZXRob2QsIHZhbHVlKSB7XG5cdCAgICBpZiAobS51cGRhdGUgKG1ldGhvZCwgdmFsdWUpICkge1xuXHQgICAgfSBlbHNlIHtcblx0XHR2YXIgcmVnID0ge307XG5cdFx0cmVnW21ldGhvZF0gPSB2YWx1ZTtcblx0XHRtLmFkZF9iYXRjaCAocmVnKTtcblx0ICAgIH1cblx0fTtcblxuXHRtLmdldCA9IGZ1bmN0aW9uIChtZXRob2QpIHtcblx0ICAgIGZvciAodmFyIGk9MDsgaTxtLmxlbmd0aDsgaSsrKSB7XG5cdFx0Zm9yICh2YXIgcCBpbiBtW2ldKSB7XG5cdFx0ICAgIGlmIChwID09PSBtZXRob2QpIHtcblx0XHRcdHJldHVybiBtW2ldW3BdO1xuXHRcdCAgICB9XG5cdFx0fVxuXHQgICAgfVxuXHR9O1xuXG5cdHJldHVybiBtO1xuICAgIH07XG5cbiAgICB2YXIgbWV0aG9kcyAgICA9IF9tZXRob2RzKCk7XG4gICAgdmFyIGFwaSA9IGZ1bmN0aW9uICgpIHt9O1xuXG4gICAgYXBpLmNoZWNrID0gZnVuY3Rpb24gKG1ldGhvZCwgY2hlY2ssIG1zZykge1xuXHRpZiAobWV0aG9kIGluc3RhbmNlb2YgQXJyYXkpIHtcblx0ICAgIGZvciAodmFyIGk9MDsgaTxtZXRob2QubGVuZ3RoOyBpKyspIHtcblx0XHRhcGkuY2hlY2sobWV0aG9kW2ldLCBjaGVjaywgbXNnKTtcblx0ICAgIH1cblx0ICAgIHJldHVybjtcblx0fVxuXG5cdGlmICh0eXBlb2YgKG1ldGhvZCkgPT09ICdmdW5jdGlvbicpIHtcblx0ICAgIG1ldGhvZC5jaGVjayhjaGVjaywgbXNnKTtcblx0fSBlbHNlIHtcblx0ICAgIHdob1ttZXRob2RdLmNoZWNrKGNoZWNrLCBtc2cpO1xuXHR9XG5cdHJldHVybiBhcGk7XG4gICAgfTtcblxuICAgIGFwaS50cmFuc2Zvcm0gPSBmdW5jdGlvbiAobWV0aG9kLCBjYmFrKSB7XG5cdGlmIChtZXRob2QgaW5zdGFuY2VvZiBBcnJheSkge1xuXHQgICAgZm9yICh2YXIgaT0wOyBpPG1ldGhvZC5sZW5ndGg7IGkrKykge1xuXHRcdGFwaS50cmFuc2Zvcm0gKG1ldGhvZFtpXSwgY2Jhayk7XG5cdCAgICB9XG5cdCAgICByZXR1cm47XG5cdH1cblxuXHRpZiAodHlwZW9mIChtZXRob2QpID09PSAnZnVuY3Rpb24nKSB7XG5cdCAgICBtZXRob2QudHJhbnNmb3JtIChjYmFrKTtcblx0fSBlbHNlIHtcblx0ICAgIHdob1ttZXRob2RdLnRyYW5zZm9ybShjYmFrKTtcblx0fVxuXHRyZXR1cm4gYXBpO1xuICAgIH07XG5cbiAgICB2YXIgYXR0YWNoX21ldGhvZCA9IGZ1bmN0aW9uIChtZXRob2QsIG9wdHMpIHtcblx0dmFyIGNoZWNrcyA9IFtdO1xuXHR2YXIgdHJhbnNmb3JtcyA9IFtdO1xuXG5cdHZhciBnZXR0ZXIgPSBvcHRzLm9uX2dldHRlciB8fCBmdW5jdGlvbiAoKSB7XG5cdCAgICByZXR1cm4gbWV0aG9kcy5nZXQobWV0aG9kKTtcblx0fTtcblxuXHR2YXIgc2V0dGVyID0gb3B0cy5vbl9zZXR0ZXIgfHwgZnVuY3Rpb24gKHgpIHtcblx0ICAgIGZvciAodmFyIGk9MDsgaTx0cmFuc2Zvcm1zLmxlbmd0aDsgaSsrKSB7XG5cdFx0eCA9IHRyYW5zZm9ybXNbaV0oeCk7XG5cdCAgICB9XG5cblx0ICAgIGZvciAodmFyIGo9MDsgajxjaGVja3MubGVuZ3RoOyBqKyspIHtcblx0XHRpZiAoIWNoZWNrc1tqXS5jaGVjayh4KSkge1xuXHRcdCAgICB2YXIgbXNnID0gY2hlY2tzW2pdLm1zZyB8fCBcblx0XHRcdChcIlZhbHVlIFwiICsgeCArIFwiIGRvZXNuJ3Qgc2VlbSB0byBiZSB2YWxpZCBmb3IgdGhpcyBtZXRob2RcIik7XG5cdFx0ICAgIHRocm93IChtc2cpO1xuXHRcdH1cblx0ICAgIH1cblx0ICAgIG1ldGhvZHMuYWRkKG1ldGhvZCwgeCk7XG5cdH07XG5cblx0dmFyIG5ld19tZXRob2QgPSBmdW5jdGlvbiAobmV3X3ZhbCkge1xuXHQgICAgaWYgKCFhcmd1bWVudHMubGVuZ3RoKSB7XG5cdFx0cmV0dXJuIGdldHRlcigpO1xuXHQgICAgfVxuXHQgICAgc2V0dGVyKG5ld192YWwpO1xuXHQgICAgcmV0dXJuIHdobzsgLy8gUmV0dXJuIHRoaXM/XG5cdH07XG5cdG5ld19tZXRob2QuY2hlY2sgPSBmdW5jdGlvbiAoY2JhaywgbXNnKSB7XG5cdCAgICBpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0XHRyZXR1cm4gY2hlY2tzO1xuXHQgICAgfVxuXHQgICAgY2hlY2tzLnB1c2ggKHtjaGVjayA6IGNiYWssXG5cdFx0XHQgIG1zZyAgIDogbXNnfSk7XG5cdCAgICByZXR1cm4gdGhpcztcblx0fTtcblx0bmV3X21ldGhvZC50cmFuc2Zvcm0gPSBmdW5jdGlvbiAoY2Jhaykge1xuXHQgICAgaWYgKCFhcmd1bWVudHMubGVuZ3RoKSB7XG5cdFx0cmV0dXJuIHRyYW5zZm9ybXM7XG5cdCAgICB9XG5cdCAgICB0cmFuc2Zvcm1zLnB1c2goY2Jhayk7XG5cdCAgICByZXR1cm4gdGhpcztcblx0fTtcblxuXHR3aG9bbWV0aG9kXSA9IG5ld19tZXRob2Q7XG4gICAgfTtcblxuICAgIHZhciBnZXRzZXQgPSBmdW5jdGlvbiAocGFyYW0sIG9wdHMpIHtcblx0aWYgKHR5cGVvZiAocGFyYW0pID09PSAnb2JqZWN0Jykge1xuXHQgICAgbWV0aG9kcy5hZGRfYmF0Y2ggKHBhcmFtKTtcblx0ICAgIGZvciAodmFyIHAgaW4gcGFyYW0pIHtcblx0XHRhdHRhY2hfbWV0aG9kIChwLCBvcHRzKTtcblx0ICAgIH1cblx0fSBlbHNlIHtcblx0ICAgIG1ldGhvZHMuYWRkIChwYXJhbSwgb3B0cy5kZWZhdWx0X3ZhbHVlKTtcblx0ICAgIGF0dGFjaF9tZXRob2QgKHBhcmFtLCBvcHRzKTtcblx0fVxuICAgIH07XG5cbiAgICBhcGkuZ2V0c2V0ID0gZnVuY3Rpb24gKHBhcmFtLCBkZWYpIHtcblx0Z2V0c2V0KHBhcmFtLCB7ZGVmYXVsdF92YWx1ZSA6IGRlZn0pO1xuXG5cdHJldHVybiBhcGk7XG4gICAgfTtcblxuICAgIGFwaS5nZXQgPSBmdW5jdGlvbiAocGFyYW0sIGRlZikge1xuXHR2YXIgb25fc2V0dGVyID0gZnVuY3Rpb24gKCkge1xuXHQgICAgdGhyb3cgKFwiTWV0aG9kIGRlZmluZWQgb25seSBhcyBhIGdldHRlciAoeW91IGFyZSB0cnlpbmcgdG8gdXNlIGl0IGFzIGEgc2V0dGVyXCIpO1xuXHR9O1xuXG5cdGdldHNldChwYXJhbSwge2RlZmF1bHRfdmFsdWUgOiBkZWYsXG5cdFx0ICAgICAgIG9uX3NldHRlciA6IG9uX3NldHRlcn1cblx0ICAgICAgKTtcblxuXHRyZXR1cm4gYXBpO1xuICAgIH07XG5cbiAgICBhcGkuc2V0ID0gZnVuY3Rpb24gKHBhcmFtLCBkZWYpIHtcblx0dmFyIG9uX2dldHRlciA9IGZ1bmN0aW9uICgpIHtcblx0ICAgIHRocm93IChcIk1ldGhvZCBkZWZpbmVkIG9ubHkgYXMgYSBzZXR0ZXIgKHlvdSBhcmUgdHJ5aW5nIHRvIHVzZSBpdCBhcyBhIGdldHRlclwiKTtcblx0fTtcblxuXHRnZXRzZXQocGFyYW0sIHtkZWZhdWx0X3ZhbHVlIDogZGVmLFxuXHRcdCAgICAgICBvbl9nZXR0ZXIgOiBvbl9nZXR0ZXJ9XG5cdCAgICAgICk7XG5cblx0cmV0dXJuIGFwaTtcbiAgICB9O1xuXG4gICAgYXBpLm1ldGhvZCA9IGZ1bmN0aW9uIChuYW1lLCBjYmFrKSB7XG5cdGlmICh0eXBlb2YgKG5hbWUpID09PSAnb2JqZWN0Jykge1xuXHQgICAgZm9yICh2YXIgcCBpbiBuYW1lKSB7XG5cdFx0d2hvW3BdID0gbmFtZVtwXTtcblx0ICAgIH1cblx0fSBlbHNlIHtcblx0ICAgIHdob1tuYW1lXSA9IGNiYWs7XG5cdH1cblx0cmV0dXJuIGFwaTtcbiAgICB9O1xuXG4gICAgcmV0dXJuIGFwaTtcbiAgICBcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gZXhwb3J0cyA9IGFwaTsiLCJtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoXCIuL3NyYy9uZXdpY2suanNcIik7XG4iLCIvKipcbiAqIE5ld2ljayBhbmQgbmh4IGZvcm1hdHMgcGFyc2VyIGluIEphdmFTY3JpcHQuXG4gKlxuICogQ29weXJpZ2h0IChjKSBKYXNvbiBEYXZpZXMgMjAxMCBhbmQgTWlndWVsIFBpZ25hdGVsbGlcbiAqXG4gKiBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYSBjb3B5XG4gKiBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSBcIlNvZnR3YXJlXCIpLCB0byBkZWFsXG4gKiBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzXG4gKiB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsXG4gKiBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0IHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXNcbiAqIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4gKlxuICogVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWQgaW5cbiAqIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuICpcbiAqIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1MgT1JcbiAqIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLFxuICogRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU4gTk8gRVZFTlQgU0hBTEwgVEhFXG4gKiBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLCBEQU1BR0VTIE9SIE9USEVSXG4gKiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLFxuICogT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFIFVTRSBPUiBPVEhFUiBERUFMSU5HUyBJTlxuICogVEhFIFNPRlRXQVJFLlxuICpcbiAqIEV4YW1wbGUgdHJlZSAoZnJvbSBodHRwOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL05ld2lja19mb3JtYXQpOlxuICpcbiAqICstLTAuMS0tQVxuICogRi0tLS0tMC4yLS0tLS1CICAgICAgICAgICAgKy0tLS0tLS0wLjMtLS0tQ1xuICogKy0tLS0tLS0tLS0tLS0tLS0tLTAuNS0tLS0tRVxuICogICAgICAgICAgICAgICAgICAgICAgICAgICAgKy0tLS0tLS0tLTAuNC0tLS0tLURcbiAqXG4gKiBOZXdpY2sgZm9ybWF0OlxuICogKEE6MC4xLEI6MC4yLChDOjAuMyxEOjAuNClFOjAuNSlGO1xuICpcbiAqIENvbnZlcnRlZCB0byBKU09OOlxuICoge1xuICogICBuYW1lOiBcIkZcIixcbiAqICAgYnJhbmNoc2V0OiBbXG4gKiAgICAge25hbWU6IFwiQVwiLCBsZW5ndGg6IDAuMX0sXG4gKiAgICAge25hbWU6IFwiQlwiLCBsZW5ndGg6IDAuMn0sXG4gKiAgICAge1xuICogICAgICAgbmFtZTogXCJFXCIsXG4gKiAgICAgICBsZW5ndGg6IDAuNSxcbiAqICAgICAgIGJyYW5jaHNldDogW1xuICogICAgICAgICB7bmFtZTogXCJDXCIsIGxlbmd0aDogMC4zfSxcbiAqICAgICAgICAge25hbWU6IFwiRFwiLCBsZW5ndGg6IDAuNH1cbiAqICAgICAgIF1cbiAqICAgICB9XG4gKiAgIF1cbiAqIH1cbiAqXG4gKiBDb252ZXJ0ZWQgdG8gSlNPTiwgYnV0IHdpdGggbm8gbmFtZXMgb3IgbGVuZ3RoczpcbiAqIHtcbiAqICAgYnJhbmNoc2V0OiBbXG4gKiAgICAge30sIHt9LCB7XG4gKiAgICAgICBicmFuY2hzZXQ6IFt7fSwge31dXG4gKiAgICAgfVxuICogICBdXG4gKiB9XG4gKi9cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgcGFyc2VfbmV3aWNrIDogZnVuY3Rpb24ocykge1xuXHR2YXIgYW5jZXN0b3JzID0gW107XG5cdHZhciB0cmVlID0ge307XG5cdHZhciB0b2tlbnMgPSBzLnNwbGl0KC9cXHMqKDt8XFwofFxcKXwsfDopXFxzKi8pO1xuXHR2YXIgc3VidHJlZTtcblx0Zm9yICh2YXIgaT0wOyBpPHRva2Vucy5sZW5ndGg7IGkrKykge1xuXHQgICAgdmFyIHRva2VuID0gdG9rZW5zW2ldO1xuXHQgICAgc3dpdGNoICh0b2tlbikge1xuICAgICAgICAgICAgY2FzZSAnKCc6IC8vIG5ldyBicmFuY2hzZXRcblx0XHRzdWJ0cmVlID0ge307XG5cdFx0dHJlZS5jaGlsZHJlbiA9IFtzdWJ0cmVlXTtcblx0XHRhbmNlc3RvcnMucHVzaCh0cmVlKTtcblx0XHR0cmVlID0gc3VidHJlZTtcblx0XHRicmVhaztcbiAgICAgICAgICAgIGNhc2UgJywnOiAvLyBhbm90aGVyIGJyYW5jaFxuXHRcdHN1YnRyZWUgPSB7fTtcblx0XHRhbmNlc3RvcnNbYW5jZXN0b3JzLmxlbmd0aC0xXS5jaGlsZHJlbi5wdXNoKHN1YnRyZWUpO1xuXHRcdHRyZWUgPSBzdWJ0cmVlO1xuXHRcdGJyZWFrO1xuICAgICAgICAgICAgY2FzZSAnKSc6IC8vIG9wdGlvbmFsIG5hbWUgbmV4dFxuXHRcdHRyZWUgPSBhbmNlc3RvcnMucG9wKCk7XG5cdFx0YnJlYWs7XG4gICAgICAgICAgICBjYXNlICc6JzogLy8gb3B0aW9uYWwgbGVuZ3RoIG5leHRcblx0XHRicmVhaztcbiAgICAgICAgICAgIGRlZmF1bHQ6XG5cdFx0dmFyIHggPSB0b2tlbnNbaS0xXTtcblx0XHRpZiAoeCA9PSAnKScgfHwgeCA9PSAnKCcgfHwgeCA9PSAnLCcpIHtcblx0XHQgICAgdHJlZS5uYW1lID0gdG9rZW47XG5cdFx0fSBlbHNlIGlmICh4ID09ICc6Jykge1xuXHRcdCAgICB0cmVlLmJyYW5jaF9sZW5ndGggPSBwYXJzZUZsb2F0KHRva2VuKTtcblx0XHR9XG5cdCAgICB9XG5cdH1cblx0cmV0dXJuIHRyZWU7XG4gICAgfSxcblxuICAgIHBhcnNlX25oeCA6IGZ1bmN0aW9uIChzKSB7XG5cdHZhciBhbmNlc3RvcnMgPSBbXTtcblx0dmFyIHRyZWUgPSB7fTtcblx0dmFyIHN1YnRyZWU7XG5cblx0dmFyIHRva2VucyA9IHMuc3BsaXQoIC9cXHMqKDt8XFwofFxcKXxcXFt8XFxdfCx8Onw9KVxccyovICk7XG5cdGZvciAodmFyIGk9MDsgaTx0b2tlbnMubGVuZ3RoOyBpKyspIHtcblx0ICAgIHZhciB0b2tlbiA9IHRva2Vuc1tpXTtcblx0ICAgIHN3aXRjaCAodG9rZW4pIHtcbiAgICAgICAgICAgIGNhc2UgJygnOiAvLyBuZXcgY2hpbGRyZW5cblx0XHRzdWJ0cmVlID0ge307XG5cdFx0dHJlZS5jaGlsZHJlbiA9IFtzdWJ0cmVlXTtcblx0XHRhbmNlc3RvcnMucHVzaCh0cmVlKTtcblx0XHR0cmVlID0gc3VidHJlZTtcblx0XHRicmVhaztcbiAgICAgICAgICAgIGNhc2UgJywnOiAvLyBhbm90aGVyIGJyYW5jaFxuXHRcdHN1YnRyZWUgPSB7fTtcblx0XHRhbmNlc3RvcnNbYW5jZXN0b3JzLmxlbmd0aC0xXS5jaGlsZHJlbi5wdXNoKHN1YnRyZWUpO1xuXHRcdHRyZWUgPSBzdWJ0cmVlO1xuXHRcdGJyZWFrO1xuICAgICAgICAgICAgY2FzZSAnKSc6IC8vIG9wdGlvbmFsIG5hbWUgbmV4dFxuXHRcdHRyZWUgPSBhbmNlc3RvcnMucG9wKCk7XG5cdFx0YnJlYWs7XG4gICAgICAgICAgICBjYXNlICc6JzogLy8gb3B0aW9uYWwgbGVuZ3RoIG5leHRcblx0XHRicmVhaztcbiAgICAgICAgICAgIGRlZmF1bHQ6XG5cdFx0dmFyIHggPSB0b2tlbnNbaS0xXTtcblx0XHRpZiAoeCA9PSAnKScgfHwgeCA9PSAnKCcgfHwgeCA9PSAnLCcpIHtcblx0XHQgICAgdHJlZS5uYW1lID0gdG9rZW47XG5cdFx0fVxuXHRcdGVsc2UgaWYgKHggPT0gJzonKSB7XG5cdFx0ICAgIHZhciB0ZXN0X3R5cGUgPSB0eXBlb2YgdG9rZW47XG5cdFx0ICAgIGlmKCFpc05hTih0b2tlbikpe1xuXHRcdFx0dHJlZS5icmFuY2hfbGVuZ3RoID0gcGFyc2VGbG9hdCh0b2tlbik7XG5cdFx0ICAgIH1cblx0XHR9XG5cdFx0ZWxzZSBpZiAoeCA9PSAnPScpe1xuXHRcdCAgICB2YXIgeDIgPSB0b2tlbnNbaS0yXTtcblx0XHQgICAgc3dpdGNoKHgyKXtcblx0XHQgICAgY2FzZSAnRCc6XG5cdFx0XHR0cmVlLmR1cGxpY2F0aW9uID0gdG9rZW47XG5cdFx0XHRicmVhaztcblx0XHQgICAgY2FzZSAnRyc6XG5cdFx0XHR0cmVlLmdlbmVfaWQgPSB0b2tlbjtcblx0XHRcdGJyZWFrO1xuXHRcdCAgICBjYXNlICdUJzpcblx0XHRcdHRyZWUudGF4b25faWQgPSB0b2tlbjtcblx0XHRcdGJyZWFrO1xuXHRcdCAgICBkZWZhdWx0IDpcblx0XHRcdHRyZWVbdG9rZW5zW2ktMl1dID0gdG9rZW47XG5cdFx0ICAgIH1cblx0XHR9XG5cdFx0ZWxzZSB7XG5cdFx0ICAgIHZhciB0ZXN0O1xuXG5cdFx0fVxuXHQgICAgfVxuXHR9XG5cdHJldHVybiB0cmVlO1xuICAgIH1cbn07XG4iLCJ2YXIgbm9kZSA9IHJlcXVpcmUoXCIuL3NyYy9ub2RlLmpzXCIpO1xubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gbm9kZTtcbiIsIm1vZHVsZS5leHBvcnRzID0gcmVxdWlyZShcIi4vc3JjL2luZGV4LmpzXCIpO1xuIiwiLy8gcmVxdWlyZSgnZnMnKS5yZWFkZGlyU3luYyhfX2Rpcm5hbWUgKyAnLycpLmZvckVhY2goZnVuY3Rpb24oZmlsZSkge1xuLy8gICAgIGlmIChmaWxlLm1hdGNoKC8uK1xcLmpzL2cpICE9PSBudWxsICYmIGZpbGUgIT09IF9fZmlsZW5hbWUpIHtcbi8vIFx0dmFyIG5hbWUgPSBmaWxlLnJlcGxhY2UoJy5qcycsICcnKTtcbi8vIFx0bW9kdWxlLmV4cG9ydHNbbmFtZV0gPSByZXF1aXJlKCcuLycgKyBmaWxlKTtcbi8vICAgICB9XG4vLyB9KTtcblxuLy8gU2FtZSBhc1xudmFyIHV0aWxzID0gcmVxdWlyZShcIi4vdXRpbHMuanNcIik7XG51dGlscy5yZWR1Y2UgPSByZXF1aXJlKFwiLi9yZWR1Y2UuanNcIik7XG5tb2R1bGUuZXhwb3J0cyA9IGV4cG9ydHMgPSB1dGlscztcbiIsInZhciByZWR1Y2UgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIHNtb290aCA9IDU7XG4gICAgdmFyIHZhbHVlID0gJ3ZhbCc7XG4gICAgdmFyIHJlZHVuZGFudCA9IGZ1bmN0aW9uIChhLCBiKSB7XG5cdGlmIChhIDwgYikge1xuXHQgICAgcmV0dXJuICgoYi1hKSA8PSAoYiAqIDAuMikpO1xuXHR9XG5cdHJldHVybiAoKGEtYikgPD0gKGEgKiAwLjIpKTtcbiAgICB9O1xuICAgIHZhciBwZXJmb3JtX3JlZHVjZSA9IGZ1bmN0aW9uIChhcnIpIHtyZXR1cm4gYXJyO307XG5cbiAgICB2YXIgcmVkdWNlID0gZnVuY3Rpb24gKGFycikge1xuXHRpZiAoIWFyci5sZW5ndGgpIHtcblx0ICAgIHJldHVybiBhcnI7XG5cdH1cblx0dmFyIHNtb290aGVkID0gcGVyZm9ybV9zbW9vdGgoYXJyKTtcblx0dmFyIHJlZHVjZWQgID0gcGVyZm9ybV9yZWR1Y2Uoc21vb3RoZWQpO1xuXHRyZXR1cm4gcmVkdWNlZDtcbiAgICB9O1xuXG4gICAgdmFyIG1lZGlhbiA9IGZ1bmN0aW9uICh2LCBhcnIpIHtcblx0YXJyLnNvcnQoZnVuY3Rpb24gKGEsIGIpIHtcblx0ICAgIHJldHVybiBhW3ZhbHVlXSAtIGJbdmFsdWVdO1xuXHR9KTtcblx0aWYgKGFyci5sZW5ndGggJSAyKSB7XG5cdCAgICB2W3ZhbHVlXSA9IGFyclt+fihhcnIubGVuZ3RoIC8gMildW3ZhbHVlXTtcdCAgICBcblx0fSBlbHNlIHtcblx0ICAgIHZhciBuID0gfn4oYXJyLmxlbmd0aCAvIDIpIC0gMTtcblx0ICAgIHZbdmFsdWVdID0gKGFycltuXVt2YWx1ZV0gKyBhcnJbbisxXVt2YWx1ZV0pIC8gMjtcblx0fVxuXG5cdHJldHVybiB2O1xuICAgIH07XG5cbiAgICB2YXIgY2xvbmUgPSBmdW5jdGlvbiAoc291cmNlKSB7XG5cdHZhciB0YXJnZXQgPSB7fTtcblx0Zm9yICh2YXIgcHJvcCBpbiBzb3VyY2UpIHtcblx0ICAgIGlmIChzb3VyY2UuaGFzT3duUHJvcGVydHkocHJvcCkpIHtcblx0XHR0YXJnZXRbcHJvcF0gPSBzb3VyY2VbcHJvcF07XG5cdCAgICB9XG5cdH1cblx0cmV0dXJuIHRhcmdldDtcbiAgICB9O1xuXG4gICAgdmFyIHBlcmZvcm1fc21vb3RoID0gZnVuY3Rpb24gKGFycikge1xuXHRpZiAoc21vb3RoID09PSAwKSB7IC8vIG5vIHNtb290aFxuXHQgICAgcmV0dXJuIGFycjtcblx0fVxuXHR2YXIgc21vb3RoX2FyciA9IFtdO1xuXHRmb3IgKHZhciBpPTA7IGk8YXJyLmxlbmd0aDsgaSsrKSB7XG5cdCAgICB2YXIgbG93ID0gKGkgPCBzbW9vdGgpID8gMCA6IChpIC0gc21vb3RoKTtcblx0ICAgIHZhciBoaWdoID0gKGkgPiAoYXJyLmxlbmd0aCAtIHNtb290aCkpID8gYXJyLmxlbmd0aCA6IChpICsgc21vb3RoKTtcblx0ICAgIHNtb290aF9hcnJbaV0gPSBtZWRpYW4oY2xvbmUoYXJyW2ldKSwgYXJyLnNsaWNlKGxvdyxoaWdoKzEpKTtcblx0fVxuXHRyZXR1cm4gc21vb3RoX2FycjtcbiAgICB9O1xuXG4gICAgcmVkdWNlLnJlZHVjZXIgPSBmdW5jdGlvbiAoY2Jhaykge1xuXHRpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0ICAgIHJldHVybiBwZXJmb3JtX3JlZHVjZTtcblx0fVxuXHRwZXJmb3JtX3JlZHVjZSA9IGNiYWs7XG5cdHJldHVybiByZWR1Y2U7XG4gICAgfTtcblxuICAgIHJlZHVjZS5yZWR1bmRhbnQgPSBmdW5jdGlvbiAoY2Jhaykge1xuXHRpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0ICAgIHJldHVybiByZWR1bmRhbnQ7XG5cdH1cblx0cmVkdW5kYW50ID0gY2Jhaztcblx0cmV0dXJuIHJlZHVjZTtcbiAgICB9O1xuXG4gICAgcmVkdWNlLnZhbHVlID0gZnVuY3Rpb24gKHZhbCkge1xuXHRpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0ICAgIHJldHVybiB2YWx1ZTtcblx0fVxuXHR2YWx1ZSA9IHZhbDtcblx0cmV0dXJuIHJlZHVjZTtcbiAgICB9O1xuXG4gICAgcmVkdWNlLnNtb290aCA9IGZ1bmN0aW9uICh2YWwpIHtcblx0aWYgKCFhcmd1bWVudHMubGVuZ3RoKSB7XG5cdCAgICByZXR1cm4gc21vb3RoO1xuXHR9XG5cdHNtb290aCA9IHZhbDtcblx0cmV0dXJuIHJlZHVjZTtcbiAgICB9O1xuXG4gICAgcmV0dXJuIHJlZHVjZTtcbn07XG5cbnZhciBibG9jayA9IGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgcmVkID0gcmVkdWNlKClcblx0LnZhbHVlKCdzdGFydCcpO1xuXG4gICAgdmFyIHZhbHVlMiA9ICdlbmQnO1xuXG4gICAgdmFyIGpvaW4gPSBmdW5jdGlvbiAob2JqMSwgb2JqMikge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgJ29iamVjdCcgOiB7XG4gICAgICAgICAgICAgICAgJ3N0YXJ0JyA6IG9iajEub2JqZWN0W3JlZC52YWx1ZSgpXSxcbiAgICAgICAgICAgICAgICAnZW5kJyAgIDogb2JqMlt2YWx1ZTJdXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgJ3ZhbHVlJyAgOiBvYmoyW3ZhbHVlMl1cbiAgICAgICAgfTtcbiAgICB9O1xuXG4gICAgLy8gdmFyIGpvaW4gPSBmdW5jdGlvbiAob2JqMSwgb2JqMikgeyByZXR1cm4gb2JqMSB9O1xuXG4gICAgcmVkLnJlZHVjZXIoIGZ1bmN0aW9uIChhcnIpIHtcblx0dmFyIHZhbHVlID0gcmVkLnZhbHVlKCk7XG5cdHZhciByZWR1bmRhbnQgPSByZWQucmVkdW5kYW50KCk7XG5cdHZhciByZWR1Y2VkX2FyciA9IFtdO1xuXHR2YXIgY3VyciA9IHtcblx0ICAgICdvYmplY3QnIDogYXJyWzBdLFxuXHQgICAgJ3ZhbHVlJyAgOiBhcnJbMF1bdmFsdWUyXVxuXHR9O1xuXHRmb3IgKHZhciBpPTE7IGk8YXJyLmxlbmd0aDsgaSsrKSB7XG5cdCAgICBpZiAocmVkdW5kYW50IChhcnJbaV1bdmFsdWVdLCBjdXJyLnZhbHVlKSkge1xuXHRcdGN1cnIgPSBqb2luKGN1cnIsIGFycltpXSk7XG5cdFx0Y29udGludWU7XG5cdCAgICB9XG5cdCAgICByZWR1Y2VkX2Fyci5wdXNoIChjdXJyLm9iamVjdCk7XG5cdCAgICBjdXJyLm9iamVjdCA9IGFycltpXTtcblx0ICAgIGN1cnIudmFsdWUgPSBhcnJbaV0uZW5kO1xuXHR9XG5cdHJlZHVjZWRfYXJyLnB1c2goY3Vyci5vYmplY3QpO1xuXG5cdC8vIHJlZHVjZWRfYXJyLnB1c2goYXJyW2Fyci5sZW5ndGgtMV0pO1xuXHRyZXR1cm4gcmVkdWNlZF9hcnI7XG4gICAgfSk7XG5cbiAgICByZWR1Y2Uuam9pbiA9IGZ1bmN0aW9uIChjYmFrKSB7XG5cdGlmICghYXJndW1lbnRzLmxlbmd0aCkge1xuXHQgICAgcmV0dXJuIGpvaW47XG5cdH1cblx0am9pbiA9IGNiYWs7XG5cdHJldHVybiByZWQ7XG4gICAgfTtcblxuICAgIHJlZHVjZS52YWx1ZTIgPSBmdW5jdGlvbiAoZmllbGQpIHtcblx0aWYgKCFhcmd1bWVudHMubGVuZ3RoKSB7XG5cdCAgICByZXR1cm4gdmFsdWUyO1xuXHR9XG5cdHZhbHVlMiA9IGZpZWxkO1xuXHRyZXR1cm4gcmVkO1xuICAgIH07XG5cbiAgICByZXR1cm4gcmVkO1xufTtcblxudmFyIGxpbmUgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIHJlZCA9IHJlZHVjZSgpO1xuXG4gICAgcmVkLnJlZHVjZXIgKCBmdW5jdGlvbiAoYXJyKSB7XG5cdHZhciByZWR1bmRhbnQgPSByZWQucmVkdW5kYW50KCk7XG5cdHZhciB2YWx1ZSA9IHJlZC52YWx1ZSgpO1xuXHR2YXIgcmVkdWNlZF9hcnIgPSBbXTtcblx0dmFyIGN1cnIgPSBhcnJbMF07XG5cdGZvciAodmFyIGk9MTsgaTxhcnIubGVuZ3RoLTE7IGkrKykge1xuXHQgICAgaWYgKHJlZHVuZGFudCAoYXJyW2ldW3ZhbHVlXSwgY3Vyclt2YWx1ZV0pKSB7XG5cdFx0Y29udGludWU7XG5cdCAgICB9XG5cdCAgICByZWR1Y2VkX2Fyci5wdXNoIChjdXJyKTtcblx0ICAgIGN1cnIgPSBhcnJbaV07XG5cdH1cblx0cmVkdWNlZF9hcnIucHVzaChjdXJyKTtcblx0cmVkdWNlZF9hcnIucHVzaChhcnJbYXJyLmxlbmd0aC0xXSk7XG5cdHJldHVybiByZWR1Y2VkX2FycjtcbiAgICB9KTtcblxuICAgIHJldHVybiByZWQ7XG5cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gcmVkdWNlO1xubW9kdWxlLmV4cG9ydHMubGluZSA9IGxpbmU7XG5tb2R1bGUuZXhwb3J0cy5ibG9jayA9IGJsb2NrO1xuXG4iLCJcbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGl0ZXJhdG9yIDogZnVuY3Rpb24oaW5pdF92YWwpIHtcblx0dmFyIGkgPSBpbml0X3ZhbCB8fCAwO1xuXHR2YXIgaXRlciA9IGZ1bmN0aW9uICgpIHtcblx0ICAgIHJldHVybiBpKys7XG5cdH07XG5cdHJldHVybiBpdGVyO1xuICAgIH0sXG5cbiAgICBzY3JpcHRfcGF0aCA6IGZ1bmN0aW9uIChzY3JpcHRfbmFtZSkgeyAvLyBzY3JpcHRfbmFtZSBpcyB0aGUgZmlsZW5hbWVcblx0dmFyIHNjcmlwdF9zY2FwZWQgPSBzY3JpcHRfbmFtZS5yZXBsYWNlKC9bLVxcL1xcXFxeJCorPy4oKXxbXFxde31dL2csICdcXFxcJCYnKTtcblx0dmFyIHNjcmlwdF9yZSA9IG5ldyBSZWdFeHAoc2NyaXB0X3NjYXBlZCArICckJyk7XG5cdHZhciBzY3JpcHRfcmVfc3ViID0gbmV3IFJlZ0V4cCgnKC4qKScgKyBzY3JpcHRfc2NhcGVkICsgJyQnKTtcblxuXHQvLyBUT0RPOiBUaGlzIHJlcXVpcmVzIHBoYW50b20uanMgb3IgYSBzaW1pbGFyIGhlYWRsZXNzIHdlYmtpdCB0byB3b3JrIChkb2N1bWVudClcblx0dmFyIHNjcmlwdHMgPSBkb2N1bWVudC5nZXRFbGVtZW50c0J5VGFnTmFtZSgnc2NyaXB0Jyk7XG5cdHZhciBwYXRoID0gXCJcIjsgIC8vIERlZmF1bHQgdG8gY3VycmVudCBwYXRoXG5cdGlmKHNjcmlwdHMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgZm9yKHZhciBpIGluIHNjcmlwdHMpIHtcblx0XHRpZihzY3JpcHRzW2ldLnNyYyAmJiBzY3JpcHRzW2ldLnNyYy5tYXRjaChzY3JpcHRfcmUpKSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiBzY3JpcHRzW2ldLnNyYy5yZXBsYWNlKHNjcmlwdF9yZV9zdWIsICckMScpO1xuXHRcdH1cbiAgICAgICAgICAgIH1cblx0fVxuXHRyZXR1cm4gcGF0aDtcbiAgICB9LFxuXG4gICAgZGVmZXJfY2FuY2VsIDogZnVuY3Rpb24gKGNiYWssIHRpbWUpIHtcbiAgICAgICAgdmFyIHRpY2s7XG5cbiAgICAgICAgdmFyIGRlZmVyX2NhbmNlbCA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHZhciBhcmdzID0gQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoYXJndW1lbnRzKTtcbiAgICAgICAgICAgIHZhciB0aGF0ID0gdGhpcztcbiAgICAgICAgICAgIGNsZWFyVGltZW91dCh0aWNrKTtcbiAgICAgICAgICAgIHRpY2sgPSBzZXRUaW1lb3V0IChmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICAgICAgY2Jhay5hcHBseSAodGhhdCwgYXJncyk7XG4gICAgICAgICAgICB9LCB0aW1lKTtcbiAgICAgICAgfTtcblxuICAgICAgICByZXR1cm4gZGVmZXJfY2FuY2VsO1xuICAgIH1cbn07XG4iLCJ2YXIgYXBpanMgPSByZXF1aXJlKFwidG50LmFwaVwiKTtcbnZhciBpdGVyYXRvciA9IHJlcXVpcmUoXCJ0bnQudXRpbHNcIikuaXRlcmF0b3I7XG5cbnZhciB0bnRfbm9kZSA9IGZ1bmN0aW9uIChkYXRhKSB7XG4vL3RudC50cmVlLm5vZGUgPSBmdW5jdGlvbiAoZGF0YSkge1xuICAgIFwidXNlIHN0cmljdFwiO1xuXG4gICAgdmFyIG5vZGUgPSBmdW5jdGlvbiAoKSB7XG4gICAgfTtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAobm9kZSk7XG5cbiAgICAvLyBBUElcbi8vICAgICBub2RlLm5vZGVzID0gZnVuY3Rpb24oKSB7XG4vLyBcdGlmIChjbHVzdGVyID09PSB1bmRlZmluZWQpIHtcbi8vIFx0ICAgIGNsdXN0ZXIgPSBkMy5sYXlvdXQuY2x1c3RlcigpXG4vLyBcdCAgICAvLyBUT0RPOiBsZW5ndGggYW5kIGNoaWxkcmVuIHNob3VsZCBiZSBleHBvc2VkIGluIHRoZSBBUElcbi8vIFx0ICAgIC8vIGkuZS4gdGhlIHVzZXIgc2hvdWxkIGJlIGFibGUgdG8gY2hhbmdlIHRoaXMgZGVmYXVsdHMgdmlhIHRoZSBBUElcbi8vIFx0ICAgIC8vIGNoaWxkcmVuIGlzIHRoZSBkZWZhdWx0cyBmb3IgcGFyc2VfbmV3aWNrLCBidXQgbWF5YmUgd2Ugc2hvdWxkIGNoYW5nZSB0aGF0XG4vLyBcdCAgICAvLyBvciBhdCBsZWFzdCBub3QgYXNzdW1lIHRoaXMgaXMgYWx3YXlzIHRoZSBjYXNlIGZvciB0aGUgZGF0YSBwcm92aWRlZFxuLy8gXHRcdC52YWx1ZShmdW5jdGlvbihkKSB7cmV0dXJuIGQubGVuZ3RofSlcbi8vIFx0XHQuY2hpbGRyZW4oZnVuY3Rpb24oZCkge3JldHVybiBkLmNoaWxkcmVufSk7XG4vLyBcdH1cbi8vIFx0bm9kZXMgPSBjbHVzdGVyLm5vZGVzKGRhdGEpO1xuLy8gXHRyZXR1cm4gbm9kZXM7XG4vLyAgICAgfTtcblxuICAgIHZhciBhcHBseV90b19kYXRhID0gZnVuY3Rpb24gKGRhdGEsIGNiYWspIHtcblx0Y2JhayhkYXRhKTtcblx0aWYgKGRhdGEuY2hpbGRyZW4gIT09IHVuZGVmaW5lZCkge1xuXHQgICAgZm9yICh2YXIgaT0wOyBpPGRhdGEuY2hpbGRyZW4ubGVuZ3RoOyBpKyspIHtcblx0XHRhcHBseV90b19kYXRhKGRhdGEuY2hpbGRyZW5baV0sIGNiYWspO1xuXHQgICAgfVxuXHR9XG4gICAgfTtcblxuICAgIHZhciBjcmVhdGVfaWRzID0gZnVuY3Rpb24gKCkge1xuXHR2YXIgaSA9IGl0ZXJhdG9yKDEpO1xuXHQvLyBXZSBjYW4ndCB1c2UgYXBwbHkgYmVjYXVzZSBhcHBseSBjcmVhdGVzIG5ldyB0cmVlcyBvbiBldmVyeSBub2RlXG5cdC8vIFdlIHNob3VsZCB1c2UgdGhlIGRpcmVjdCBkYXRhIGluc3RlYWRcblx0YXBwbHlfdG9fZGF0YSAoZGF0YSwgZnVuY3Rpb24gKGQpIHtcblx0ICAgIGlmIChkLl9pZCA9PT0gdW5kZWZpbmVkKSB7XG5cdFx0ZC5faWQgPSBpKCk7XG5cdFx0Ly8gVE9ETzogTm90IHN1cmUgX2luU3ViVHJlZSBpcyBzdHJpY3RseSBuZWNlc3Nhcnlcblx0XHQvLyBkLl9pblN1YlRyZWUgPSB7cHJldjp0cnVlLCBjdXJyOnRydWV9O1xuXHQgICAgfVxuXHR9KTtcbiAgICB9O1xuXG4gICAgdmFyIGxpbmtfcGFyZW50cyA9IGZ1bmN0aW9uIChkYXRhKSB7XG5cdGlmIChkYXRhID09PSB1bmRlZmluZWQpIHtcblx0ICAgIHJldHVybjtcblx0fVxuXHRpZiAoZGF0YS5jaGlsZHJlbiA9PT0gdW5kZWZpbmVkKSB7XG5cdCAgICByZXR1cm47XG5cdH1cblx0Zm9yICh2YXIgaT0wOyBpPGRhdGEuY2hpbGRyZW4ubGVuZ3RoOyBpKyspIHtcblx0ICAgIC8vIF9wYXJlbnQ/XG5cdCAgICBkYXRhLmNoaWxkcmVuW2ldLl9wYXJlbnQgPSBkYXRhO1xuXHQgICAgbGlua19wYXJlbnRzKGRhdGEuY2hpbGRyZW5baV0pO1xuXHR9XG4gICAgfTtcblxuICAgIHZhciBjb21wdXRlX3Jvb3RfZGlzdHMgPSBmdW5jdGlvbiAoZGF0YSkge1xuXHRhcHBseV90b19kYXRhIChkYXRhLCBmdW5jdGlvbiAoZCkge1xuXHQgICAgdmFyIGw7XG5cdCAgICBpZiAoZC5fcGFyZW50ID09PSB1bmRlZmluZWQpIHtcblx0XHRkLl9yb290X2Rpc3QgPSAwO1xuXHQgICAgfSBlbHNlIHtcblx0XHR2YXIgbCA9IDA7XG5cdFx0aWYgKGQuYnJhbmNoX2xlbmd0aCkge1xuXHRcdCAgICBsID0gZC5icmFuY2hfbGVuZ3RoXG5cdFx0fVxuXHRcdGQuX3Jvb3RfZGlzdCA9IGwgKyBkLl9wYXJlbnQuX3Jvb3RfZGlzdDtcblx0ICAgIH1cblx0fSk7XG4gICAgfTtcblxuICAgIC8vIFRPRE86IGRhdGEgY2FuJ3QgYmUgcmV3cml0dGVuIHVzZWQgdGhlIGFwaSB5ZXQuIFdlIG5lZWQgZmluYWxpemVyc1xuICAgIG5vZGUuZGF0YSA9IGZ1bmN0aW9uKG5ld19kYXRhKSB7XG5cdGlmICghYXJndW1lbnRzLmxlbmd0aCkge1xuXHQgICAgcmV0dXJuIGRhdGFcblx0fVxuXHRkYXRhID0gbmV3X2RhdGE7XG5cdGNyZWF0ZV9pZHMoKTtcblx0bGlua19wYXJlbnRzKGRhdGEpO1xuXHRjb21wdXRlX3Jvb3RfZGlzdHMoZGF0YSk7XG5cdHJldHVybiBub2RlO1xuICAgIH07XG4gICAgLy8gV2UgYmluZCB0aGUgZGF0YSB0aGF0IGhhcyBiZWVuIHBhc3NlZFxuICAgIG5vZGUuZGF0YShkYXRhKTtcblxuICAgIGFwaS5tZXRob2QgKCdmaW5kX2FsbCcsIGZ1bmN0aW9uIChjYmFrLCBkZWVwKSB7XG5cdHZhciBub2RlcyA9IFtdO1xuXHRub2RlLmFwcGx5IChmdW5jdGlvbiAobikge1xuXHQgICAgaWYgKGNiYWsobikpIHtcblx0XHRub2Rlcy5wdXNoIChuKTtcblx0ICAgIH1cblx0fSk7XG5cdHJldHVybiBub2RlcztcbiAgICB9KTtcbiAgICBcbiAgICBhcGkubWV0aG9kICgnZmluZF9ub2RlJywgZnVuY3Rpb24gKGNiYWssIGRlZXApIHtcblx0aWYgKGNiYWsobm9kZSkpIHtcblx0ICAgIHJldHVybiBub2RlO1xuXHR9XG5cblx0aWYgKGRhdGEuY2hpbGRyZW4gIT09IHVuZGVmaW5lZCkge1xuXHQgICAgZm9yICh2YXIgaj0wOyBqPGRhdGEuY2hpbGRyZW4ubGVuZ3RoOyBqKyspIHtcblx0XHR2YXIgZm91bmQgPSB0bnRfbm9kZShkYXRhLmNoaWxkcmVuW2pdKS5maW5kX25vZGUoY2JhaywgZGVlcCk7XG5cdFx0aWYgKGZvdW5kKSB7XG5cdFx0ICAgIHJldHVybiBmb3VuZDtcblx0XHR9XG5cdCAgICB9XG5cdH1cblxuXHRpZiAoZGVlcCAmJiAoZGF0YS5fY2hpbGRyZW4gIT09IHVuZGVmaW5lZCkpIHtcblx0ICAgIGZvciAodmFyIGk9MDsgaTxkYXRhLl9jaGlsZHJlbi5sZW5ndGg7IGkrKykge1xuXHRcdHRudF9ub2RlKGRhdGEuX2NoaWxkcmVuW2ldKS5maW5kX25vZGUoY2JhaywgZGVlcClcblx0XHR2YXIgZm91bmQgPSB0bnRfbm9kZShkYXRhLl9jaGlsZHJlbltpXSkuZmluZF9ub2RlKGNiYWssIGRlZXApO1xuXHRcdGlmIChmb3VuZCkge1xuXHRcdCAgICByZXR1cm4gZm91bmQ7XG5cdFx0fVxuXHQgICAgfVxuXHR9XG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kICgnZmluZF9ub2RlX2J5X25hbWUnLCBmdW5jdGlvbihuYW1lLCBkZWVwKSB7XG5cdHJldHVybiBub2RlLmZpbmRfbm9kZSAoZnVuY3Rpb24gKG5vZGUpIHtcblx0ICAgIHJldHVybiBub2RlLm5vZGVfbmFtZSgpID09PSBuYW1lXG5cdH0sIGRlZXApO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ3RvZ2dsZScsIGZ1bmN0aW9uKCkge1xuXHRpZiAoZGF0YSkge1xuXHQgICAgaWYgKGRhdGEuY2hpbGRyZW4pIHsgLy8gVW5jb2xsYXBzZWQgLT4gY29sbGFwc2Vcblx0XHR2YXIgaGlkZGVuID0gMDtcblx0XHRub2RlLmFwcGx5IChmdW5jdGlvbiAobikge1xuXHRcdCAgICB2YXIgaGlkZGVuX2hlcmUgPSBuLm5faGlkZGVuKCkgfHwgMDtcblx0XHQgICAgaGlkZGVuICs9IChuLm5faGlkZGVuKCkgfHwgMCkgKyAxO1xuXHRcdH0pO1xuXHRcdG5vZGUubl9oaWRkZW4gKGhpZGRlbi0xKTtcblx0XHRkYXRhLl9jaGlsZHJlbiA9IGRhdGEuY2hpbGRyZW47XG5cdFx0ZGF0YS5jaGlsZHJlbiA9IHVuZGVmaW5lZDtcblx0ICAgIH0gZWxzZSB7ICAgICAgICAgICAgIC8vIENvbGxhcHNlZCAtPiB1bmNvbGxhcHNlXG5cdFx0bm9kZS5uX2hpZGRlbigwKTtcblx0XHRkYXRhLmNoaWxkcmVuID0gZGF0YS5fY2hpbGRyZW47XG5cdFx0ZGF0YS5fY2hpbGRyZW4gPSB1bmRlZmluZWQ7XG5cdCAgICB9XG5cdH1cblx0cmV0dXJuIHRoaXM7XG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kICgnaXNfY29sbGFwc2VkJywgZnVuY3Rpb24gKCkge1xuXHRyZXR1cm4gKGRhdGEuX2NoaWxkcmVuICE9PSB1bmRlZmluZWQgJiYgZGF0YS5jaGlsZHJlbiA9PT0gdW5kZWZpbmVkKTtcbiAgICB9KTtcblxuICAgIHZhciBoYXNfYW5jZXN0b3IgPSBmdW5jdGlvbihuLCBhbmNlc3Rvcikge1xuXHQvLyBJdCBpcyBiZXR0ZXIgdG8gd29yayBhdCB0aGUgZGF0YSBsZXZlbFxuXHRuID0gbi5kYXRhKCk7XG5cdGFuY2VzdG9yID0gYW5jZXN0b3IuZGF0YSgpO1xuXHRpZiAobi5fcGFyZW50ID09PSB1bmRlZmluZWQpIHtcblx0ICAgIHJldHVybiBmYWxzZVxuXHR9XG5cdG4gPSBuLl9wYXJlbnRcblx0Zm9yICg7Oykge1xuXHQgICAgaWYgKG4gPT09IHVuZGVmaW5lZCkge1xuXHRcdHJldHVybiBmYWxzZTtcblx0ICAgIH1cblx0ICAgIGlmIChuID09PSBhbmNlc3Rvcikge1xuXHRcdHJldHVybiB0cnVlO1xuXHQgICAgfVxuXHQgICAgbiA9IG4uX3BhcmVudDtcblx0fVxuICAgIH07XG5cbiAgICAvLyBUaGlzIGlzIHRoZSBlYXNpZXN0IHdheSB0byBjYWxjdWxhdGUgdGhlIExDQSBJIGNhbiB0aGluayBvZi4gQnV0IGl0IGlzIHZlcnkgaW5lZmZpY2llbnQgdG9vLlxuICAgIC8vIEl0IGlzIHdvcmtpbmcgZmluZSBieSBub3csIGJ1dCBpbiBjYXNlIGl0IG5lZWRzIHRvIGJlIG1vcmUgcGVyZm9ybWFudCB3ZSBjYW4gaW1wbGVtZW50IHRoZSBMQ0FcbiAgICAvLyBhbGdvcml0aG0gZXhwbGFpbmVkIGhlcmU6XG4gICAgLy8gaHR0cDovL2NvbW11bml0eS50b3Bjb2Rlci5jb20vdGM/bW9kdWxlPVN0YXRpYyZkMT10dXRvcmlhbHMmZDI9bG93ZXN0Q29tbW9uQW5jZXN0b3JcbiAgICBhcGkubWV0aG9kICgnbGNhJywgZnVuY3Rpb24gKG5vZGVzKSB7XG5cdGlmIChub2Rlcy5sZW5ndGggPT09IDEpIHtcblx0ICAgIHJldHVybiBub2Rlc1swXTtcblx0fVxuXHR2YXIgbGNhX25vZGUgPSBub2Rlc1swXTtcblx0Zm9yICh2YXIgaSA9IDE7IGk8bm9kZXMubGVuZ3RoOyBpKyspIHtcblx0ICAgIGxjYV9ub2RlID0gX2xjYShsY2Ffbm9kZSwgbm9kZXNbaV0pO1xuXHR9XG5cdHJldHVybiBsY2Ffbm9kZTtcblx0Ly8gcmV0dXJuIHRudF9ub2RlKGxjYV9ub2RlKTtcbiAgICB9KTtcblxuICAgIHZhciBfbGNhID0gZnVuY3Rpb24obm9kZTEsIG5vZGUyKSB7XG5cdGlmIChub2RlMS5kYXRhKCkgPT09IG5vZGUyLmRhdGEoKSkge1xuXHQgICAgcmV0dXJuIG5vZGUxO1xuXHR9XG5cdGlmIChoYXNfYW5jZXN0b3Iobm9kZTEsIG5vZGUyKSkge1xuXHQgICAgcmV0dXJuIG5vZGUyO1xuXHR9XG5cdHJldHVybiBfbGNhKG5vZGUxLCBub2RlMi5wYXJlbnQoKSk7XG4gICAgfTtcblxuICAgIGFwaS5tZXRob2QoJ25faGlkZGVuJywgZnVuY3Rpb24gKHZhbCkge1xuXHRpZiAoIWFyZ3VtZW50cy5sZW5ndGgpIHtcblx0ICAgIHJldHVybiBub2RlLnByb3BlcnR5KCdfaGlkZGVuJyk7XG5cdH1cblx0bm9kZS5wcm9wZXJ0eSgnX2hpZGRlbicsIHZhbCk7XG5cdHJldHVybiBub2RlXG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kICgnZ2V0X2FsbF9ub2RlcycsIGZ1bmN0aW9uIChkZWVwKSB7XG5cdHZhciBub2RlcyA9IFtdO1xuXHRub2RlLmFwcGx5KGZ1bmN0aW9uIChuKSB7XG5cdCAgICBub2Rlcy5wdXNoKG4pO1xuXHR9LCBkZWVwKTtcblx0cmV0dXJuIG5vZGVzO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ2dldF9hbGxfbGVhdmVzJywgZnVuY3Rpb24gKGRlZXApIHtcblx0dmFyIGxlYXZlcyA9IFtdO1xuXHRub2RlLmFwcGx5KGZ1bmN0aW9uIChuKSB7XG5cdCAgICBpZiAobi5pc19sZWFmKGRlZXApKSB7XG5cdFx0bGVhdmVzLnB1c2gobik7XG5cdCAgICB9XG5cdH0sIGRlZXApO1xuXHRyZXR1cm4gbGVhdmVzO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ3Vwc3RyZWFtJywgZnVuY3Rpb24oY2Jhaykge1xuXHRjYmFrKG5vZGUpO1xuXHR2YXIgcGFyZW50ID0gbm9kZS5wYXJlbnQoKTtcblx0aWYgKHBhcmVudCAhPT0gdW5kZWZpbmVkKSB7XG5cdCAgICBwYXJlbnQudXBzdHJlYW0oY2Jhayk7XG5cdH1cbi8vXHR0bnRfbm9kZShwYXJlbnQpLnVwc3RyZWFtKGNiYWspO1xuLy8gXHRub2RlLnVwc3RyZWFtKG5vZGUuX3BhcmVudCwgY2Jhayk7XG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kICgnc3VidHJlZScsIGZ1bmN0aW9uKG5vZGVzLCBrZWVwX3NpbmdsZXRvbnMpIHtcblx0aWYgKGtlZXBfc2luZ2xldG9ucyA9PT0gdW5kZWZpbmVkKSB7XG5cdCAgICBrZWVwX3NpbmdsZXRvbnMgPSBmYWxzZTtcblx0fVxuICAgIFx0dmFyIG5vZGVfY291bnRzID0ge307XG4gICAgXHRmb3IgKHZhciBpPTA7IGk8bm9kZXMubGVuZ3RoOyBpKyspIHtcblx0ICAgIHZhciBuID0gbm9kZXNbaV07XG5cdCAgICBpZiAobiAhPT0gdW5kZWZpbmVkKSB7XG5cdFx0bi51cHN0cmVhbSAoZnVuY3Rpb24gKHRoaXNfbm9kZSl7XG5cdFx0ICAgIHZhciBpZCA9IHRoaXNfbm9kZS5pZCgpO1xuXHRcdCAgICBpZiAobm9kZV9jb3VudHNbaWRdID09PSB1bmRlZmluZWQpIHtcblx0XHRcdG5vZGVfY291bnRzW2lkXSA9IDA7XG5cdFx0ICAgIH1cblx0XHQgICAgbm9kZV9jb3VudHNbaWRdKytcbiAgICBcdFx0fSk7XG5cdCAgICB9XG4gICAgXHR9XG4gICAgXG5cdHZhciBpc19zaW5nbGV0b24gPSBmdW5jdGlvbiAobm9kZV9kYXRhKSB7XG5cdCAgICB2YXIgbl9jaGlsZHJlbiA9IDA7XG5cdCAgICBpZiAobm9kZV9kYXRhLmNoaWxkcmVuID09PSB1bmRlZmluZWQpIHtcblx0XHRyZXR1cm4gZmFsc2U7XG5cdCAgICB9XG5cdCAgICBmb3IgKHZhciBpPTA7IGk8bm9kZV9kYXRhLmNoaWxkcmVuLmxlbmd0aDsgaSsrKSB7XG5cdFx0dmFyIGlkID0gbm9kZV9kYXRhLmNoaWxkcmVuW2ldLl9pZDtcblx0XHRpZiAobm9kZV9jb3VudHNbaWRdID4gMCkge1xuXHRcdCAgICBuX2NoaWxkcmVuKys7XG5cdFx0fVxuXHQgICAgfVxuXHQgICAgcmV0dXJuIG5fY2hpbGRyZW4gPT09IDE7XG5cdH07XG5cblx0dmFyIHN1YnRyZWUgPSB7fTtcblx0Y29weV9kYXRhIChkYXRhLCBzdWJ0cmVlLCAwLCBmdW5jdGlvbiAobm9kZV9kYXRhKSB7XG5cdCAgICB2YXIgbm9kZV9pZCA9IG5vZGVfZGF0YS5faWQ7XG5cdCAgICB2YXIgY291bnRzID0gbm9kZV9jb3VudHNbbm9kZV9pZF07XG5cdCAgICBcblx0ICAgIC8vIElzIGluIHBhdGhcblx0ICAgIGlmIChjb3VudHMgPiAwKSB7XG5cdFx0aWYgKGlzX3NpbmdsZXRvbihub2RlX2RhdGEpICYmICFrZWVwX3NpbmdsZXRvbnMpIHtcblx0XHQgICAgcmV0dXJuIGZhbHNlOyBcblx0XHR9XG5cdFx0cmV0dXJuIHRydWU7XG5cdCAgICB9XG5cdCAgICAvLyBJcyBub3QgaW4gcGF0aFxuXHQgICAgcmV0dXJuIGZhbHNlO1xuXHR9KTtcblxuXHRyZXR1cm4gdG50X25vZGUoc3VidHJlZS5jaGlsZHJlblswXSk7XG4gICAgfSk7XG5cbiAgICB2YXIgY29weV9kYXRhID0gZnVuY3Rpb24gKG9yaWdfZGF0YSwgc3VidHJlZSwgY3VyckJyYW5jaExlbmd0aCwgY29uZGl0aW9uKSB7XG4gICAgICAgIGlmIChvcmlnX2RhdGEgPT09IHVuZGVmaW5lZCkge1xuXHQgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGNvbmRpdGlvbihvcmlnX2RhdGEpKSB7XG5cdCAgICB2YXIgY29weSA9IGNvcHlfbm9kZShvcmlnX2RhdGEsIGN1cnJCcmFuY2hMZW5ndGgpO1xuXHQgICAgaWYgKHN1YnRyZWUuY2hpbGRyZW4gPT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgICAgIHN1YnRyZWUuY2hpbGRyZW4gPSBbXTtcblx0ICAgIH1cblx0ICAgIHN1YnRyZWUuY2hpbGRyZW4ucHVzaChjb3B5KTtcblx0ICAgIGlmIChvcmlnX2RhdGEuY2hpbGRyZW4gPT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgICAgIHJldHVybjtcblx0ICAgIH1cblx0ICAgIGZvciAodmFyIGkgPSAwOyBpIDwgb3JpZ19kYXRhLmNoaWxkcmVuLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICAgICAgY29weV9kYXRhIChvcmlnX2RhdGEuY2hpbGRyZW5baV0sIGNvcHksIDAsIGNvbmRpdGlvbik7XG5cdCAgICB9XG4gICAgICAgIH0gZWxzZSB7XG5cdCAgICBpZiAob3JpZ19kYXRhLmNoaWxkcmVuID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgICAgICAgICByZXR1cm47XG5cdCAgICB9XG5cdCAgICBjdXJyQnJhbmNoTGVuZ3RoICs9IG9yaWdfZGF0YS5icmFuY2hfbGVuZ3RoIHx8IDA7XG5cdCAgICBmb3IgKHZhciBpID0gMDsgaSA8IG9yaWdfZGF0YS5jaGlsZHJlbi5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgICAgIGNvcHlfZGF0YShvcmlnX2RhdGEuY2hpbGRyZW5baV0sIHN1YnRyZWUsIGN1cnJCcmFuY2hMZW5ndGgsIGNvbmRpdGlvbik7XG5cdCAgICB9XG4gICAgICAgIH1cbiAgICB9O1xuXG4gICAgdmFyIGNvcHlfbm9kZSA9IGZ1bmN0aW9uIChub2RlX2RhdGEsIGV4dHJhQnJhbmNoTGVuZ3RoKSB7XG5cdHZhciBjb3B5ID0ge307XG5cdC8vIGNvcHkgYWxsIHRoZSBvd24gcHJvcGVydGllcyBleGNlcHRzIGxpbmtzIHRvIG90aGVyIG5vZGVzIG9yIGRlcHRoXG5cdGZvciAodmFyIHBhcmFtIGluIG5vZGVfZGF0YSkge1xuXHQgICAgaWYgKChwYXJhbSA9PT0gXCJjaGlsZHJlblwiKSB8fFxuXHRcdChwYXJhbSA9PT0gXCJfY2hpbGRyZW5cIikgfHxcblx0XHQocGFyYW0gPT09IFwiX3BhcmVudFwiKSB8fFxuXHRcdChwYXJhbSA9PT0gXCJkZXB0aFwiKSkge1xuXHRcdGNvbnRpbnVlO1xuXHQgICAgfVxuXHQgICAgaWYgKG5vZGVfZGF0YS5oYXNPd25Qcm9wZXJ0eShwYXJhbSkpIHtcblx0XHRjb3B5W3BhcmFtXSA9IG5vZGVfZGF0YVtwYXJhbV07XG5cdCAgICB9XG5cdH1cblx0aWYgKChjb3B5LmJyYW5jaF9sZW5ndGggIT09IHVuZGVmaW5lZCkgJiYgKGV4dHJhQnJhbmNoTGVuZ3RoICE9PSB1bmRlZmluZWQpKSB7XG5cdCAgICBjb3B5LmJyYW5jaF9sZW5ndGggKz0gZXh0cmFCcmFuY2hMZW5ndGg7XG5cdH1cblx0cmV0dXJuIGNvcHk7XG4gICAgfTtcblxuICAgIFxuICAgIC8vIFRPRE86IFRoaXMgbWV0aG9kIHZpc2l0cyBhbGwgdGhlIG5vZGVzXG4gICAgLy8gYSBtb3JlIHBlcmZvcm1hbnQgdmVyc2lvbiBzaG91bGQgcmV0dXJuIHRydWVcbiAgICAvLyB0aGUgZmlyc3QgdGltZSBjYmFrKG5vZGUpIGlzIHRydWVcbiAgICBhcGkubWV0aG9kICgncHJlc2VudCcsIGZ1bmN0aW9uIChjYmFrKSB7XG5cdC8vIGNiYWsgc2hvdWxkIHJldHVybiB0cnVlL2ZhbHNlXG5cdHZhciBpc190cnVlID0gZmFsc2U7XG5cdG5vZGUuYXBwbHkgKGZ1bmN0aW9uIChuKSB7XG5cdCAgICBpZiAoY2JhayhuKSA9PT0gdHJ1ZSkge1xuXHRcdGlzX3RydWUgPSB0cnVlO1xuXHQgICAgfVxuXHR9KTtcblx0cmV0dXJuIGlzX3RydWU7XG4gICAgfSk7XG5cbiAgICAvLyBjYmFrIGlzIGNhbGxlZCB3aXRoIHR3byBub2Rlc1xuICAgIC8vIGFuZCBzaG91bGQgcmV0dXJuIGEgbmVnYXRpdmUgbnVtYmVyLCAwIG9yIGEgcG9zaXRpdmUgbnVtYmVyXG4gICAgYXBpLm1ldGhvZCAoJ3NvcnQnLCBmdW5jdGlvbiAoY2Jhaykge1xuXHRpZiAoZGF0YS5jaGlsZHJlbiA9PT0gdW5kZWZpbmVkKSB7XG5cdCAgICByZXR1cm47XG5cdH1cblxuXHR2YXIgbmV3X2NoaWxkcmVuID0gW107XG5cdGZvciAodmFyIGk9MDsgaTxkYXRhLmNoaWxkcmVuLmxlbmd0aDsgaSsrKSB7XG5cdCAgICBuZXdfY2hpbGRyZW4ucHVzaCh0bnRfbm9kZShkYXRhLmNoaWxkcmVuW2ldKSk7XG5cdH1cblxuXHRuZXdfY2hpbGRyZW4uc29ydChjYmFrKTtcblxuXHRkYXRhLmNoaWxkcmVuID0gW107XG5cdGZvciAodmFyIGk9MDsgaTxuZXdfY2hpbGRyZW4ubGVuZ3RoOyBpKyspIHtcblx0ICAgIGRhdGEuY2hpbGRyZW4ucHVzaChuZXdfY2hpbGRyZW5baV0uZGF0YSgpKTtcblx0fVxuXG5cdGZvciAodmFyIGk9MDsgaTxkYXRhLmNoaWxkcmVuLmxlbmd0aDsgaSsrKSB7XG5cdCAgICB0bnRfbm9kZShkYXRhLmNoaWxkcmVuW2ldKS5zb3J0KGNiYWspO1xuXHR9XG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kICgnZmxhdHRlbicsIGZ1bmN0aW9uIChwcmVzZXJ2ZV9pbnRlcm5hbCkge1xuXHRpZiAobm9kZS5pc19sZWFmKCkpIHtcblx0ICAgIHJldHVybiBub2RlO1xuXHR9XG5cdHZhciBkYXRhID0gbm9kZS5kYXRhKCk7XG5cdHZhciBuZXdyb290ID0gY29weV9ub2RlKGRhdGEpO1xuXHR2YXIgbm9kZXM7XG5cdGlmIChwcmVzZXJ2ZV9pbnRlcm5hbCkge1xuXHQgICAgbm9kZXMgPSBub2RlLmdldF9hbGxfbm9kZXMoKTtcblx0ICAgIG5vZGVzLnNoaWZ0KCk7IC8vIHRoZSBzZWxmIG5vZGUgaXMgYWxzbyBpbmNsdWRlZFxuXHR9IGVsc2Uge1xuXHQgICAgbm9kZXMgPSBub2RlLmdldF9hbGxfbGVhdmVzKCk7XG5cdH1cblx0bmV3cm9vdC5jaGlsZHJlbiA9IFtdO1xuXHRmb3IgKHZhciBpPTA7IGk8bm9kZXMubGVuZ3RoOyBpKyspIHtcblx0ICAgIGRlbGV0ZSAobm9kZXNbaV0uY2hpbGRyZW4pO1xuXHQgICAgbmV3cm9vdC5jaGlsZHJlbi5wdXNoKGNvcHlfbm9kZShub2Rlc1tpXS5kYXRhKCkpKTtcblx0fVxuXG5cdHJldHVybiB0bnRfbm9kZShuZXdyb290KTtcbiAgICB9KTtcblxuICAgIFxuICAgIC8vIFRPRE86IFRoaXMgbWV0aG9kIG9ubHkgJ2FwcGx5J3MgdG8gbm9uIGNvbGxhcHNlZCBub2RlcyAoaWUgLl9jaGlsZHJlbiBpcyBub3QgdmlzaXRlZClcbiAgICAvLyBXb3VsZCBpdCBiZSBiZXR0ZXIgdG8gaGF2ZSBhbiBleHRyYSBmbGFnICh0cnVlL2ZhbHNlKSB0byB2aXNpdCBhbHNvIGNvbGxhcHNlZCBub2Rlcz9cbiAgICBhcGkubWV0aG9kICgnYXBwbHknLCBmdW5jdGlvbihjYmFrLCBkZWVwKSB7XG5cdGlmIChkZWVwID09PSB1bmRlZmluZWQpIHtcblx0ICAgIGRlZXAgPSBmYWxzZTtcblx0fVxuXHRjYmFrKG5vZGUpO1xuXHRpZiAoZGF0YS5jaGlsZHJlbiAhPT0gdW5kZWZpbmVkKSB7XG5cdCAgICBmb3IgKHZhciBpPTA7IGk8ZGF0YS5jaGlsZHJlbi5sZW5ndGg7IGkrKykge1xuXHRcdHZhciBuID0gdG50X25vZGUoZGF0YS5jaGlsZHJlbltpXSlcblx0XHRuLmFwcGx5KGNiYWssIGRlZXApO1xuXHQgICAgfVxuXHR9XG5cblx0aWYgKChkYXRhLl9jaGlsZHJlbiAhPT0gdW5kZWZpbmVkKSAmJiBkZWVwKSB7XG5cdCAgICBmb3IgKHZhciBqPTA7IGo8ZGF0YS5fY2hpbGRyZW4ubGVuZ3RoOyBqKyspIHtcblx0XHR2YXIgbiA9IHRudF9ub2RlKGRhdGEuX2NoaWxkcmVuW2pdKTtcblx0XHRuLmFwcGx5KGNiYWssIGRlZXApO1xuXHQgICAgfVxuXHR9XG4gICAgfSk7XG5cbiAgICAvLyBUT0RPOiBOb3Qgc3VyZSBpZiBpdCBtYWtlcyBzZW5zZSB0byBzZXQgdmlhIGEgY2FsbGJhY2s6XG4gICAgLy8gcm9vdC5wcm9wZXJ0eSAoZnVuY3Rpb24gKG5vZGUsIHZhbCkge1xuICAgIC8vICAgIG5vZGUuZGVlcGVyLmZpZWxkID0gdmFsXG4gICAgLy8gfSwgJ25ld192YWx1ZScpXG4gICAgYXBpLm1ldGhvZCAoJ3Byb3BlcnR5JywgZnVuY3Rpb24ocHJvcCwgdmFsdWUpIHtcblx0aWYgKGFyZ3VtZW50cy5sZW5ndGggPT09IDEpIHtcblx0ICAgIGlmICgodHlwZW9mIHByb3ApID09PSAnZnVuY3Rpb24nKSB7XG5cdFx0cmV0dXJuIHByb3AoZGF0YSlcdFxuXHQgICAgfVxuXHQgICAgcmV0dXJuIGRhdGFbcHJvcF1cblx0fVxuXHRpZiAoKHR5cGVvZiBwcm9wKSA9PT0gJ2Z1bmN0aW9uJykge1xuXHQgICAgcHJvcChkYXRhLCB2YWx1ZSk7ICAgXG5cdH1cblx0ZGF0YVtwcm9wXSA9IHZhbHVlO1xuXHRyZXR1cm4gbm9kZTtcbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKCdpc19sZWFmJywgZnVuY3Rpb24oZGVlcCkge1xuXHRpZiAoZGVlcCkge1xuXHQgICAgcmV0dXJuICgoZGF0YS5jaGlsZHJlbiA9PT0gdW5kZWZpbmVkKSAmJiAoZGF0YS5fY2hpbGRyZW4gPT09IHVuZGVmaW5lZCkpO1xuXHR9XG5cdHJldHVybiBkYXRhLmNoaWxkcmVuID09PSB1bmRlZmluZWQ7XG4gICAgfSk7XG5cbiAgICAvLyBJdCBsb29rcyBsaWtlIHRoZSBjbHVzdGVyIGNhbid0IGJlIHVzZWQgZm9yIGFueXRoaW5nIHVzZWZ1bCBoZXJlXG4gICAgLy8gSXQgaXMgbm93IGluY2x1ZGVkIGFzIGFuIG9wdGlvbmFsIHBhcmFtZXRlciB0byB0aGUgdG50LnRyZWUoKSBtZXRob2QgY2FsbFxuICAgIC8vIHNvIEknbSBjb21tZW50aW5nIHRoZSBnZXR0ZXJcbiAgICAvLyBub2RlLmNsdXN0ZXIgPSBmdW5jdGlvbigpIHtcbiAgICAvLyBcdHJldHVybiBjbHVzdGVyO1xuICAgIC8vIH07XG5cbiAgICAvLyBub2RlLmRlcHRoID0gZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAvLyAgICAgcmV0dXJuIG5vZGUuZGVwdGg7XG4gICAgLy8gfTtcblxuLy8gICAgIG5vZGUubmFtZSA9IGZ1bmN0aW9uIChub2RlKSB7XG4vLyAgICAgICAgIHJldHVybiBub2RlLm5hbWU7XG4vLyAgICAgfTtcblxuICAgIGFwaS5tZXRob2QgKCdpZCcsIGZ1bmN0aW9uICgpIHtcblx0cmV0dXJuIG5vZGUucHJvcGVydHkoJ19pZCcpO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ25vZGVfbmFtZScsIGZ1bmN0aW9uICgpIHtcblx0cmV0dXJuIG5vZGUucHJvcGVydHkoJ25hbWUnKTtcbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKCdicmFuY2hfbGVuZ3RoJywgZnVuY3Rpb24gKCkge1xuXHRyZXR1cm4gbm9kZS5wcm9wZXJ0eSgnYnJhbmNoX2xlbmd0aCcpO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ3Jvb3RfZGlzdCcsIGZ1bmN0aW9uICgpIHtcblx0cmV0dXJuIG5vZGUucHJvcGVydHkoJ19yb290X2Rpc3QnKTtcbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKCdjaGlsZHJlbicsIGZ1bmN0aW9uIChkZWVwKSB7XG5cdHZhciBjaGlsZHJlbiA9IFtdO1xuXG5cdGlmIChkYXRhLmNoaWxkcmVuKSB7XG5cdCAgICBmb3IgKHZhciBpPTA7IGk8ZGF0YS5jaGlsZHJlbi5sZW5ndGg7IGkrKykge1xuXHRcdGNoaWxkcmVuLnB1c2godG50X25vZGUoZGF0YS5jaGlsZHJlbltpXSkpO1xuXHQgICAgfVxuXHR9XG5cdGlmICgoZGF0YS5fY2hpbGRyZW4pICYmIGRlZXApIHtcblx0ICAgIGZvciAodmFyIGo9MDsgajxkYXRhLl9jaGlsZHJlbi5sZW5ndGg7IGorKykge1xuXHRcdGNoaWxkcmVuLnB1c2godG50X25vZGUoZGF0YS5fY2hpbGRyZW5bal0pKTtcblx0ICAgIH1cblx0fVxuXHRpZiAoY2hpbGRyZW4ubGVuZ3RoID09PSAwKSB7XG5cdCAgICByZXR1cm4gdW5kZWZpbmVkO1xuXHR9XG5cdHJldHVybiBjaGlsZHJlbjtcbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKCdwYXJlbnQnLCBmdW5jdGlvbiAoKSB7XG5cdGlmIChkYXRhLl9wYXJlbnQgPT09IHVuZGVmaW5lZCkge1xuXHQgICAgcmV0dXJuIHVuZGVmaW5lZDtcblx0fVxuXHRyZXR1cm4gdG50X25vZGUoZGF0YS5fcGFyZW50KTtcbiAgICB9KTtcblxuICAgIHJldHVybiBub2RlO1xuXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IGV4cG9ydHMgPSB0bnRfbm9kZTtcblxuIiwidmFyIGFwaWpzID0gcmVxdWlyZSgndG50LmFwaScpO1xudmFyIHRyZWUgPSB7fTtcblxudHJlZS5kaWFnb25hbCA9IGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgZCA9IGZ1bmN0aW9uIChkaWFnb25hbFBhdGgpIHtcbiAgICAgICAgdmFyIHNvdXJjZSA9IGRpYWdvbmFsUGF0aC5zb3VyY2U7XG4gICAgICAgIHZhciB0YXJnZXQgPSBkaWFnb25hbFBhdGgudGFyZ2V0O1xuICAgICAgICB2YXIgbWlkcG9pbnRYID0gKHNvdXJjZS54ICsgdGFyZ2V0LngpIC8gMjtcbiAgICAgICAgdmFyIG1pZHBvaW50WSA9IChzb3VyY2UueSArIHRhcmdldC55KSAvIDI7XG4gICAgICAgIHZhciBwYXRoRGF0YSA9IFtzb3VyY2UsIHt4OiB0YXJnZXQueCwgeTogc291cmNlLnl9LCB0YXJnZXRdO1xuICAgICAgICBwYXRoRGF0YSA9IHBhdGhEYXRhLm1hcChkLnByb2plY3Rpb24oKSk7XG4gICAgICAgIHJldHVybiBkLnBhdGgoKShwYXRoRGF0YSwgcmFkaWFsX2NhbGMuY2FsbCh0aGlzLHBhdGhEYXRhKSk7XG4gICAgfTtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAoZClcbiAgICBcdC5nZXRzZXQgKCdwcm9qZWN0aW9uJylcbiAgICBcdC5nZXRzZXQgKCdwYXRoJyk7XG5cbiAgICB2YXIgY29vcmRpbmF0ZVRvQW5nbGUgPSBmdW5jdGlvbiAoY29vcmQsIHJhZGl1cykge1xuICAgICAgXHR2YXIgd2hvbGVBbmdsZSA9IDIgKiBNYXRoLlBJLFxuICAgICAgICBxdWFydGVyQW5nbGUgPSB3aG9sZUFuZ2xlIC8gNDtcblxuICAgICAgXHR2YXIgY29vcmRRdWFkID0gY29vcmRbMF0gPj0gMCA/IChjb29yZFsxXSA+PSAwID8gMSA6IDIpIDogKGNvb3JkWzFdID49IDAgPyA0IDogMyksXG4gICAgICAgIGNvb3JkQmFzZUFuZ2xlID0gTWF0aC5hYnMoTWF0aC5hc2luKGNvb3JkWzFdIC8gcmFkaXVzKSk7XG5cbiAgICAgIFx0Ly8gU2luY2UgdGhpcyBpcyBqdXN0IGJhc2VkIG9uIHRoZSBhbmdsZSBvZiB0aGUgcmlnaHQgdHJpYW5nbGUgZm9ybWVkXG4gICAgICBcdC8vIGJ5IHRoZSBjb29yZGluYXRlIGFuZCB0aGUgb3JpZ2luLCBlYWNoIHF1YWQgd2lsbCBoYXZlIGRpZmZlcmVudFxuICAgICAgXHQvLyBvZmZzZXRzXG4gICAgICBcdHZhciBjb29yZEFuZ2xlO1xuICAgICAgXHRzd2l0Y2ggKGNvb3JkUXVhZCkge1xuICAgICAgXHRjYXNlIDE6XG4gICAgICBcdCAgICBjb29yZEFuZ2xlID0gcXVhcnRlckFuZ2xlIC0gY29vcmRCYXNlQW5nbGU7XG4gICAgICBcdCAgICBicmVhaztcbiAgICAgIFx0Y2FzZSAyOlxuICAgICAgXHQgICAgY29vcmRBbmdsZSA9IHF1YXJ0ZXJBbmdsZSArIGNvb3JkQmFzZUFuZ2xlO1xuICAgICAgXHQgICAgYnJlYWs7XG4gICAgICBcdGNhc2UgMzpcbiAgICAgIFx0ICAgIGNvb3JkQW5nbGUgPSAyKnF1YXJ0ZXJBbmdsZSArIHF1YXJ0ZXJBbmdsZSAtIGNvb3JkQmFzZUFuZ2xlO1xuICAgICAgXHQgICAgYnJlYWs7XG4gICAgICBcdGNhc2UgNDpcbiAgICAgIFx0ICAgIGNvb3JkQW5nbGUgPSAzKnF1YXJ0ZXJBbmdsZSArIGNvb3JkQmFzZUFuZ2xlO1xuICAgICAgXHR9XG4gICAgICBcdHJldHVybiBjb29yZEFuZ2xlO1xuICAgIH07XG5cbiAgICB2YXIgcmFkaWFsX2NhbGMgPSBmdW5jdGlvbiAocGF0aERhdGEpIHtcbiAgICAgICAgdmFyIHNyYyA9IHBhdGhEYXRhWzBdO1xuICAgICAgICB2YXIgbWlkID0gcGF0aERhdGFbMV07XG4gICAgICAgIHZhciBkc3QgPSBwYXRoRGF0YVsyXTtcbiAgICAgICAgdmFyIHJhZGl1cyA9IE1hdGguc3FydChzcmNbMF0qc3JjWzBdICsgc3JjWzFdKnNyY1sxXSk7XG4gICAgICAgIHZhciBzcmNBbmdsZSA9IGNvb3JkaW5hdGVUb0FuZ2xlKHNyYywgcmFkaXVzKTtcbiAgICAgICAgdmFyIG1pZEFuZ2xlID0gY29vcmRpbmF0ZVRvQW5nbGUobWlkLCByYWRpdXMpO1xuICAgICAgICB2YXIgY2xvY2t3aXNlID0gTWF0aC5hYnMobWlkQW5nbGUgLSBzcmNBbmdsZSkgPiBNYXRoLlBJID8gbWlkQW5nbGUgPD0gc3JjQW5nbGUgOiBtaWRBbmdsZSA+IHNyY0FuZ2xlO1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgcmFkaXVzICAgOiByYWRpdXMsXG4gICAgICAgICAgICBjbG9ja3dpc2UgOiBjbG9ja3dpc2VcbiAgICAgICAgfTtcbiAgICB9O1xuXG4gICAgcmV0dXJuIGQ7XG59O1xuXG4vLyB2ZXJ0aWNhbCBkaWFnb25hbCBmb3IgcmVjdCBicmFuY2hlc1xudHJlZS5kaWFnb25hbC52ZXJ0aWNhbCA9IGZ1bmN0aW9uICh1c2VBcmMpIHtcbiAgICB2YXIgcGF0aCA9IGZ1bmN0aW9uKHBhdGhEYXRhLCBvYmopIHtcbiAgICAgICAgdmFyIHNyYyA9IHBhdGhEYXRhWzBdO1xuICAgICAgICB2YXIgbWlkID0gcGF0aERhdGFbMV07XG4gICAgICAgIHZhciBkc3QgPSBwYXRoRGF0YVsyXTtcbiAgICAgICAgdmFyIHJhZGl1cyA9IChtaWRbMV0gLSBzcmNbMV0pICogMjAwMDtcblxuICAgICAgICByZXR1cm4gXCJNXCIgKyBzcmMgKyBcIiBBXCIgKyBbcmFkaXVzLHJhZGl1c10gKyBcIiAwIDAsMCBcIiArIG1pZCArIFwiTVwiICsgbWlkICsgXCJMXCIgKyBkc3Q7XG4gICAgICAgIC8vIHJldHVybiBcIk1cIiArIHNyYyArIFwiIExcIiArIG1pZCArIFwiIExcIiArIGRzdDtcbiAgICB9O1xuXG4gICAgdmFyIHByb2plY3Rpb24gPSBmdW5jdGlvbihkKSB7XG4gICAgICAgIHJldHVybiBbZC55LCBkLnhdO1xuICAgIH07XG5cbiAgICByZXR1cm4gdHJlZS5kaWFnb25hbCgpXG4gICAgICBcdC5wYXRoKHBhdGgpXG4gICAgICBcdC5wcm9qZWN0aW9uKHByb2plY3Rpb24pO1xufTtcblxudHJlZS5kaWFnb25hbC5yYWRpYWwgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIHBhdGggPSBmdW5jdGlvbihwYXRoRGF0YSwgb2JqKSB7XG4gICAgICAgIHZhciBzcmMgPSBwYXRoRGF0YVswXTtcbiAgICAgICAgdmFyIG1pZCA9IHBhdGhEYXRhWzFdO1xuICAgICAgICB2YXIgZHN0ID0gcGF0aERhdGFbMl07XG4gICAgICAgIHZhciByYWRpdXMgPSBvYmoucmFkaXVzO1xuICAgICAgICB2YXIgY2xvY2t3aXNlID0gb2JqLmNsb2Nrd2lzZTtcblxuICAgICAgICBpZiAoY2xvY2t3aXNlKSB7XG4gICAgICAgICAgICByZXR1cm4gXCJNXCIgKyBzcmMgKyBcIiBBXCIgKyBbcmFkaXVzLHJhZGl1c10gKyBcIiAwIDAsMCBcIiArIG1pZCArIFwiTVwiICsgbWlkICsgXCJMXCIgKyBkc3Q7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gXCJNXCIgKyBtaWQgKyBcIiBBXCIgKyBbcmFkaXVzLHJhZGl1c10gKyBcIiAwIDAsMCBcIiArIHNyYyArIFwiTVwiICsgbWlkICsgXCJMXCIgKyBkc3Q7XG4gICAgICAgIH1cbiAgICB9O1xuXG4gICAgdmFyIHByb2plY3Rpb24gPSBmdW5jdGlvbihkKSB7XG4gICAgICBcdHZhciByID0gZC55LCBhID0gKGQueCAtIDkwKSAvIDE4MCAqIE1hdGguUEk7XG4gICAgICBcdHJldHVybiBbciAqIE1hdGguY29zKGEpLCByICogTWF0aC5zaW4oYSldO1xuICAgIH07XG5cbiAgICByZXR1cm4gdHJlZS5kaWFnb25hbCgpXG4gICAgICBcdC5wYXRoKHBhdGgpXG4gICAgICBcdC5wcm9qZWN0aW9uKHByb2plY3Rpb24pO1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gdHJlZS5kaWFnb25hbDtcbiIsInZhciB0cmVlID0gcmVxdWlyZSAoXCIuL3RyZWUuanNcIik7XG50cmVlLmxhYmVsID0gcmVxdWlyZShcIi4vbGFiZWwuanNcIik7XG50cmVlLmRpYWdvbmFsID0gcmVxdWlyZShcIi4vZGlhZ29uYWwuanNcIik7XG50cmVlLmxheW91dCA9IHJlcXVpcmUoXCIuL2xheW91dC5qc1wiKTtcbnRyZWUubm9kZV9kaXNwbGF5ID0gcmVxdWlyZShcIi4vbm9kZV9kaXNwbGF5LmpzXCIpO1xuLy8gdHJlZS5ub2RlID0gcmVxdWlyZShcInRudC50cmVlLm5vZGVcIik7XG4vLyB0cmVlLnBhcnNlX25ld2ljayA9IHJlcXVpcmUoXCJ0bnQubmV3aWNrXCIpLnBhcnNlX25ld2ljaztcbi8vIHRyZWUucGFyc2Vfbmh4ID0gcmVxdWlyZShcInRudC5uZXdpY2tcIikucGFyc2Vfbmh4O1xuXG5tb2R1bGUuZXhwb3J0cyA9IGV4cG9ydHMgPSB0cmVlO1xuXG4iLCJ2YXIgYXBpanMgPSByZXF1aXJlKFwidG50LmFwaVwiKTtcbnZhciB0cmVlID0ge307XG5cbnRyZWUubGFiZWwgPSBmdW5jdGlvbiAoKSB7XG4gICAgXCJ1c2Ugc3RyaWN0XCI7XG5cbiAgICB2YXIgZGlzcGF0Y2ggPSBkMy5kaXNwYXRjaCAoXCJjbGlja1wiLCBcImRibGNsaWNrXCIsIFwibW91c2VvdmVyXCIsIFwibW91c2VvdXRcIilcblxuICAgIC8vIFRPRE86IE5vdCBzdXJlIGlmIHdlIHNob3VsZCBiZSByZW1vdmluZyBieSBkZWZhdWx0IHByZXYgbGFiZWxzXG4gICAgLy8gb3IgaXQgd291bGQgYmUgYmV0dGVyIHRvIGhhdmUgYSBzZXBhcmF0ZSByZW1vdmUgbWV0aG9kIGNhbGxlZCBieSB0aGUgdmlzXG4gICAgLy8gb24gdXBkYXRlXG4gICAgLy8gV2UgYWxzbyBoYXZlIHRoZSBwcm9ibGVtIHRoYXQgd2UgbWF5IGJlIHRyYW5zaXRpb25pbmcgZnJvbVxuICAgIC8vIHRleHQgdG8gaW1nIGxhYmVscyBhbmQgd2UgbmVlZCB0byByZW1vdmUgdGhlIGxhYmVsIG9mIGEgZGlmZmVyZW50IHR5cGVcbiAgICB2YXIgbGFiZWwgPSBmdW5jdGlvbiAobm9kZSwgbGF5b3V0X3R5cGUsIG5vZGVfc2l6ZSkge1xuICAgICAgICBpZiAodHlwZW9mIChub2RlKSAhPT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICAgICAgdGhyb3cobm9kZSk7XG4gICAgICAgIH1cblxuICAgICAgICBsYWJlbC5kaXNwbGF5KCkuY2FsbCh0aGlzLCBub2RlLCBsYXlvdXRfdHlwZSlcbiAgICAgICAgICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfdHJlZV9sYWJlbFwiKVxuICAgICAgICAgICAgLmF0dHIoXCJ0cmFuc2Zvcm1cIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgICAgICB2YXIgdCA9IGxhYmVsLnRyYW5zZm9ybSgpKG5vZGUsIGxheW91dF90eXBlKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gXCJ0cmFuc2xhdGUgKFwiICsgKHQudHJhbnNsYXRlWzBdICsgbm9kZV9zaXplKSArIFwiIFwiICsgdC50cmFuc2xhdGVbMV0gKyBcIilyb3RhdGUoXCIgKyB0LnJvdGF0ZSArIFwiKVwiO1xuICAgICAgICAgICAgfSlcbiAgICAgICAgLy8gVE9ETzogdGhpcyBjbGljayBldmVudCBpcyBwcm9iYWJseSBuZXZlciBmaXJlZCBzaW5jZSB0aGVyZSBpcyBhbiBvbmNsaWNrIGV2ZW50IGluIHRoZSBub2RlIGcgZWxlbWVudD9cbiAgICAgICAgICAgIC5vbihcImNsaWNrXCIsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICBkaXNwYXRjaC5jbGljay5jYWxsKHRoaXMsIG5vZGUpXG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLm9uKFwiZGJsY2xpY2tcIiwgZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgICAgIGRpc3BhdGNoLmRibGNsaWNrLmNhbGwodGhpcywgbm9kZSlcbiAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAub24oXCJtb3VzZW92ZXJcIiwgZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgICAgIGRpc3BhdGNoLm1vdXNlb3Zlci5jYWxsKHRoaXMsIG5vZGUpXG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLm9uKFwibW91c2VvdXRcIiwgZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgICAgIGRpc3BhdGNoLm1vdXNlb3V0LmNhbGwodGhpcywgbm9kZSlcbiAgICAgICAgICAgIH0pXG4gICAgfTtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAobGFiZWwpXG4gICAgICAgIC5nZXRzZXQgKCd3aWR0aCcsIGZ1bmN0aW9uICgpIHsgdGhyb3cgXCJOZWVkIGEgd2lkdGggY2FsbGJhY2tcIiB9KVxuICAgICAgICAuZ2V0c2V0ICgnaGVpZ2h0JywgZnVuY3Rpb24gKCkgeyB0aHJvdyBcIk5lZWQgYSBoZWlnaHQgY2FsbGJhY2tcIiB9KVxuICAgICAgICAuZ2V0c2V0ICgnZGlzcGxheScsIGZ1bmN0aW9uICgpIHsgdGhyb3cgXCJOZWVkIGEgZGlzcGxheSBjYWxsYmFja1wiIH0pXG4gICAgICAgIC5nZXRzZXQgKCd0cmFuc2Zvcm0nLCBmdW5jdGlvbiAoKSB7IHRocm93IFwiTmVlZCBhIHRyYW5zZm9ybSBjYWxsYmFja1wiIH0pXG4gICAgICAgIC8vLmdldHNldCAoJ29uX2NsaWNrJyk7XG5cbiAgICByZXR1cm4gZDMucmViaW5kIChsYWJlbCwgZGlzcGF0Y2gsIFwib25cIik7XG59O1xuXG4vLyBUZXh0IGJhc2VkIGxhYmVsc1xudHJlZS5sYWJlbC50ZXh0ID0gZnVuY3Rpb24gKCkge1xuICAgIHZhciBsYWJlbCA9IHRyZWUubGFiZWwoKTtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAobGFiZWwpXG4gICAgICAgIC5nZXRzZXQgKCdmb250c2l6ZScsIDEwKVxuICAgICAgICAuZ2V0c2V0ICgnZm9udHdlaWdodCcsIFwibm9ybWFsXCIpXG4gICAgICAgIC5nZXRzZXQgKCdjb2xvcicsIFwiIzAwMFwiKVxuICAgICAgICAuZ2V0c2V0ICgndGV4dCcsIGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICByZXR1cm4gZC5kYXRhKCkubmFtZTtcbiAgICAgICAgfSlcblxuICAgIGxhYmVsLmRpc3BsYXkgKGZ1bmN0aW9uIChub2RlLCBsYXlvdXRfdHlwZSkge1xuICAgICAgICB2YXIgbCA9IGQzLnNlbGVjdCh0aGlzKVxuICAgICAgICAgICAgLmFwcGVuZChcInRleHRcIilcbiAgICAgICAgICAgIC5hdHRyKFwidGV4dC1hbmNob3JcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgICAgICBpZiAobGF5b3V0X3R5cGUgPT09IFwicmFkaWFsXCIpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIChkLnglMzYwIDwgMTgwKSA/IFwic3RhcnRcIiA6IFwiZW5kXCI7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHJldHVybiBcInN0YXJ0XCI7XG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLnRleHQoZnVuY3Rpb24oKXtcbiAgICAgICAgICAgICAgICByZXR1cm4gbGFiZWwudGV4dCgpKG5vZGUpXG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLnN0eWxlKCdmb250LXNpemUnLCBmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIGQzLmZ1bmN0b3IobGFiZWwuZm9udHNpemUoKSkobm9kZSkgKyBcInB4XCI7XG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLnN0eWxlKCdmb250LXdlaWdodCcsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihsYWJlbC5mb250d2VpZ2h0KCkpKG5vZGUpO1xuICAgICAgICAgICAgfSlcbiAgICAgICAgICAgIC5zdHlsZSgnZmlsbCcsIGQzLmZ1bmN0b3IobGFiZWwuY29sb3IoKSkobm9kZSkpO1xuXG4gICAgICAgIHJldHVybiBsO1xuICAgIH0pO1xuXG4gICAgbGFiZWwudHJhbnNmb3JtIChmdW5jdGlvbiAobm9kZSwgbGF5b3V0X3R5cGUpIHtcbiAgICAgICAgdmFyIGQgPSBub2RlLmRhdGEoKTtcbiAgICAgICAgdmFyIHQgPSB7XG4gICAgICAgICAgICB0cmFuc2xhdGUgOiBbNSwgNV0sXG4gICAgICAgICAgICByb3RhdGUgOiAwXG4gICAgICAgIH07XG4gICAgICAgIGlmIChsYXlvdXRfdHlwZSA9PT0gXCJyYWRpYWxcIikge1xuICAgICAgICAgICAgdC50cmFuc2xhdGVbMV0gPSB0LnRyYW5zbGF0ZVsxXSAtIChkLnglMzYwIDwgMTgwID8gMCA6IGxhYmVsLmZvbnRzaXplKCkpXG4gICAgICAgICAgICB0LnJvdGF0ZSA9IChkLnglMzYwIDwgMTgwID8gMCA6IDE4MClcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gdDtcbiAgICB9KTtcblxuXG4gICAgLy8gbGFiZWwudHJhbnNmb3JtIChmdW5jdGlvbiAobm9kZSkge1xuICAgIC8vIFx0dmFyIGQgPSBub2RlLmRhdGEoKTtcbiAgICAvLyBcdHJldHVybiBcInRyYW5zbGF0ZSgxMCA1KXJvdGF0ZShcIiArIChkLnglMzYwIDwgMTgwID8gMCA6IDE4MCkgKyBcIilcIjtcbiAgICAvLyB9KTtcblxuICAgIGxhYmVsLndpZHRoIChmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICB2YXIgc3ZnID0gZDMuc2VsZWN0KFwiYm9keVwiKVxuICAgICAgICAgICAgLmFwcGVuZChcInN2Z1wiKVxuICAgICAgICAgICAgLmF0dHIoXCJoZWlnaHRcIiwgMClcbiAgICAgICAgICAgIC5zdHlsZSgndmlzaWJpbGl0eScsICdoaWRkZW4nKTtcblxuICAgICAgICB2YXIgdGV4dCA9IHN2Z1xuICAgICAgICAgICAgLmFwcGVuZChcInRleHRcIilcbiAgICAgICAgICAgIC5zdHlsZSgnZm9udC1zaXplJywgZDMuZnVuY3RvcihsYWJlbC5mb250c2l6ZSgpKShub2RlKSArIFwicHhcIilcbiAgICAgICAgICAgIC50ZXh0KGxhYmVsLnRleHQoKShub2RlKSk7XG5cbiAgICAgICAgdmFyIHdpZHRoID0gdGV4dC5ub2RlKCkuZ2V0QkJveCgpLndpZHRoO1xuICAgICAgICBzdmcucmVtb3ZlKCk7XG5cbiAgICAgICAgcmV0dXJuIHdpZHRoO1xuICAgIH0pO1xuXG4gICAgbGFiZWwuaGVpZ2h0IChmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihsYWJlbC5mb250c2l6ZSgpKShub2RlKTtcbiAgICB9KTtcblxuICAgIHJldHVybiBsYWJlbDtcbn07XG5cbi8vIEltYWdlIGJhc2VkIGxhYmVsc1xudHJlZS5sYWJlbC5pbWcgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIGxhYmVsID0gdHJlZS5sYWJlbCgpO1xuXG4gICAgdmFyIGFwaSA9IGFwaWpzIChsYWJlbClcbiAgICAgICAgLmdldHNldCAoJ3NyYycsIGZ1bmN0aW9uICgpIHt9KVxuXG4gICAgbGFiZWwuZGlzcGxheSAoZnVuY3Rpb24gKG5vZGUsIGxheW91dF90eXBlKSB7XG4gICAgICAgIGlmIChsYWJlbC5zcmMoKShub2RlKSkge1xuICAgICAgICAgICAgdmFyIGwgPSBkMy5zZWxlY3QodGhpcylcbiAgICAgICAgICAgICAgICAuYXBwZW5kKFwiaW1hZ2VcIilcbiAgICAgICAgICAgICAgICAuYXR0cihcIndpZHRoXCIsIGxhYmVsLndpZHRoKCkoKSlcbiAgICAgICAgICAgICAgICAuYXR0cihcImhlaWdodFwiLCBsYWJlbC5oZWlnaHQoKSgpKVxuICAgICAgICAgICAgICAgIC5hdHRyKFwieGxpbms6aHJlZlwiLCBsYWJlbC5zcmMoKShub2RlKSk7XG4gICAgICAgICAgICByZXR1cm4gbDtcbiAgICAgICAgfVxuICAgICAgICAvLyBmYWxsYmFjayB0ZXh0IGluIGNhc2UgdGhlIGltZyBpcyBub3QgZm91bmQ/XG4gICAgICAgIHJldHVybiBkMy5zZWxlY3QodGhpcylcbiAgICAgICAgICAgIC5hcHBlbmQoXCJ0ZXh0XCIpXG4gICAgICAgICAgICAudGV4dChcIlwiKTtcbiAgICB9KTtcblxuICAgIGxhYmVsLnRyYW5zZm9ybSAoZnVuY3Rpb24gKG5vZGUsIGxheW91dF90eXBlKSB7XG4gICAgICAgIHZhciBkID0gbm9kZS5kYXRhKCk7XG4gICAgICAgIHZhciB0ID0ge1xuICAgICAgICAgICAgdHJhbnNsYXRlIDogWzEwLCAoLWxhYmVsLmhlaWdodCgpKCkgLyAyKV0sXG4gICAgICAgICAgICByb3RhdGUgOiAwXG4gICAgICAgIH07XG5cbiAgICAgICAgaWYgKGxheW91dF90eXBlID09PSAncmFkaWFsJykge1xuICAgICAgICAgICAgdC50cmFuc2xhdGVbMF0gPSB0LnRyYW5zbGF0ZVswXSArIChkLnglMzYwIDwgMTgwID8gMCA6IGxhYmVsLndpZHRoKCkoKSksXG4gICAgICAgICAgICB0LnRyYW5zbGF0ZVsxXSA9IHQudHJhbnNsYXRlWzFdICsgKGQueCUzNjAgPCAxODAgPyAwIDogbGFiZWwuaGVpZ2h0KCkoKSksXG4gICAgICAgICAgICB0LnJvdGF0ZSA9IChkLnglMzYwIDwgMTgwID8gMCA6IDE4MClcbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiB0O1xuICAgIH0pO1xuXG4gICAgcmV0dXJuIGxhYmVsO1xufTtcblxuLy8gTGFiZWxzIG1hZGUgb2YgMisgc2ltcGxlIGxhYmVsc1xudHJlZS5sYWJlbC5jb21wb3NpdGUgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIGxhYmVscyA9IFtdO1xuXG4gICAgdmFyIGxhYmVsID0gZnVuY3Rpb24gKG5vZGUsIGxheW91dF90eXBlLCBub2RlX3NpemUpIHtcbiAgICAgICAgdmFyIGN1cnJfeG9mZnNldCA9IDA7XG5cbiAgICAgICAgZm9yICh2YXIgaT0wOyBpPGxhYmVscy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgdmFyIGRpc3BsYXkgPSBsYWJlbHNbaV07XG5cbiAgICAgICAgICAgIChmdW5jdGlvbiAob2Zmc2V0KSB7XG4gICAgICAgICAgICAgICAgZGlzcGxheS50cmFuc2Zvcm0gKGZ1bmN0aW9uIChub2RlLCBsYXlvdXRfdHlwZSkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgdHN1cGVyID0gZGlzcGxheS5fc3VwZXJfLnRyYW5zZm9ybSgpKG5vZGUsIGxheW91dF90eXBlKTtcbiAgICAgICAgICAgICAgICAgICAgdmFyIHQgPSB7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cmFuc2xhdGUgOiBbb2Zmc2V0ICsgdHN1cGVyLnRyYW5zbGF0ZVswXSwgdHN1cGVyLnRyYW5zbGF0ZVsxXV0sXG4gICAgICAgICAgICAgICAgICAgICAgICByb3RhdGUgOiB0c3VwZXIucm90YXRlXG4gICAgICAgICAgICAgICAgICAgIH07XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiB0O1xuICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICB9KShjdXJyX3hvZmZzZXQpO1xuXG4gICAgICAgICAgICBjdXJyX3hvZmZzZXQgKz0gMTA7XG4gICAgICAgICAgICBjdXJyX3hvZmZzZXQgKz0gZGlzcGxheS53aWR0aCgpKG5vZGUpO1xuXG4gICAgICAgICAgICBkaXNwbGF5LmNhbGwodGhpcywgbm9kZSwgbGF5b3V0X3R5cGUsIG5vZGVfc2l6ZSk7XG4gICAgICAgIH1cbiAgICB9O1xuXG4gICAgdmFyIGFwaSA9IGFwaWpzIChsYWJlbClcblxuICAgIGFwaS5tZXRob2QgKCdhZGRfbGFiZWwnLCBmdW5jdGlvbiAoZGlzcGxheSwgbm9kZSkge1xuICAgICAgICBkaXNwbGF5Ll9zdXBlcl8gPSB7fTtcbiAgICAgICAgYXBpanMgKGRpc3BsYXkuX3N1cGVyXylcbiAgICAgICAgICAgIC5nZXQgKCd0cmFuc2Zvcm0nLCBkaXNwbGF5LnRyYW5zZm9ybSgpKTtcblxuICAgICAgICBsYWJlbHMucHVzaChkaXNwbGF5KTtcbiAgICAgICAgcmV0dXJuIGxhYmVsO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCAoJ3dpZHRoJywgZnVuY3Rpb24gKCkge1xuICAgICAgICByZXR1cm4gZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgICAgIHZhciB0b3Rfd2lkdGggPSAwO1xuICAgICAgICAgICAgZm9yICh2YXIgaT0wOyBpPGxhYmVscy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgICAgIHRvdF93aWR0aCArPSBwYXJzZUludChsYWJlbHNbaV0ud2lkdGgoKShub2RlKSk7XG4gICAgICAgICAgICAgICAgdG90X3dpZHRoICs9IHBhcnNlSW50KGxhYmVsc1tpXS5fc3VwZXJfLnRyYW5zZm9ybSgpKG5vZGUpLnRyYW5zbGF0ZVswXSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiB0b3Rfd2lkdGg7XG4gICAgICAgIH1cbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKCdoZWlnaHQnLCBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHJldHVybiBmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICAgICAgdmFyIG1heF9oZWlnaHQgPSAwO1xuICAgICAgICAgICAgZm9yICh2YXIgaT0wOyBpPGxhYmVscy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgICAgIHZhciBjdXJyX2hlaWdodCA9IGxhYmVsc1tpXS5oZWlnaHQoKShub2RlKTtcbiAgICAgICAgICAgICAgICBpZiAoIGN1cnJfaGVpZ2h0ID4gbWF4X2hlaWdodCkge1xuICAgICAgICAgICAgICAgICAgICBtYXhfaGVpZ2h0ID0gY3Vycl9oZWlnaHQ7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIG1heF9oZWlnaHQ7XG4gICAgICAgIH1cbiAgICB9KTtcblxuICAgIHJldHVybiBsYWJlbDtcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gZXhwb3J0cyA9IHRyZWUubGFiZWw7XG4iLCIvLyBCYXNlZCBvbiB0aGUgY29kZSBieSBLZW4taWNoaSBVZWRhIGluIGh0dHA6Ly9ibC5vY2tzLm9yZy9rdWVkYS8xMDM2Nzc2I2QzLnBoeWxvZ3JhbS5qc1xuXG52YXIgYXBpanMgPSByZXF1aXJlKFwidG50LmFwaVwiKTtcbnZhciBkaWFnb25hbCA9IHJlcXVpcmUoXCIuL2RpYWdvbmFsLmpzXCIpO1xudmFyIHRyZWUgPSB7fTtcblxudHJlZS5sYXlvdXQgPSBmdW5jdGlvbiAoKSB7XG5cbiAgICB2YXIgbCA9IGZ1bmN0aW9uICgpIHtcbiAgICB9O1xuXG4gICAgdmFyIGNsdXN0ZXIgPSBkMy5sYXlvdXQuY2x1c3RlcigpXG4gICAgXHQuc29ydChudWxsKVxuICAgIFx0LnZhbHVlKGZ1bmN0aW9uIChkKSB7cmV0dXJuIGQubGVuZ3RoO30gKVxuICAgIFx0LnNlcGFyYXRpb24oZnVuY3Rpb24gKCkge3JldHVybiAxO30pO1xuXG4gICAgdmFyIGFwaSA9IGFwaWpzIChsKVxuICAgIFx0LmdldHNldCAoJ3NjYWxlJywgdHJ1ZSlcbiAgICBcdC5nZXRzZXQgKCdtYXhfbGVhZl9sYWJlbF93aWR0aCcsIDApXG4gICAgXHQubWV0aG9kIChcImNsdXN0ZXJcIiwgY2x1c3RlcilcbiAgICBcdC5tZXRob2QoJ3lzY2FsZScsIGZ1bmN0aW9uICgpIHt0aHJvdyBcInlzY2FsZSBpcyBub3QgZGVmaW5lZCBpbiB0aGUgYmFzZSBvYmplY3RcIjt9KVxuICAgIFx0Lm1ldGhvZCgnYWRqdXN0X2NsdXN0ZXJfc2l6ZScsIGZ1bmN0aW9uICgpIHt0aHJvdyBcImFkanVzdF9jbHVzdGVyX3NpemUgaXMgbm90IGRlZmluZWQgaW4gdGhlIGJhc2Ugb2JqZWN0XCI7IH0pXG4gICAgXHQubWV0aG9kKCd3aWR0aCcsIGZ1bmN0aW9uICgpIHt0aHJvdyBcIndpZHRoIGlzIG5vdCBkZWZpbmVkIGluIHRoZSBiYXNlIG9iamVjdFwiO30pXG4gICAgXHQubWV0aG9kKCdoZWlnaHQnLCBmdW5jdGlvbiAoKSB7dGhyb3cgXCJoZWlnaHQgaXMgbm90IGRlZmluZWQgaW4gdGhlIGJhc2Ugb2JqZWN0XCI7fSk7XG5cbiAgICBhcGkubWV0aG9kKCdzY2FsZV9icmFuY2hfbGVuZ3RocycsIGZ1bmN0aW9uIChjdXJyKSB7XG4gICAgXHRpZiAobC5zY2FsZSgpID09PSBmYWxzZSkge1xuICAgIFx0ICAgIHJldHVybjtcbiAgICBcdH1cblxuICAgIFx0dmFyIG5vZGVzID0gY3Vyci5ub2RlcztcbiAgICBcdHZhciB0cmVlID0gY3Vyci50cmVlO1xuXG4gICAgXHR2YXIgcm9vdF9kaXN0cyA9IG5vZGVzLm1hcCAoZnVuY3Rpb24gKGQpIHtcbiAgICBcdCAgICByZXR1cm4gZC5fcm9vdF9kaXN0O1xuICAgIFx0fSk7XG5cbiAgICBcdHZhciB5c2NhbGUgPSBsLnlzY2FsZShyb290X2Rpc3RzKTtcbiAgICBcdHRyZWUuYXBwbHkgKGZ1bmN0aW9uIChub2RlKSB7XG4gICAgXHQgICAgbm9kZS5wcm9wZXJ0eShcInlcIiwgeXNjYWxlKG5vZGUucm9vdF9kaXN0KCkpKTtcbiAgICBcdH0pO1xuICAgIH0pO1xuXG4gICAgcmV0dXJuIGw7XG59O1xuXG50cmVlLmxheW91dC52ZXJ0aWNhbCA9IGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgbGF5b3V0ID0gdHJlZS5sYXlvdXQoKTtcbiAgICAvLyBFbGVtZW50cyBsaWtlICdsYWJlbHMnIGRlcGVuZCBvbiB0aGUgbGF5b3V0IHR5cGUuIFRoaXMgZXhwb3NlcyBhIHdheSBvZiBpZGVudGlmeWluZyB0aGUgbGF5b3V0IHR5cGVcbiAgICBsYXlvdXQudHlwZSA9IFwidmVydGljYWxcIjtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAobGF5b3V0KVxuICAgIFx0LmdldHNldCAoJ3dpZHRoJywgMzYwKVxuICAgIFx0LmdldCAoJ3RyYW5zbGF0ZV92aXMnLCBbMjAsMjBdKVxuICAgIFx0Lm1ldGhvZCAoJ2RpYWdvbmFsJywgZGlhZ29uYWwudmVydGljYWwpXG4gICAgXHQubWV0aG9kICgndHJhbnNmb3JtX25vZGUnLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICBcdCAgICByZXR1cm4gXCJ0cmFuc2xhdGUoXCIgKyBkLnkgKyBcIixcIiArIGQueCArIFwiKVwiO1xuICAgIFx0fSk7XG5cbiAgICBhcGkubWV0aG9kKCdoZWlnaHQnLCBmdW5jdGlvbiAocGFyYW1zKSB7XG4gICAgXHRyZXR1cm4gKHBhcmFtcy5uX2xlYXZlcyAqIHBhcmFtcy5sYWJlbF9oZWlnaHQpO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCgneXNjYWxlJywgZnVuY3Rpb24gKGRpc3RzKSB7XG4gICAgXHRyZXR1cm4gZDMuc2NhbGUubGluZWFyKClcbiAgICBcdCAgICAuZG9tYWluKFswLCBkMy5tYXgoZGlzdHMpXSlcbiAgICBcdCAgICAucmFuZ2UoWzAsIGxheW91dC53aWR0aCgpIC0gMjAgLSBsYXlvdXQubWF4X2xlYWZfbGFiZWxfd2lkdGgoKV0pO1xuICAgIH0pO1xuXG4gICAgYXBpLm1ldGhvZCgnYWRqdXN0X2NsdXN0ZXJfc2l6ZScsIGZ1bmN0aW9uIChwYXJhbXMpIHtcbiAgICBcdHZhciBoID0gbGF5b3V0LmhlaWdodChwYXJhbXMpO1xuICAgIFx0dmFyIHcgPSBsYXlvdXQud2lkdGgoKSAtIGxheW91dC5tYXhfbGVhZl9sYWJlbF93aWR0aCgpIC0gbGF5b3V0LnRyYW5zbGF0ZV92aXMoKVswXSAtIHBhcmFtcy5sYWJlbF9wYWRkaW5nO1xuICAgIFx0bGF5b3V0LmNsdXN0ZXIuc2l6ZSAoW2gsd10pO1xuICAgIFx0cmV0dXJuIGxheW91dDtcbiAgICB9KTtcblxuICAgIHJldHVybiBsYXlvdXQ7XG59O1xuXG50cmVlLmxheW91dC5yYWRpYWwgPSBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIGxheW91dCA9IHRyZWUubGF5b3V0KCk7XG4gICAgLy8gRWxlbWVudHMgbGlrZSAnbGFiZWxzJyBkZXBlbmQgb24gdGhlIGxheW91dCB0eXBlLiBUaGlzIGV4cG9zZXMgYSB3YXkgb2YgaWRlbnRpZnlpbmcgdGhlIGxheW91dCB0eXBlXG4gICAgbGF5b3V0LnR5cGUgPSAncmFkaWFsJztcblxuICAgIHZhciBkZWZhdWx0X3dpZHRoID0gMzYwO1xuICAgIHZhciByID0gZGVmYXVsdF93aWR0aCAvIDI7XG5cbiAgICB2YXIgY29uZiA9IHtcbiAgICBcdHdpZHRoIDogMzYwXG4gICAgfTtcblxuICAgIHZhciBhcGkgPSBhcGlqcyAobGF5b3V0KVxuICAgIFx0LmdldHNldCAoY29uZilcbiAgICBcdC5nZXRzZXQgKCd0cmFuc2xhdGVfdmlzJywgW3IsIHJdKSAvLyBUT0RPOiAxLjMgc2hvdWxkIGJlIHJlcGxhY2VkIGJ5IGEgc2Vuc2libGUgdmFsdWVcbiAgICBcdC5tZXRob2QgKCd0cmFuc2Zvcm1fbm9kZScsIGZ1bmN0aW9uIChkKSB7XG4gICAgXHQgICAgcmV0dXJuIFwicm90YXRlKFwiICsgKGQueCAtIDkwKSArIFwiKXRyYW5zbGF0ZShcIiArIGQueSArIFwiKVwiO1xuICAgIFx0fSlcbiAgICBcdC5tZXRob2QgKCdkaWFnb25hbCcsIGRpYWdvbmFsLnJhZGlhbClcbiAgICBcdC5tZXRob2QgKCdoZWlnaHQnLCBmdW5jdGlvbiAoKSB7IHJldHVybiBjb25mLndpZHRoOyB9KTtcblxuICAgIC8vIENoYW5nZXMgaW4gd2lkdGggYWZmZWN0IGNoYW5nZXMgaW4gclxuICAgIGxheW91dC53aWR0aC50cmFuc2Zvcm0gKGZ1bmN0aW9uICh2YWwpIHtcbiAgICBcdHIgPSB2YWwgLyAyO1xuICAgIFx0bGF5b3V0LmNsdXN0ZXIuc2l6ZShbMzYwLCByXSk7XG4gICAgXHRsYXlvdXQudHJhbnNsYXRlX3Zpcyhbciwgcl0pO1xuICAgIFx0cmV0dXJuIHZhbDtcbiAgICB9KTtcblxuICAgIGFwaS5tZXRob2QgKFwieXNjYWxlXCIsICBmdW5jdGlvbiAoZGlzdHMpIHtcblx0cmV0dXJuIGQzLnNjYWxlLmxpbmVhcigpXG5cdCAgICAuZG9tYWluKFswLGQzLm1heChkaXN0cyldKVxuXHQgICAgLnJhbmdlKFswLCByXSk7XG4gICAgfSk7XG5cbiAgICBhcGkubWV0aG9kIChcImFkanVzdF9jbHVzdGVyX3NpemVcIiwgZnVuY3Rpb24gKHBhcmFtcykge1xuICAgIFx0ciA9IChsYXlvdXQud2lkdGgoKS8yKSAtIGxheW91dC5tYXhfbGVhZl9sYWJlbF93aWR0aCgpIC0gMjA7XG4gICAgXHRsYXlvdXQuY2x1c3Rlci5zaXplKFszNjAsIHJdKTtcbiAgICBcdHJldHVybiBsYXlvdXQ7XG4gICAgfSk7XG5cbiAgICByZXR1cm4gbGF5b3V0O1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gdHJlZS5sYXlvdXQ7XG4iLCJ2YXIgYXBpanMgPSByZXF1aXJlKFwidG50LmFwaVwiKTtcbnZhciB0cmVlID0ge307XG5cbnRyZWUubm9kZV9kaXNwbGF5ID0gZnVuY3Rpb24gKCkge1xuICAgIFwidXNlIHN0cmljdFwiO1xuXG4gICAgdmFyIG4gPSBmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICB2YXIgcHJveHk7XG4gICAgICAgIHZhciB0aGlzUHJveHkgPSBkMy5zZWxlY3QodGhpcykuc2VsZWN0KFwiLnRudF90cmVlX25vZGVfcHJveHlcIik7XG4gICAgICAgIGlmICh0aGlzUHJveHlbMF1bMF0gPT09IG51bGwpIHtcbiAgICAgICAgICAgIHZhciBzaXplID0gZDMuZnVuY3RvcihuLnNpemUoKSkobm9kZSk7XG4gICAgICAgICAgICBwcm94eSA9IGQzLnNlbGVjdCh0aGlzKVxuICAgICAgICAgICAgICAgIC5hcHBlbmQoXCJyZWN0XCIpXG4gICAgICAgICAgICAgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF90cmVlX25vZGVfcHJveHlcIik7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBwcm94eSA9IHRoaXNQcm94eTtcbiAgICAgICAgfVxuXG4gICAgXHRuLmRpc3BsYXkoKS5jYWxsKHRoaXMsIG5vZGUpO1xuICAgICAgICB2YXIgZGltID0gdGhpcy5nZXRCQm94KCk7XG4gICAgICAgIHByb3h5XG4gICAgICAgICAgICAuYXR0cihcInhcIiwgZGltLngpXG4gICAgICAgICAgICAuYXR0cihcInlcIiwgZGltLnkpXG4gICAgICAgICAgICAuYXR0cihcIndpZHRoXCIsIGRpbS53aWR0aClcbiAgICAgICAgICAgIC5hdHRyKFwiaGVpZ2h0XCIsIGRpbS5oZWlnaHQpO1xuICAgIH07XG5cbiAgICB2YXIgYXBpID0gYXBpanMgKG4pXG4gICAgXHQuZ2V0c2V0KFwic2l6ZVwiLCA0LjQpXG4gICAgXHQuZ2V0c2V0KFwiZmlsbFwiLCBcImJsYWNrXCIpXG4gICAgXHQuZ2V0c2V0KFwic3Ryb2tlXCIsIFwiYmxhY2tcIilcbiAgICBcdC5nZXRzZXQoXCJzdHJva2Vfd2lkdGhcIiwgXCIxcHhcIilcbiAgICBcdC5nZXRzZXQoXCJkaXNwbGF5XCIsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHRocm93IFwiZGlzcGxheSBpcyBub3QgZGVmaW5lZCBpbiB0aGUgYmFzZSBvYmplY3RcIjtcbiAgICAgICAgfSk7XG4gICAgYXBpLm1ldGhvZChcInJlc2V0XCIsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgZDMuc2VsZWN0KHRoaXMpXG4gICAgICAgICAgICAuc2VsZWN0QWxsKFwiKjpub3QoLnRudF90cmVlX25vZGVfcHJveHkpXCIpXG4gICAgICAgICAgICAucmVtb3ZlKCk7XG4gICAgfSk7XG5cbiAgICByZXR1cm4gbjtcbn07XG5cbnRyZWUubm9kZV9kaXNwbGF5LmNpcmNsZSA9IGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgbiA9IHRyZWUubm9kZV9kaXNwbGF5KCk7XG5cbiAgICBuLmRpc3BsYXkgKGZ1bmN0aW9uIChub2RlKSB7XG4gICAgXHRkMy5zZWxlY3QodGhpcylcbiAgICAgICAgICAgIC5hcHBlbmQoXCJjaXJjbGVcIilcbiAgICAgICAgICAgIC5hdHRyKFwiclwiLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKG4uc2l6ZSgpKShub2RlKTtcbiAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAuYXR0cihcImZpbGxcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihuLmZpbGwoKSkobm9kZSk7XG4gICAgICAgICAgICB9KVxuICAgICAgICAgICAgLmF0dHIoXCJzdHJva2VcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihuLnN0cm9rZSgpKShub2RlKTtcbiAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAuYXR0cihcInN0cm9rZS13aWR0aFwiLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKG4uc3Ryb2tlX3dpZHRoKCkpKG5vZGUpO1xuICAgICAgICAgICAgfSlcbiAgICAgICAgICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfbm9kZV9kaXNwbGF5X2VsZW1cIik7XG4gICAgfSk7XG5cbiAgICByZXR1cm4gbjtcbn07XG5cbnRyZWUubm9kZV9kaXNwbGF5LnNxdWFyZSA9IGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgbiA9IHRyZWUubm9kZV9kaXNwbGF5KCk7XG5cbiAgICBuLmRpc3BsYXkgKGZ1bmN0aW9uIChub2RlKSB7XG5cdHZhciBzID0gZDMuZnVuY3RvcihuLnNpemUoKSkobm9kZSk7XG5cdGQzLnNlbGVjdCh0aGlzKVxuICAgICAgICAuYXBwZW5kKFwicmVjdFwiKVxuICAgICAgICAuYXR0cihcInhcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgIHJldHVybiAtcztcbiAgICAgICAgfSlcbiAgICAgICAgLmF0dHIoXCJ5XCIsIGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICByZXR1cm4gLXM7XG4gICAgICAgIH0pXG4gICAgICAgIC5hdHRyKFwid2lkdGhcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgIHJldHVybiBzKjI7XG4gICAgICAgIH0pXG4gICAgICAgIC5hdHRyKFwiaGVpZ2h0XCIsIGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICByZXR1cm4gcyoyO1xuICAgICAgICB9KVxuICAgICAgICAuYXR0cihcImZpbGxcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKG4uZmlsbCgpKShub2RlKTtcbiAgICAgICAgfSlcbiAgICAgICAgLmF0dHIoXCJzdHJva2VcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKG4uc3Ryb2tlKCkpKG5vZGUpO1xuICAgICAgICB9KVxuICAgICAgICAuYXR0cihcInN0cm9rZS13aWR0aFwiLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgcmV0dXJuIGQzLmZ1bmN0b3Iobi5zdHJva2Vfd2lkdGgoKSkobm9kZSk7XG4gICAgICAgIH0pXG4gICAgICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfbm9kZV9kaXNwbGF5X2VsZW1cIik7XG4gICAgfSk7XG5cbiAgICByZXR1cm4gbjtcbn07XG5cbnRyZWUubm9kZV9kaXNwbGF5LnRyaWFuZ2xlID0gZnVuY3Rpb24gKCkge1xuICAgIHZhciBuID0gdHJlZS5ub2RlX2Rpc3BsYXkoKTtcblxuICAgIG4uZGlzcGxheSAoZnVuY3Rpb24gKG5vZGUpIHtcblx0dmFyIHMgPSBkMy5mdW5jdG9yKG4uc2l6ZSgpKShub2RlKTtcblx0ZDMuc2VsZWN0KHRoaXMpXG4gICAgICAgIC5hcHBlbmQoXCJwb2x5Z29uXCIpXG4gICAgICAgIC5hdHRyKFwicG9pbnRzXCIsICgtcykgKyBcIiwwIFwiICsgcyArIFwiLFwiICsgKC1zKSArIFwiIFwiICsgcyArIFwiLFwiICsgcylcbiAgICAgICAgLmF0dHIoXCJmaWxsXCIsIGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihuLmZpbGwoKSkobm9kZSk7XG4gICAgICAgIH0pXG4gICAgICAgIC5hdHRyKFwic3Ryb2tlXCIsIGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICByZXR1cm4gZDMuZnVuY3RvcihuLnN0cm9rZSgpKShub2RlKTtcbiAgICAgICAgfSlcbiAgICAgICAgLmF0dHIoXCJzdHJva2Utd2lkdGhcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKG4uc3Ryb2tlX3dpZHRoKCkpKG5vZGUpO1xuICAgICAgICB9KVxuICAgICAgICAuYXR0cihcImNsYXNzXCIsIFwidG50X25vZGVfZGlzcGxheV9lbGVtXCIpO1xuICAgIH0pO1xuXG4gICAgcmV0dXJuIG47XG59O1xuXG4vLyB0cmVlLm5vZGVfZGlzcGxheS5jb25kID0gZnVuY3Rpb24gKCkge1xuLy8gICAgIHZhciBuID0gdHJlZS5ub2RlX2Rpc3BsYXkoKTtcbi8vXG4vLyAgICAgLy8gY29uZGl0aW9ucyBhcmUgb2JqZWN0cyB3aXRoXG4vLyAgICAgLy8gbmFtZSA6IGEgbmFtZSBmb3IgdGhpcyBkaXNwbGF5XG4vLyAgICAgLy8gY2FsbGJhY2s6IHRoZSBjb25kaXRpb24gdG8gYXBwbHkgKHJlY2VpdmVzIGEgdG50Lm5vZGUpXG4vLyAgICAgLy8gZGlzcGxheTogYSBub2RlX2Rpc3BsYXlcbi8vICAgICB2YXIgY29uZHMgPSBbXTtcbi8vXG4vLyAgICAgbi5kaXNwbGF5IChmdW5jdGlvbiAobm9kZSkge1xuLy8gICAgICAgICB2YXIgcyA9IGQzLmZ1bmN0b3Iobi5zaXplKCkpKG5vZGUpO1xuLy8gICAgICAgICBmb3IgKHZhciBpPTA7IGk8Y29uZHMubGVuZ3RoOyBpKyspIHtcbi8vICAgICAgICAgICAgIHZhciBjb25kID0gY29uZHNbaV07XG4vLyAgICAgICAgICAgICAvLyBGb3IgZWFjaCBub2RlLCB0aGUgZmlyc3QgY29uZGl0aW9uIG1ldCBpcyB1c2VkXG4vLyAgICAgICAgICAgICBpZiAoZDMuZnVuY3Rvcihjb25kLmNhbGxiYWNrKS5jYWxsKHRoaXMsIG5vZGUpID09PSB0cnVlKSB7XG4vLyAgICAgICAgICAgICAgICAgY29uZC5kaXNwbGF5LmNhbGwodGhpcywgbm9kZSk7XG4vLyAgICAgICAgICAgICAgICAgYnJlYWs7XG4vLyAgICAgICAgICAgICB9XG4vLyAgICAgICAgIH1cbi8vICAgICB9KTtcbi8vXG4vLyAgICAgdmFyIGFwaSA9IGFwaWpzKG4pO1xuLy9cbi8vICAgICBhcGkubWV0aG9kKFwiYWRkXCIsIGZ1bmN0aW9uIChuYW1lLCBjYmFrLCBub2RlX2Rpc3BsYXkpIHtcbi8vICAgICAgICAgY29uZHMucHVzaCh7IG5hbWUgOiBuYW1lLFxuLy8gICAgICAgICAgICAgY2FsbGJhY2sgOiBjYmFrLFxuLy8gICAgICAgICAgICAgZGlzcGxheSA6IG5vZGVfZGlzcGxheVxuLy8gICAgICAgICB9KTtcbi8vICAgICAgICAgcmV0dXJuIG47XG4vLyAgICAgfSk7XG4vL1xuLy8gICAgIGFwaS5tZXRob2QoXCJyZXNldFwiLCBmdW5jdGlvbiAoKSB7XG4vLyAgICAgICAgIGNvbmRzID0gW107XG4vLyAgICAgICAgIHJldHVybiBuO1xuLy8gICAgIH0pO1xuLy9cbi8vICAgICBhcGkubWV0aG9kKFwidXBkYXRlXCIsIGZ1bmN0aW9uIChuYW1lLCBjYmFrLCBuZXdfZGlzcGxheSkge1xuLy8gICAgICAgICBmb3IgKHZhciBpPTA7IGk8Y29uZHMubGVuZ3RoOyBpKyspIHtcbi8vICAgICAgICAgICAgIGlmIChjb25kc1tpXS5uYW1lID09PSBuYW1lKSB7XG4vLyAgICAgICAgICAgICAgICAgY29uZHNbaV0uY2FsbGJhY2sgPSBjYmFrO1xuLy8gICAgICAgICAgICAgICAgIGNvbmRzW2ldLmRpc3BsYXkgPSBuZXdfZGlzcGxheTtcbi8vICAgICAgICAgICAgIH1cbi8vICAgICAgICAgfVxuLy8gICAgICAgICByZXR1cm4gbjtcbi8vICAgICB9KTtcbi8vXG4vLyAgICAgcmV0dXJuIG47XG4vL1xuLy8gfTtcblxubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gdHJlZS5ub2RlX2Rpc3BsYXk7XG4iLCJ2YXIgYXBpanMgPSByZXF1aXJlKFwidG50LmFwaVwiKTtcbnZhciB0bnRfdHJlZV9ub2RlID0gcmVxdWlyZShcInRudC50cmVlLm5vZGVcIik7XG5cbnZhciB0cmVlID0gZnVuY3Rpb24gKCkge1xuICAgIFwidXNlIHN0cmljdFwiO1xuXG4gICAgdmFyIGRpc3BhdGNoID0gZDMuZGlzcGF0Y2ggKFwiY2xpY2tcIiwgXCJkYmxjbGlja1wiLCBcIm1vdXNlb3ZlclwiLCBcIm1vdXNlb3V0XCIpO1xuXG4gICAgdmFyIGNvbmYgPSB7XG4gICAgICAgIGR1cmF0aW9uICAgICAgICAgOiA1MDAsICAgICAgLy8gRHVyYXRpb24gb2YgdGhlIHRyYW5zaXRpb25zXG4gICAgICAgIG5vZGVfZGlzcGxheSAgICAgOiB0cmVlLm5vZGVfZGlzcGxheS5jaXJjbGUoKSxcbiAgICAgICAgbGFiZWwgICAgICAgICAgICA6IHRyZWUubGFiZWwudGV4dCgpLFxuICAgICAgICBsYXlvdXQgICAgICAgICAgIDogdHJlZS5sYXlvdXQudmVydGljYWwoKSxcbiAgICAgICAgLy8gb25fY2xpY2sgICAgICAgICA6IGZ1bmN0aW9uICgpIHt9LFxuICAgICAgICAvLyBvbl9kYmxfY2xpY2sgICAgIDogZnVuY3Rpb24gKCkge30sXG4gICAgICAgIC8vIG9uX21vdXNlb3ZlciAgICAgOiBmdW5jdGlvbiAoKSB7fSxcbiAgICAgICAgYnJhbmNoX2NvbG9yICAgICA6ICdibGFjaycsXG4gICAgICAgIGlkICAgICAgICAgICAgICAgOiBmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgcmV0dXJuIGQuX2lkO1xuICAgICAgICB9XG4gICAgfTtcblxuICAgIC8vIEtlZXAgdHJhY2sgb2YgdGhlIGZvY3VzZWQgbm9kZVxuICAgIC8vIFRPRE86IFdvdWxkIGl0IGJlIGJldHRlciB0byBoYXZlIG11bHRpcGxlIGZvY3VzZWQgbm9kZXM/IChpZSB1c2UgYW4gYXJyYXkpXG4gICAgLy8gdmFyIGZvY3VzZWRfbm9kZTtcblxuICAgIC8vIEV4dHJhIGRlbGF5IGluIHRoZSB0cmFuc2l0aW9ucyAoVE9ETzogTmVlZGVkPylcbiAgICB2YXIgZGVsYXkgPSAwO1xuXG4gICAgLy8gRWFzZSBvZiB0aGUgdHJhbnNpdGlvbnNcbiAgICB2YXIgZWFzZSA9IFwiY3ViaWMtaW4tb3V0XCI7XG5cbiAgICAvLyBUaGUgaWQgb2YgdGhlIHRyZWUgY29udGFpbmVyXG4gICAgdmFyIGRpdl9pZDtcblxuICAgIC8vIFRoZSB0cmVlIHZpc3VhbGl6YXRpb24gKHN2ZylcbiAgICB2YXIgc3ZnO1xuICAgIHZhciB2aXM7XG4gICAgdmFyIGxpbmtzX2c7XG4gICAgdmFyIG5vZGVzX2c7XG5cbiAgICAvLyBUT0RPOiBGb3Igbm93LCBjb3VudHMgYXJlIGdpdmVuIG9ubHkgZm9yIGxlYXZlc1xuICAgIC8vIGJ1dCBpdCBtYXkgYmUgZ29vZCB0byBhbGxvdyBjb3VudHMgZm9yIGludGVybmFsIG5vZGVzXG4gICAgdmFyIGNvdW50cyA9IHt9O1xuXG4gICAgLy8gVGhlIGZ1bGwgdHJlZVxuICAgIHZhciBiYXNlID0ge1xuICAgICAgICB0cmVlIDogdW5kZWZpbmVkLFxuICAgICAgICBkYXRhIDogdW5kZWZpbmVkLFxuICAgICAgICBub2RlcyA6IHVuZGVmaW5lZCxcbiAgICAgICAgbGlua3MgOiB1bmRlZmluZWRcbiAgICB9O1xuXG4gICAgLy8gVGhlIGN1cnIgdHJlZS4gTmVlZGVkIHRvIHJlLWNvbXB1dGUgdGhlIGxpbmtzIC8gbm9kZXMgcG9zaXRpb25zIG9mIHN1YnRyZWVzXG4gICAgdmFyIGN1cnIgPSB7XG4gICAgICAgIHRyZWUgOiB1bmRlZmluZWQsXG4gICAgICAgIGRhdGEgOiB1bmRlZmluZWQsXG4gICAgICAgIG5vZGVzIDogdW5kZWZpbmVkLFxuICAgICAgICBsaW5rcyA6IHVuZGVmaW5lZFxuICAgIH07XG5cbiAgICAvLyBUaGUgY2JhayByZXR1cm5lZFxuICAgIHZhciB0ID0gZnVuY3Rpb24gKGRpdikge1xuICAgIFx0ZGl2X2lkID0gZDMuc2VsZWN0KGRpdikuYXR0cihcImlkXCIpO1xuXG4gICAgICAgIHZhciB0cmVlX2RpdiA9IGQzLnNlbGVjdChkaXYpXG4gICAgICAgICAgICAuYXBwZW5kKFwiZGl2XCIpXG4gICAgICAgICAgICAuc3R5bGUoXCJ3aWR0aFwiLCAoY29uZi5sYXlvdXQud2lkdGgoKSArICBcInB4XCIpKVxuICAgICAgICAgICAgLmF0dHIoXCJjbGFzc1wiLCBcInRudF9ncm91cERpdlwiKTtcblxuICAgIFx0dmFyIGNsdXN0ZXIgPSBjb25mLmxheW91dC5jbHVzdGVyO1xuXG4gICAgXHR2YXIgbl9sZWF2ZXMgPSBjdXJyLnRyZWUuZ2V0X2FsbF9sZWF2ZXMoKS5sZW5ndGg7XG5cbiAgICBcdHZhciBtYXhfbGVhZl9sYWJlbF9sZW5ndGggPSBmdW5jdGlvbiAodHJlZSkge1xuICAgIFx0ICAgIHZhciBtYXggPSAwO1xuICAgIFx0ICAgIHZhciBsZWF2ZXMgPSB0cmVlLmdldF9hbGxfbGVhdmVzKCk7XG4gICAgXHQgICAgZm9yICh2YXIgaT0wOyBpPGxlYXZlcy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgICAgIHZhciBsYWJlbF93aWR0aCA9IGNvbmYubGFiZWwud2lkdGgoKShsZWF2ZXNbaV0pICsgZDMuZnVuY3RvciAoY29uZi5ub2RlX2Rpc3BsYXkuc2l6ZSgpKShsZWF2ZXNbaV0pO1xuICAgICAgICAgICAgICAgIGlmIChsYWJlbF93aWR0aCA+IG1heCkge1xuICAgICAgICAgICAgICAgICAgICBtYXggPSBsYWJlbF93aWR0aDtcbiAgICAgICAgICAgICAgICB9XG4gICAgXHQgICAgfVxuICAgIFx0ICAgIHJldHVybiBtYXg7XG4gICAgXHR9O1xuXG4gICAgICAgIHZhciBtYXhfbGVhZl9ub2RlX2hlaWdodCA9IGZ1bmN0aW9uICh0cmVlKSB7XG4gICAgICAgICAgICB2YXIgbWF4ID0gMDtcbiAgICAgICAgICAgIHZhciBsZWF2ZXMgPSB0cmVlLmdldF9hbGxfbGVhdmVzKCk7XG4gICAgICAgICAgICBmb3IgKHZhciBpPTA7IGk8bGVhdmVzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICAgICAgdmFyIG5vZGVfaGVpZ2h0ID0gZDMuZnVuY3Rvcihjb25mLm5vZGVfZGlzcGxheS5zaXplKCkpKGxlYXZlc1tpXSkgKiAyO1xuICAgICAgICAgICAgICAgIHZhciBsYWJlbF9oZWlnaHQgPSBkMy5mdW5jdG9yKGNvbmYubGFiZWwuaGVpZ2h0KCkpKGxlYXZlc1tpXSk7XG5cbiAgICAgICAgICAgICAgICBtYXggPSBkMy5tYXgoW21heCwgbm9kZV9oZWlnaHQsIGxhYmVsX2hlaWdodF0pO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIG1heDtcbiAgICAgICAgfTtcblxuICAgIFx0dmFyIG1heF9sYWJlbF9sZW5ndGggPSBtYXhfbGVhZl9sYWJlbF9sZW5ndGgoY3Vyci50cmVlKTtcbiAgICBcdGNvbmYubGF5b3V0Lm1heF9sZWFmX2xhYmVsX3dpZHRoKG1heF9sYWJlbF9sZW5ndGgpO1xuXG4gICAgXHR2YXIgbWF4X25vZGVfaGVpZ2h0ID0gbWF4X2xlYWZfbm9kZV9oZWlnaHQoY3Vyci50cmVlKTtcblxuICAgIFx0Ly8gQ2x1c3RlciBzaXplIGlzIHRoZSByZXN1bHQgb2YuLi5cbiAgICBcdC8vIHRvdGFsIHdpZHRoIG9mIHRoZSB2aXMgLSB0cmFuc2Zvcm0gZm9yIHRoZSB0cmVlIC0gbWF4X2xlYWZfbGFiZWxfd2lkdGggLSBob3Jpem9udGFsIHRyYW5zZm9ybSBvZiB0aGUgbGFiZWxcbiAgICBcdC8vIFRPRE86IFN1YnN0aXR1dGUgMTUgYnkgdGhlIGhvcml6b250YWwgdHJhbnNmb3JtIG9mIHRoZSBub2Rlc1xuICAgIFx0dmFyIGNsdXN0ZXJfc2l6ZV9wYXJhbXMgPSB7XG4gICAgXHQgICAgbl9sZWF2ZXMgOiBuX2xlYXZlcyxcbiAgICBcdCAgICBsYWJlbF9oZWlnaHQgOiBtYXhfbm9kZV9oZWlnaHQsXG4gICAgXHQgICAgbGFiZWxfcGFkZGluZyA6IDE1XG4gICAgXHR9O1xuXG4gICAgXHRjb25mLmxheW91dC5hZGp1c3RfY2x1c3Rlcl9zaXplKGNsdXN0ZXJfc2l6ZV9wYXJhbXMpO1xuXG4gICAgXHR2YXIgZGlhZ29uYWwgPSBjb25mLmxheW91dC5kaWFnb25hbCgpO1xuICAgIFx0dmFyIHRyYW5zZm9ybSA9IGNvbmYubGF5b3V0LnRyYW5zZm9ybV9ub2RlO1xuXG4gICAgXHRzdmcgPSB0cmVlX2RpdlxuICAgIFx0ICAgIC5hcHBlbmQoXCJzdmdcIilcbiAgICBcdCAgICAuYXR0cihcIndpZHRoXCIsIGNvbmYubGF5b3V0LndpZHRoKCkpXG4gICAgXHQgICAgLmF0dHIoXCJoZWlnaHRcIiwgY29uZi5sYXlvdXQuaGVpZ2h0KGNsdXN0ZXJfc2l6ZV9wYXJhbXMpICsgMzApXG4gICAgXHQgICAgLmF0dHIoXCJmaWxsXCIsIFwibm9uZVwiKTtcblxuICAgIFx0dmlzID0gc3ZnXG4gICAgXHQgICAgLmFwcGVuZChcImdcIilcbiAgICBcdCAgICAuYXR0cihcImlkXCIsIFwidG50X3N0X1wiICsgZGl2X2lkKVxuICAgIFx0ICAgIC5hdHRyKFwidHJhbnNmb3JtXCIsXG4gICAgXHRcdCAgXCJ0cmFuc2xhdGUoXCIgK1xuICAgIFx0XHQgIGNvbmYubGF5b3V0LnRyYW5zbGF0ZV92aXMoKVswXSArXG4gICAgXHRcdCAgXCIsXCIgK1xuICAgIFx0XHQgIGNvbmYubGF5b3V0LnRyYW5zbGF0ZV92aXMoKVsxXSArXG4gICAgXHRcdCAgXCIpXCIpO1xuXG4gICAgXHRjdXJyLm5vZGVzID0gY2x1c3Rlci5ub2RlcyhjdXJyLmRhdGEpO1xuICAgIFx0Y29uZi5sYXlvdXQuc2NhbGVfYnJhbmNoX2xlbmd0aHMoY3Vycik7XG4gICAgXHRjdXJyLmxpbmtzID0gY2x1c3Rlci5saW5rcyhjdXJyLm5vZGVzKTtcblxuICAgIFx0Ly8gTElOS1NcbiAgICBcdC8vIEFsbCB0aGUgbGlua3MgYXJlIGdyb3VwZWQgaW4gYSBnIGVsZW1lbnRcbiAgICBcdGxpbmtzX2cgPSB2aXNcbiAgICBcdCAgICAuYXBwZW5kKFwiZ1wiKVxuICAgIFx0ICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJsaW5rc1wiKTtcbiAgICBcdG5vZGVzX2cgPSB2aXNcbiAgICBcdCAgICAuYXBwZW5kKFwiZ1wiKVxuICAgIFx0ICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJub2Rlc1wiKTtcblxuICAgIFx0Ly92YXIgbGluayA9IHZpc1xuICAgIFx0dmFyIGxpbmsgPSBsaW5rc19nXG4gICAgXHQgICAgLnNlbGVjdEFsbChcInBhdGgudG50X3RyZWVfbGlua1wiKVxuICAgIFx0ICAgIC5kYXRhKGN1cnIubGlua3MsIGZ1bmN0aW9uKGQpe1xuICAgICAgICAgICAgICAgIHJldHVybiBjb25mLmlkKGQudGFyZ2V0KTtcbiAgICAgICAgICAgIH0pO1xuXG4gICAgXHRsaW5rXG4gICAgXHQgICAgLmVudGVyKClcbiAgICBcdCAgICAuYXBwZW5kKFwicGF0aFwiKVxuICAgIFx0ICAgIC5hdHRyKFwiY2xhc3NcIiwgXCJ0bnRfdHJlZV9saW5rXCIpXG4gICAgXHQgICAgLmF0dHIoXCJpZFwiLCBmdW5jdGlvbihkKSB7XG4gICAgXHQgICAgXHRyZXR1cm4gXCJ0bnRfdHJlZV9saW5rX1wiICsgZGl2X2lkICsgXCJfXCIgKyBjb25mLmlkKGQudGFyZ2V0KTtcbiAgICBcdCAgICB9KVxuICAgIFx0ICAgIC5zdHlsZShcInN0cm9rZVwiLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgICAgIHJldHVybiBkMy5mdW5jdG9yKGNvbmYuYnJhbmNoX2NvbG9yKSh0bnRfdHJlZV9ub2RlKGQuc291cmNlKSwgdG50X3RyZWVfbm9kZShkLnRhcmdldCkpO1xuICAgIFx0ICAgIH0pXG4gICAgXHQgICAgLmF0dHIoXCJkXCIsIGRpYWdvbmFsKTtcblxuICAgIFx0Ly8gTk9ERVNcbiAgICBcdC8vdmFyIG5vZGUgPSB2aXNcbiAgICBcdHZhciBub2RlID0gbm9kZXNfZ1xuICAgIFx0ICAgIC5zZWxlY3RBbGwoXCJnLnRudF90cmVlX25vZGVcIilcbiAgICBcdCAgICAuZGF0YShjdXJyLm5vZGVzLCBmdW5jdGlvbihkKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIGNvbmYuaWQoZCk7XG4gICAgICAgICAgICB9KTtcblxuICAgIFx0dmFyIG5ld19ub2RlID0gbm9kZVxuICAgIFx0ICAgIC5lbnRlcigpLmFwcGVuZChcImdcIilcbiAgICBcdCAgICAuYXR0cihcImNsYXNzXCIsIGZ1bmN0aW9uKG4pIHtcbiAgICAgICAgXHRcdGlmIChuLmNoaWxkcmVuKSB7XG4gICAgICAgIFx0XHQgICAgaWYgKG4uZGVwdGggPT09IDApIHtcbiAgICAgICAgICAgIFx0XHRcdHJldHVybiBcInJvb3QgdG50X3RyZWVfbm9kZVwiO1xuICAgICAgICBcdFx0ICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBcdFx0XHRyZXR1cm4gXCJpbm5lciB0bnRfdHJlZV9ub2RlXCI7XG4gICAgICAgIFx0XHQgICAgfVxuICAgICAgICBcdFx0fSBlbHNlIHtcbiAgICAgICAgXHRcdCAgICByZXR1cm4gXCJsZWFmIHRudF90cmVlX25vZGVcIjtcbiAgICAgICAgXHRcdH1cbiAgICAgICAgXHR9KVxuICAgIFx0ICAgIC5hdHRyKFwiaWRcIiwgZnVuY3Rpb24oZCkge1xuICAgICAgICBcdFx0cmV0dXJuIFwidG50X3RyZWVfbm9kZV9cIiArIGRpdl9pZCArIFwiX1wiICsgZC5faWQ7XG4gICAgXHQgICAgfSlcbiAgICBcdCAgICAuYXR0cihcInRyYW5zZm9ybVwiLCB0cmFuc2Zvcm0pO1xuXG4gICAgXHQvLyBkaXNwbGF5IG5vZGUgc2hhcGVcbiAgICBcdG5ld19ub2RlXG4gICAgXHQgICAgLmVhY2ggKGZ1bmN0aW9uIChkKSB7XG4gICAgICAgIFx0XHRjb25mLm5vZGVfZGlzcGxheS5jYWxsKHRoaXMsIHRudF90cmVlX25vZGUoZCkpO1xuICAgIFx0ICAgIH0pO1xuXG4gICAgXHQvLyBkaXNwbGF5IG5vZGUgbGFiZWxcbiAgICBcdG5ld19ub2RlXG4gICAgXHQgICAgLmVhY2ggKGZ1bmN0aW9uIChkKSB7XG4gICAgXHQgICAgXHRjb25mLmxhYmVsLmNhbGwodGhpcywgdG50X3RyZWVfbm9kZShkKSwgY29uZi5sYXlvdXQudHlwZSwgZDMuZnVuY3Rvcihjb25mLm5vZGVfZGlzcGxheS5zaXplKCkpKHRudF90cmVlX25vZGUoZCkpKTtcbiAgICBcdCAgICB9KTtcblxuICAgICAgICBuZXdfbm9kZS5vbihcImNsaWNrXCIsIGZ1bmN0aW9uIChub2RlKSB7XG4gICAgICAgICAgICB2YXIgbXlfbm9kZSA9IHRudF90cmVlX25vZGUobm9kZSk7XG4gICAgICAgICAgICB0cmVlLnRyaWdnZXIoXCJub2RlOmNsaWNrXCIsIG15X25vZGUpO1xuICAgICAgICAgICAgZGlzcGF0Y2guY2xpY2suY2FsbCh0aGlzLCBteV9ub2RlKTtcbiAgICAgICAgfSk7XG4gICAgICAgIG5ld19ub2RlLm9uKFwiZGJsY2xpY2tcIiwgZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgICAgIHZhciBteV9ub2RlID0gdG50X3RyZWVfbm9kZShub2RlKTtcbiAgICAgICAgICAgIHRyZWUudHJpZ2dlcihcIm5vZGU6ZGJsY2xpY2tcIiwgbXlfbm9kZSk7XG4gICAgICAgICAgICBkaXNwYXRjaC5kYmxjbGljay5jYWxsKHRoaXMsIG15X25vZGUpO1xuICAgICAgICB9KTtcbiAgICAgICAgbmV3X25vZGUub24oXCJtb3VzZW92ZXJcIiwgZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgICAgIHZhciBteV9ub2RlID0gdG50X3RyZWVfbm9kZShub2RlKTtcbiAgICAgICAgICAgIHRyZWUudHJpZ2dlcihcIm5vZGU6aG92ZXJcIiwgdG50X3RyZWVfbm9kZShub2RlKSk7XG4gICAgICAgICAgICBkaXNwYXRjaC5tb3VzZW92ZXIuY2FsbCh0aGlzLCBteV9ub2RlKTtcbiAgICAgICAgfSk7XG4gICAgICAgIG5ld19ub2RlLm9uKFwibW91c2VvdXRcIiwgZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgICAgIHZhciBteV9ub2RlID0gdG50X3RyZWVfbm9kZShub2RlKTtcbiAgICAgICAgICAgIHRyZWUudHJpZ2dlcihcIm5vZGU6bW91c2VvdXRcIiwgdG50X3RyZWVfbm9kZShub2RlKSk7XG4gICAgICAgICAgICBkaXNwYXRjaC5tb3VzZW91dC5jYWxsKHRoaXMsIG15X25vZGUpO1xuICAgICAgICB9KTtcblxuXG4gICAgXHQvLyBVcGRhdGUgcGxvdHMgYW4gdXBkYXRlZCB0cmVlXG4gICAgICAgIGFwaS5tZXRob2QgKCd1cGRhdGUnLCBmdW5jdGlvbigpIHtcbiAgICAgICAgICAgIHRyZWVfZGl2XG4gICAgICAgICAgICAgICAgLnN0eWxlKFwid2lkdGhcIiwgKGNvbmYubGF5b3V0LndpZHRoKCkgKyBcInB4XCIpKTtcbiAgICBcdCAgICBzdmcuYXR0cihcIndpZHRoXCIsIGNvbmYubGF5b3V0LndpZHRoKCkpO1xuXG4gICAgXHQgICAgdmFyIGNsdXN0ZXIgPSBjb25mLmxheW91dC5jbHVzdGVyO1xuICAgIFx0ICAgIHZhciBkaWFnb25hbCA9IGNvbmYubGF5b3V0LmRpYWdvbmFsKCk7XG4gICAgXHQgICAgdmFyIHRyYW5zZm9ybSA9IGNvbmYubGF5b3V0LnRyYW5zZm9ybV9ub2RlO1xuXG4gICAgXHQgICAgdmFyIG1heF9sYWJlbF9sZW5ndGggPSBtYXhfbGVhZl9sYWJlbF9sZW5ndGgoY3Vyci50cmVlKTtcbiAgICBcdCAgICBjb25mLmxheW91dC5tYXhfbGVhZl9sYWJlbF93aWR0aChtYXhfbGFiZWxfbGVuZ3RoKTtcblxuICAgIFx0ICAgIHZhciBtYXhfbm9kZV9oZWlnaHQgPSBtYXhfbGVhZl9ub2RlX2hlaWdodChjdXJyLnRyZWUpO1xuXG4gICAgXHQgICAgLy8gQ2x1c3RlciBzaXplIGlzIHRoZSByZXN1bHQgb2YuLi5cbiAgICBcdCAgICAvLyB0b3RhbCB3aWR0aCBvZiB0aGUgdmlzIC0gdHJhbnNmb3JtIGZvciB0aGUgdHJlZSAtIG1heF9sZWFmX2xhYmVsX3dpZHRoIC0gaG9yaXpvbnRhbCB0cmFuc2Zvcm0gb2YgdGhlIGxhYmVsXG4gICAgICAgIFx0Ly8gVE9ETzogU3Vic3RpdHV0ZSAxNSBieSB0aGUgdHJhbnNmb3JtIG9mIHRoZSBub2RlcyAocHJvYmFibHkgYnkgc2VsZWN0aW5nIG9uZSBub2RlIGFzc3VtaW5nIGFsbCB0aGUgbm9kZXMgaGF2ZSB0aGUgc2FtZSB0cmFuc2Zvcm1cbiAgICBcdCAgICB2YXIgbl9sZWF2ZXMgPSBjdXJyLnRyZWUuZ2V0X2FsbF9sZWF2ZXMoKS5sZW5ndGg7XG4gICAgXHQgICAgdmFyIGNsdXN0ZXJfc2l6ZV9wYXJhbXMgPSB7XG4gICAgICAgIFx0XHRuX2xlYXZlcyA6IG5fbGVhdmVzLFxuICAgICAgICBcdFx0bGFiZWxfaGVpZ2h0IDogbWF4X25vZGVfaGVpZ2h0LFxuICAgICAgICBcdFx0bGFiZWxfcGFkZGluZyA6IDE1XG4gICAgXHQgICAgfTtcbiAgICBcdCAgICBjb25mLmxheW91dC5hZGp1c3RfY2x1c3Rlcl9zaXplKGNsdXN0ZXJfc2l6ZV9wYXJhbXMpO1xuXG4gICAgICAgICAgICBzdmdcbiAgICAgICAgICAgICAgICAudHJhbnNpdGlvbigpXG4gICAgICAgICAgICAgICAgLmR1cmF0aW9uKGNvbmYuZHVyYXRpb24pXG4gICAgICAgICAgICAgICAgLmVhc2UoZWFzZSlcbiAgICAgICAgICAgICAgICAuYXR0cihcImhlaWdodFwiLCBjb25mLmxheW91dC5oZWlnaHQoY2x1c3Rlcl9zaXplX3BhcmFtcykgKyAzMCk7IC8vIGhlaWdodCBpcyBpbiB0aGUgbGF5b3V0XG5cbiAgICBcdCAgICB2aXNcbiAgICAgICAgICAgICAgICAudHJhbnNpdGlvbigpXG4gICAgICAgICAgICAgICAgLmR1cmF0aW9uKGNvbmYuZHVyYXRpb24pXG4gICAgICAgICAgICAgICAgLmF0dHIoXCJ0cmFuc2Zvcm1cIixcbiAgICAgICAgICAgICAgICBcInRyYW5zbGF0ZShcIiArXG4gICAgICAgICAgICAgICAgY29uZi5sYXlvdXQudHJhbnNsYXRlX3ZpcygpWzBdICtcbiAgICAgICAgICAgICAgICBcIixcIiArXG4gICAgICAgICAgICAgICAgY29uZi5sYXlvdXQudHJhbnNsYXRlX3ZpcygpWzFdICtcbiAgICAgICAgICAgICAgICBcIilcIik7XG5cbiAgICAgICAgICAgIGN1cnIubm9kZXMgPSBjbHVzdGVyLm5vZGVzKGN1cnIuZGF0YSk7XG4gICAgICAgICAgICBjb25mLmxheW91dC5zY2FsZV9icmFuY2hfbGVuZ3RocyhjdXJyKTtcbiAgICAgICAgICAgIGN1cnIubGlua3MgPSBjbHVzdGVyLmxpbmtzKGN1cnIubm9kZXMpO1xuXG4gICAgXHQgICAgLy8gTElOS1NcbiAgICBcdCAgICB2YXIgbGluayA9IGxpbmtzX2dcbiAgICAgICAgXHRcdC5zZWxlY3RBbGwoXCJwYXRoLnRudF90cmVlX2xpbmtcIilcbiAgICAgICAgXHRcdC5kYXRhKGN1cnIubGlua3MsIGZ1bmN0aW9uKGQpe1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gY29uZi5pZChkLnRhcmdldCk7XG4gICAgICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIC8vIE5PREVTXG4gICAgXHQgICAgdmFyIG5vZGUgPSBub2Rlc19nXG4gICAgICAgIFx0XHQuc2VsZWN0QWxsKFwiZy50bnRfdHJlZV9ub2RlXCIpXG4gICAgICAgIFx0XHQuZGF0YShjdXJyLm5vZGVzLCBmdW5jdGlvbihkKSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiBjb25mLmlkKGQpO1xuICAgICAgICAgICAgICAgIH0pO1xuXG4gICAgXHQgICAgdmFyIGV4aXRfbGluayA9IGxpbmtcbiAgICAgICAgXHRcdC5leGl0KClcbiAgICAgICAgXHRcdC5yZW1vdmUoKTtcblxuICAgIFx0ICAgIGxpbmtcbiAgICAgICAgXHRcdC5lbnRlcigpXG4gICAgICAgIFx0XHQuYXBwZW5kKFwicGF0aFwiKVxuICAgICAgICBcdFx0LmF0dHIoXCJjbGFzc1wiLCBcInRudF90cmVlX2xpbmtcIilcbiAgICAgICAgXHRcdC5hdHRyKFwiaWRcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgXHRcdCAgICByZXR1cm4gXCJ0bnRfdHJlZV9saW5rX1wiICsgZGl2X2lkICsgXCJfXCIgKyBjb25mLmlkKGQudGFyZ2V0KTtcbiAgICAgICAgXHRcdH0pXG4gICAgICAgIFx0XHQuYXR0cihcInN0cm9rZVwiLCBmdW5jdGlvbiAoZCkge1xuICAgICAgICBcdFx0ICAgIHJldHVybiBkMy5mdW5jdG9yKGNvbmYuYnJhbmNoX2NvbG9yKSh0bnRfdHJlZV9ub2RlKGQuc291cmNlKSwgdG50X3RyZWVfbm9kZShkLnRhcmdldCkpO1xuICAgICAgICBcdFx0fSlcbiAgICAgICAgXHRcdC5hdHRyKFwiZFwiLCBkaWFnb25hbCk7XG5cbiAgICBcdCAgICBsaW5rXG4gICAgXHQgICAgXHQudHJhbnNpdGlvbigpXG4gICAgICAgIFx0XHQuZWFzZShlYXNlKVxuICAgIFx0ICAgIFx0LmR1cmF0aW9uKGNvbmYuZHVyYXRpb24pXG4gICAgXHQgICAgXHQuYXR0cihcImRcIiwgZGlhZ29uYWwpO1xuXG5cbiAgICBcdCAgICAvLyBOb2Rlc1xuICAgIFx0ICAgIHZhciBuZXdfbm9kZSA9IG5vZGVcbiAgICAgICAgXHRcdC5lbnRlcigpXG4gICAgICAgIFx0XHQuYXBwZW5kKFwiZ1wiKVxuICAgICAgICBcdFx0LmF0dHIoXCJjbGFzc1wiLCBmdW5jdGlvbihuKSB7XG4gICAgICAgIFx0XHQgICAgaWYgKG4uY2hpbGRyZW4pIHtcbiAgICAgICAgICAgIFx0XHRcdGlmIChuLmRlcHRoID09PSAwKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFwicm9vdCB0bnRfdHJlZV9ub2RlXCI7XG4gICAgICAgICAgICBcdFx0XHR9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBcImlubmVyIHRudF90cmVlX25vZGVcIjtcbiAgICAgICAgICAgIFx0XHRcdH1cbiAgICAgICAgXHRcdCAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFwibGVhZiB0bnRfdHJlZV9ub2RlXCI7XG4gICAgICAgIFx0XHQgICAgfVxuICAgICAgICBcdFx0fSlcbiAgICAgICAgXHRcdC5hdHRyKFwiaWRcIiwgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgXHRcdCAgICByZXR1cm4gXCJ0bnRfdHJlZV9ub2RlX1wiICsgZGl2X2lkICsgXCJfXCIgKyBkLl9pZDtcbiAgICAgICAgXHRcdH0pXG4gICAgICAgIFx0XHQuYXR0cihcInRyYW5zZm9ybVwiLCB0cmFuc2Zvcm0pO1xuXG4gICAgXHQgICAgLy8gRXhpdGluZyBub2RlcyBhcmUganVzdCByZW1vdmVkXG4gICAgXHQgICAgbm9kZVxuICAgICAgICBcdFx0LmV4aXQoKVxuICAgICAgICBcdFx0LnJlbW92ZSgpO1xuXG4gICAgICAgICAgICBuZXdfbm9kZS5vbihcImNsaWNrXCIsIGZ1bmN0aW9uIChub2RlKSB7XG4gICAgICAgICAgICAgICAgdmFyIG15X25vZGUgPSB0bnRfdHJlZV9ub2RlKG5vZGUpO1xuICAgICAgICAgICAgICAgIHRyZWUudHJpZ2dlcihcIm5vZGU6Y2xpY2tcIiwgbXlfbm9kZSk7XG4gICAgICAgICAgICAgICAgZGlzcGF0Y2guY2xpY2suY2FsbCh0aGlzLCBteV9ub2RlKTtcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgbmV3X25vZGUub24oXCJkYmxjbGlja1wiLCBmdW5jdGlvbiAobm9kZSkge1xuICAgICAgICAgICAgICAgIHZhciBteV9ub2RlID0gdG50X3RyZWVfbm9kZShub2RlKTtcbiAgICAgICAgICAgICAgICB0cmVlLnRyaWdnZXIoXCJub2RlOmRibGNsaWNrXCIsIG15X25vZGUpO1xuICAgICAgICAgICAgICAgIGRpc3BhdGNoLmRibGNsaWNrLmNhbGwodGhpcywgbXlfbm9kZSk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIG5ld19ub2RlLm9uKFwibW91c2VvdmVyXCIsIGZ1bmN0aW9uIChub2RlKSB7XG4gICAgICAgICAgICAgICAgdmFyIG15X25vZGUgPSB0bnRfdHJlZV9ub2RlKG5vZGUpO1xuICAgICAgICAgICAgICAgIHRyZWUudHJpZ2dlcihcIm5vZGU6aG92ZXJcIiwgdG50X3RyZWVfbm9kZShub2RlKSk7XG4gICAgICAgICAgICAgICAgZGlzcGF0Y2gubW91c2VvdmVyLmNhbGwodGhpcywgbXlfbm9kZSk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIG5ld19ub2RlLm9uKFwibW91c2VvdXRcIiwgZnVuY3Rpb24gKG5vZGUpIHtcbiAgICAgICAgICAgICAgICB2YXIgbXlfbm9kZSA9IHRudF90cmVlX25vZGUobm9kZSk7XG4gICAgICAgICAgICAgICAgdHJlZS50cmlnZ2VyKFwibm9kZTptb3VzZW91dFwiLCB0bnRfdHJlZV9ub2RlKG5vZGUpKTtcbiAgICAgICAgICAgICAgICBkaXNwYXRjaC5tb3VzZW91dC5jYWxsKHRoaXMsIG15X25vZGUpO1xuICAgICAgICAgICAgfSk7XG5cbiAgICBcdCAgICAvLyAvLyBXZSBuZWVkIHRvIHJlLWNyZWF0ZSBhbGwgdGhlIG5vZGVzIGFnYWluIGluIGNhc2UgdGhleSBoYXZlIGNoYW5nZWQgbGl2ZWx5IChvciB0aGUgbGF5b3V0KVxuICAgIFx0ICAgIC8vIG5vZGUuc2VsZWN0QWxsKFwiKlwiKS5yZW1vdmUoKTtcbiAgICBcdCAgICAvLyBuZXdfbm9kZVxuICAgIFx0XHQvLyAgICAgLmVhY2goZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgXHQvLyBcdFx0Y29uZi5ub2RlX2Rpc3BsYXkuY2FsbCh0aGlzLCB0bnRfdHJlZV9ub2RlKGQpKTtcbiAgICBcdFx0Ly8gICAgIH0pO1xuICAgICAgICAgICAgLy9cbiAgICBcdCAgICAvLyAvLyBXZSBuZWVkIHRvIHJlLWNyZWF0ZSBhbGwgdGhlIGxhYmVscyBhZ2FpbiBpbiBjYXNlIHRoZXkgaGF2ZSBjaGFuZ2VkIGxpdmVseSAob3IgdGhlIGxheW91dClcbiAgICBcdCAgICAvLyBuZXdfbm9kZVxuICAgIFx0XHQvLyAgICAgLmVhY2ggKGZ1bmN0aW9uIChkKSB7XG4gICAgICAgIFx0Ly8gXHRcdGNvbmYubGFiZWwuY2FsbCh0aGlzLCB0bnRfdHJlZV9ub2RlKGQpLCBjb25mLmxheW91dC50eXBlLCBkMy5mdW5jdG9yKGNvbmYubm9kZV9kaXNwbGF5LnNpemUoKSkodG50X3RyZWVfbm9kZShkKSkpO1xuICAgIFx0XHQvLyAgICAgfSk7XG5cbiAgICAgICAgICAgIHQudXBkYXRlX25vZGVzKCk7XG5cbiAgICBcdCAgICBub2RlXG4gICAgICAgIFx0XHQudHJhbnNpdGlvbigpXG4gICAgICAgIFx0XHQuZWFzZShlYXNlKVxuICAgICAgICBcdFx0LmR1cmF0aW9uKGNvbmYuZHVyYXRpb24pXG4gICAgICAgIFx0XHQuYXR0cihcInRyYW5zZm9ybVwiLCB0cmFuc2Zvcm0pO1xuXG4gICAgXHR9KTtcblxuICAgICAgICBhcGkubWV0aG9kKCd1cGRhdGVfbm9kZXMnLCBmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICB2YXIgbm9kZSA9IG5vZGVzX2dcbiAgICAgICAgICAgICAgICAuc2VsZWN0QWxsKFwiZy50bnRfdHJlZV9ub2RlXCIpO1xuXG4gICAgICAgICAgICAvLyByZS1jcmVhdGUgYWxsIHRoZSBub2RlcyBhZ2FpblxuICAgICAgICAgICAgLy8gbm9kZS5zZWxlY3RBbGwoXCIqXCIpLnJlbW92ZSgpO1xuICAgICAgICAgICAgbm9kZVxuICAgICAgICAgICAgICAgIC5lYWNoKGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICAgICAgY29uZi5ub2RlX2Rpc3BsYXkucmVzZXQuY2FsbCh0aGlzKTtcbiAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgbm9kZVxuICAgICAgICAgICAgICAgIC5lYWNoKGZ1bmN0aW9uIChkKSB7XG4gICAgICAgICAgICAgICAgICAgIC8vY29uc29sZS5sb2coY29uZi5ub2RlX2Rpc3BsYXkoKSk7XG4gICAgICAgICAgICAgICAgICAgIGNvbmYubm9kZV9kaXNwbGF5LmNhbGwodGhpcywgdG50X3RyZWVfbm9kZShkKSk7XG4gICAgICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIC8vIHJlLWNyZWF0ZSBhbGwgdGhlIGxhYmVscyBhZ2FpblxuICAgICAgICAgICAgbm9kZVxuICAgICAgICAgICAgICAgIC5lYWNoIChmdW5jdGlvbiAoZCkge1xuICAgICAgICAgICAgICAgICAgICBjb25mLmxhYmVsLmNhbGwodGhpcywgdG50X3RyZWVfbm9kZShkKSwgY29uZi5sYXlvdXQudHlwZSwgZDMuZnVuY3Rvcihjb25mLm5vZGVfZGlzcGxheS5zaXplKCkpKHRudF90cmVlX25vZGUoZCkpKTtcbiAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICB9KTtcbiAgICB9O1xuXG4gICAgLy8gQVBJXG4gICAgdmFyIGFwaSA9IGFwaWpzICh0KVxuICAgIFx0LmdldHNldCAoY29uZik7XG5cbiAgICAvLyBuIGlzIHRoZSBudW1iZXIgdG8gaW50ZXJwb2xhdGUsIHRoZSBzZWNvbmQgYXJndW1lbnQgY2FuIGJlIGVpdGhlciBcInRyZWVcIiBvciBcInBpeGVsXCIgZGVwZW5kaW5nXG4gICAgLy8gaWYgbiBpcyBzZXQgdG8gdHJlZSB1bml0cyBvciBwaXhlbHMgdW5pdHNcbiAgICBhcGkubWV0aG9kICgnc2NhbGVfYmFyJywgZnVuY3Rpb24gKG4sIHVuaXRzKSB7XG4gICAgICAgIGlmICghdC5sYXlvdXQoKS5zY2FsZSgpKSB7XG4gICAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgICAgaWYgKCF1bml0cykge1xuICAgICAgICAgICAgdW5pdHMgPSBcInBpeGVsXCI7XG4gICAgICAgIH1cbiAgICAgICAgdmFyIHZhbDtcbiAgICAgICAgbGlua3NfZy5zZWxlY3QoXCJwYXRoXCIpXG4gICAgICAgICAgICAuZWFjaChmdW5jdGlvbiAocCkge1xuICAgICAgICAgICAgICAgIHZhciBkID0gdGhpcy5nZXRBdHRyaWJ1dGUoXCJkXCIpO1xuXG4gICAgICAgICAgICAgICAgdmFyIHBhdGhQYXJ0cyA9IGQuc3BsaXQoL1tNTEFdLyk7XG4gICAgICAgICAgICAgICAgdmFyIHRvU3RyID0gcGF0aFBhcnRzLnBvcCgpO1xuICAgICAgICAgICAgICAgIHZhciBmcm9tU3RyID0gcGF0aFBhcnRzLnBvcCgpO1xuXG4gICAgICAgICAgICAgICAgdmFyIGZyb20gPSBmcm9tU3RyLnNwbGl0KFwiLFwiKTtcbiAgICAgICAgICAgICAgICB2YXIgdG8gPSB0b1N0ci5zcGxpdChcIixcIik7XG5cbiAgICAgICAgICAgICAgICB2YXIgZGVsdGFYID0gdG9bMF0gLSBmcm9tWzBdO1xuICAgICAgICAgICAgICAgIHZhciBkZWx0YVkgPSB0b1sxXSAtIGZyb21bMV07XG4gICAgICAgICAgICAgICAgdmFyIHBpeGVsc0Rpc3QgPSBNYXRoLnNxcnQoZGVsdGFYKmRlbHRhWCArIGRlbHRhWSpkZWx0YVkpO1xuXG4gICAgICAgICAgICAgICAgdmFyIHNvdXJjZSA9IHAuc291cmNlO1xuICAgICAgICAgICAgICAgIHZhciB0YXJnZXQgPSBwLnRhcmdldDtcblxuICAgICAgICAgICAgICAgIHZhciBicmFuY2hEaXN0ID0gdGFyZ2V0Ll9yb290X2Rpc3QgLSBzb3VyY2UuX3Jvb3RfZGlzdDtcblxuICAgICAgICAgICAgICAgIC8vIFN1cHBvc2luZyBwaXhlbHNEaXN0IGhhcyBiZWVuIHBhc3NlZFxuICAgICAgICAgICAgICAgIGlmICh1bml0cyA9PT0gXCJwaXhlbFwiKSB7XG4gICAgICAgICAgICAgICAgICAgIHZhbCA9IChicmFuY2hEaXN0IC8gcGl4ZWxzRGlzdCkgKiBuO1xuICAgICAgICAgICAgICAgIH0gZWxzZSBpZiAodW5pdHMgPT09IFwidHJlZVwiKSB7XG4gICAgICAgICAgICAgICAgICAgIHZhbCA9IChwaXhlbHNEaXN0IC8gYnJhbmNoRGlzdCkgKiBuO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgaWYgKGlzTmFOKHZhbCkpIHtcbiAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gdmFsO1xuICAgICAgICB9KTtcblxuICAgIC8vIFRPRE86IFJld3JpdGUgZGF0YSB1c2luZyBnZXRzZXQgLyBmaW5hbGl6ZXJzICYgdHJhbnNmb3Jtc1xuICAgIGFwaS5tZXRob2QgKCdkYXRhJywgZnVuY3Rpb24gKGQpIHtcbiAgICAgICAgaWYgKCFhcmd1bWVudHMubGVuZ3RoKSB7XG4gICAgICAgICAgICByZXR1cm4gYmFzZS5kYXRhO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gVGhlIG9yaWdpbmFsIGRhdGEgaXMgc3RvcmVkIGFzIHRoZSBiYXNlIGFuZCBjdXJyIGRhdGFcbiAgICAgICAgYmFzZS5kYXRhID0gZDtcbiAgICAgICAgY3Vyci5kYXRhID0gZDtcblxuICAgICAgICAvLyBTZXQgdXAgYSBuZXcgdHJlZSBiYXNlZCBvbiB0aGUgZGF0YVxuICAgICAgICB2YXIgbmV3dHJlZSA9IHRudF90cmVlX25vZGUoYmFzZS5kYXRhKTtcblxuICAgICAgICB0LnJvb3QobmV3dHJlZSk7XG4gICAgICAgIGJhc2UudHJlZSA9IG5ld3RyZWU7XG4gICAgICAgIGN1cnIudHJlZSA9IGJhc2UudHJlZTtcblxuICAgICAgICB0cmVlLnRyaWdnZXIoXCJkYXRhOmhhc0NoYW5nZWRcIiwgYmFzZS5kYXRhKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9KTtcblxuICAgIC8vIFRPRE86IFRoaXMgaXMgb25seSBhIGdldHRlclxuICAgIGFwaS5tZXRob2QgKCdyb290JywgZnVuY3Rpb24gKCkge1xuICAgICAgICByZXR1cm4gY3Vyci50cmVlO1xuICAgIH0pO1xuXG4gICAgLy8gYXBpLm1ldGhvZCAoJ3N1YnRyZWUnLCBmdW5jdGlvbiAoY3Vycl9ub2Rlcywga2VlcFNpbmdsZXRvbnMpIHtcbiAgICAvLyAgICAgdmFyIHN1YnRyZWUgPSBiYXNlLnRyZWUuc3VidHJlZShjdXJyX25vZGVzLCBrZWVwU2luZ2xldG9ucyk7XG4gICAgLy8gICAgIGN1cnIuZGF0YSA9IHN1YnRyZWUuZGF0YSgpO1xuICAgIC8vICAgICBjdXJyLnRyZWUgPSBzdWJ0cmVlO1xuICAgIC8vXG4gICAgLy8gICAgIHJldHVybiB0aGlzO1xuICAgIC8vIH0pO1xuXG4gICAgLy8gYXBpLm1ldGhvZCAoJ3Jlcm9vdCcsIGZ1bmN0aW9uIChub2RlLCBrZWVwU2luZ2xldG9ucykge1xuICAgIC8vICAgICAvLyBmaW5kXG4gICAgLy8gICAgIHZhciByb290ID0gdC5yb290KCk7XG4gICAgLy8gICAgIHZhciBmb3VuZF9ub2RlID0gdC5yb290KCkuZmluZF9ub2RlKGZ1bmN0aW9uIChuKSB7XG4gICAgLy8gICAgICAgICByZXR1cm4gbm9kZS5pZCgpID09PSBuLmlkKCk7XG4gICAgLy8gICAgIH0pO1xuICAgIC8vICAgICB2YXIgc3VidHJlZSA9IHJvb3Quc3VidHJlZShmb3VuZF9ub2RlLmdldF9hbGxfbGVhdmVzKCksIGtlZXBTaW5nbGV0b25zKTtcbiAgICAvL1xuICAgIC8vICAgICByZXR1cm4gc3VidHJlZTtcbiAgICAvLyB9KTtcblxuICAgIHJldHVybiBkMy5yZWJpbmQgKHQsIGRpc3BhdGNoLCBcIm9uXCIpO1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSBleHBvcnRzID0gdHJlZTtcbiJdfQ==
