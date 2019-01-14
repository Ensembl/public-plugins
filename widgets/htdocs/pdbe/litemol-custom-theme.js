var LiteMol;
(function (LiteMol) {
    var Core;
    (function (Core) {
        var Utils;
        (function (Utils) {
            "use strict";
            function createMapObject() {
                var map = Object.create(null);
                // to cause deoptimization as we don't want to create hidden classes
                map["__"] = void 0;
                delete map["__"];
                return map;
            }
            var FastMap;
            (function (FastMap) {
                function forEach(data, f, ctx) {
                    var hasOwn = Object.prototype.hasOwnProperty;
                    for (var _i = 0, _a = Object.keys(data); _i < _a.length; _i++) {
                        var key = _a[_i];
                        if (!hasOwn.call(data, key))
                            continue;
                        var v = data[key];
                        if (v === void 0)
                            continue;
                        f(v, key, ctx);
                    }
                }
                var fastMap = {
                    set: function (key, v) {
                        if (this.data[key] === void 0 && v !== void 0) {
                            this.size++;
                        }
                        this.data[key] = v;
                    },
                    get: function (key) {
                        return this.data[key];
                    },
                    delete: function (key) {
                        if (this.data[key] === void 0)
                            return false;
                        delete this.data[key];
                        this.size--;
                        return true;
                    },
                    has: function (key) {
                        return this.data[key] !== void 0;
                    },
                    clear: function () {
                        this.data = createMapObject();
                        this.size = 0;
                    },
                    forEach: function (f, ctx) {
                        forEach(this.data, f, ctx !== void 0 ? ctx : void 0);
                    }
                };
 /**
 *                  * Creates an empty map.
 *                                   */
  function create() {
                    var ret = Object.create(fastMap);
                    ret.data = createMapObject();
                    ret.size = 0;
                    return ret;
                }
                FastMap.create = create;
                /**
 *                  * Create a map from an array of the form [[key, value], ...]
 *                                   */
                function ofArray(data) {
                    var ret = create();
                    for (var _i = 0, data_1 = data; _i < data_1.length; _i++) {
                        var xs = data_1[_i];
                        ret.set(xs[0], xs[1]);
                    }
                    return ret;
                }
                FastMap.ofArray = ofArray;
                /**
 *                  * Create a map from an object of the form { key: value, ... }
 *                                   */
                function ofObject(data) {
                    var ret = create();
                    var hasOwn = Object.prototype.hasOwnProperty;
                    for (var _i = 0, _a = Object.keys(data); _i < _a.length; _i++) {
                        var key = _a[_i];
                        if (!hasOwn.call(data, key))
                            continue;
                        var v = data[key];
                        ret.set(key, v);
                    }
                    return ret;
                }
                FastMap.ofObject = ofObject;
            })(FastMap = Utils.FastMap || (Utils.FastMap = {}));
            var FastSet;
            (function (FastSet) {
                function forEach(data, f, ctx) {
                    var hasOwn = Object.prototype.hasOwnProperty;
                    for (var _i = 0, _a = Object.keys(data); _i < _a.length; _i++) {
                        var p = _a[_i];
                        if (!hasOwn.call(data, p) || data[p] !== null)
                            continue;
                        f(p, ctx);
                    }
                }
                /**
 *                  * Uses null for present values.
 *                                   */
                var fastSet = {
                    add: function (key) {
                        if (this.data[key] === null)
                            return false;
                        this.data[key] = null;
                        this.size++;
                        return true;
                    },
                    delete: function (key) {
                        if (this.data[key] !== null)
                            return false;
                        delete this.data[key];
                        this.size--;
                        return true;
                    },
                    has: function (key) {
                        return this.data[key] === null;
                    },
                    clear: function () {
                        this.data = createMapObject();
                        this.size = 0;
                    },
                    forEach: function (f, ctx) {
                        forEach(this.data, f, ctx !== void 0 ? ctx : void 0);
                    }
                };
                /**
                 * Create an empty set.
                 */
                function create() {
                    var ret = Object.create(fastSet);
                    ret.data = createMapObject();
                    ret.size = 0;
                    return ret;
                }
                FastSet.create = create;
                /**
                 * Create a set of an "array like" sequence.
                 */
                function ofArray(xs) {
                    var ret = create();
                    for (var i = 0, l = xs.length; i < l; i++) {
                        ret.add(xs[i]);
                    }
                    return ret;
                }
                FastSet.ofArray = ofArray;
            })(FastSet = Utils.FastSet || (Utils.FastSet = {}));
        })(Utils = Core.Utils || (Core.Utils = {}));
    })(Core = LiteMol.Core || (LiteMol.Core = {}));
})(LiteMol || (LiteMol = {}));

var LiteMolPluginInstance;
(function (LiteMolPluginInstance) {
    var CustomTheme;
    (function (CustomTheme) {
        var Core = LiteMol.Core;
        var Visualization = LiteMol.Visualization;
        var Bootstrap = LiteMol.Bootstrap;
        var Q = Core.Structure.Query;
        var ColorMapper = (function () {
            function ColorMapper() {
                this.uniqueColors = [];
                this.map = Core.Utils.FastMap.create();
            }
            Object.defineProperty(ColorMapper.prototype, "colorMap", {
                get: function () {
                    var map = Core.Utils.FastMap.create();
                    this.uniqueColors.forEach(function (c, i) { return map.set(i, c); });
                    return map;
                },
                enumerable: true,
                configurable: true
            });
            ColorMapper.prototype.addColor = function (color) {
                var id = color.r + "-" + color.g + "-" + color.b;
                if (this.map.has(id))
                    return this.map.get(id);
                var index = this.uniqueColors.length;
                this.uniqueColors.push(Visualization.Color.fromRgb(color.r, color.g, color.b));
                this.map.set(id, index);
                return index;
            };
            return ColorMapper;
        }());
        function createTheme(model, colorDef) {
            var mapper = new ColorMapper();
            mapper.addColor(colorDef.base);
            var map = new Uint8Array(model.atoms.count);
            for (var _i = 0, _a = colorDef.entries; _i < _a.length; _i++) {
                var e = _a[_i];
                var query = Q.sequence(e.entity_id.toString(), e.struct_asym_id, { seqNumber: e.start_residue_number }, { seqNumber: e.end_residue_number }).compile();
                var colorIndex = mapper.addColor(e.color);
                for (var _b = 0, _c = query(model.queryContext).fragments; _b < _c.length; _b++) {
                    var f = _c[_b];
                    for (var _d = 0, _e = f.atomIndices; _d < _e.length; _d++) {
                        var a = _e[_d];
                        map[a] = colorIndex;
                    }
                }
            }
            var fallbackColor = { r: 0.6, g: 0.6, b: 0.6 };
            var selectionColor = { r: 0, g: 0, b: 1 };
            var highlightColor = { r: 1, g: 0, b: 1 };
            var colors = Core.Utils.FastMap.create();
            colors.set('Uniform', fallbackColor);
            colors.set('Selection', selectionColor);
            colors.set('Highlight', highlightColor);
            var mapping = Visualization.Theme.createColorMapMapping(function (i) { return map[i]; }, mapper.colorMap, fallbackColor);
            return Visualization.Theme.createMapping(mapping, { colors: colors });
        }
        CustomTheme.createTheme = createTheme;
        function applyTheme(plugin, modelRef, theme) {
            var visuals = plugin.context.select(Bootstrap.Tree.Selection.byRef(modelRef).subtree().ofType(Bootstrap.Entity.Molecule.Visual));
            for (var _i = 0, visuals_2 = visuals; _i < visuals_2.length; _i++) {
                var v = visuals_2[_i];
                Bootstrap.Command.Visual.UpdateBasicTheme.dispatch(plugin.context, { visual: v, theme: theme });
            }
        }
        CustomTheme.applyTheme = applyTheme;
    })(CustomTheme = LiteMolPluginInstance.CustomTheme || (LiteMolPluginInstance.CustomTheme = {}));
})(LiteMolPluginInstance || (LiteMolPluginInstance = {}));
