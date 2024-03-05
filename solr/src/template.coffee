# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Directive
  constructor: (@selector,value,@loopvars) ->
    @loopvars ?= []
    if typeof(value) == 'string'
      @value = value.split('.')
    else if $.isFunction(value)
      @value = value
    else
      for k,v of value
        m = /^(.*)\<\-(.*)$/g.exec(k)
        if m.length
          [@loopvar,@list] = [m[1],m[2].split(".")]
          @subs = ( new Directive(sk,sv,@loopvars.concat([@loopvar])) for sk,sv of v )

  _accessor: (value,model_context) ->
    (if $.inArray(value[0],@loopvars) != -1
      value
    else
      model_context.concat(value)
    ).join('.')

  emit: (model_context,view_context) ->
    if @loopvar
      inner = {}
      ik = @loopvar+"<-"+@_accessor(@list,model_context)
      value = {}
      value[ik] = {}
      for sub in @subs
        [k,v] = sub.emit(model_context,[])
        value[ik][k] = v
    else if $.isArray(@value)
      value = @_accessor(@value,model_context)
    else
      real = @value
      value = (e) ->
        context = e.context
        context = context[x] for x in model_context
        f = $.extend({},e,{ context })
        real.call(@,f)
    [view_context.concat([@selector]).join(' '),value]

class Component
  constructor: (@registry,@spec,@name) ->
    @template = $($.trim(@spec.template ? "<div></div>"))
    @directives = @_directives_from_spec(@spec) ? {}
    @submap = @spec.subtemplates ? {}
    @sockets = {}
    @sockets[v] = k for k,v of (@spec.sockets ? {})
    @config = @spec.config ? {}
    @postproc = @spec.postproc ? (el,data) ->
    @decorate = @spec.decorate ? {}
    @extends = @spec.extends
    @fixes = @spec.fixes
    @more_fixes = @spec.more_fixes

  resolved: ->
    if @extends?
      parent = @registry.get(@extends)
      if parent?
        @spec[k] = v for k,v of parent.spec when not @spec[k]?
        @spec.super = parent.spec
      delete @extends
      return new Component(@registry,@spec,@name)
    else
      @
 
  run_preproc: (data) ->
    spec = @spec
    if @spec.preproc?
      [spec,data] = @spec.preproc(@spec,data)
    [new Component(@registry,spec,@name),data]

  emit_directives: (model_context,view_context) ->
    out = {}
    for d in @directives
      [k,v] = d.emit(model_context,view_context)
      out[k] = v
    out

  _directives_from_spec: (spec) ->
    out = []
    out.push(new Directive(k,v)) for k,v of spec.directives
    out

  get_config: (key,data) -> 
    if $.isFunction(@config[key])
      @config[key](data)
    else
      @config[key]

  submap_get: -> @submap
  decorate_get: -> @decorate
  postproc_get: -> @postproc
  has_socket: (s) -> @sockets[s]?
  get_socket: (s) -> @sockets[s]
  get_fixes: -> @fixes
  get_more_fixes: -> (@registry.get(k) for k in ( @more_fixes ? [] ))

  emit_template: (klass) ->
    out = @template.clone()
    out.addClass(klass)
    out

  get_parent: ->
    if @extends?
      @parent = @registry.get(@extends)
      @extends = undefined
    @parent

  make_part: (assembly,model_context,base_vc,sub_vc,parent) ->
    new Part(assembly,@,model_context,base_vc,sub_vc,parent)

  get_all_subs: (_seen) ->
    _seen ?= {}
    out = []
    for k,v of @submap
      for t in v
        unless _seen[t.template]
          out.concat(@registry.get(t.template).get_all_subs(_seen))
    out.push(@)
    _seen[@name] = 1
    out

next_class_id_idx = 1

class Part
  constructor: (@assembly,@component,@model_context,base_vc,@sub_vc,@parent) ->
    @children = []
    if @parent? then @parent.children.push(@)
    @klass = "__tmplcl__#{next_class_id_idx += 1}"
    @view_context = base_vc.concat(@sub_vc)
    submap = @component.submap_get()
    @subs = []
    for k,v of submap
      if !$.isArray(v) then v = [v]
      for s in v
        @add_subtemplate(k,s)

  find_sockets_in_subtree: (socket,ret) ->
    if @component.has_socket(socket)
      ret.push([@,@component.get_socket(socket)])
    for c in @children
      c.find_sockets_in_subtree(socket,ret)

  find_sockets: (socket,ret) ->
    if socket?
      if @parent
        @parent.find_sockets(socket,ret)
      else
        @find_sockets_in_subtree(socket,ret)
    return []


  add_subtemplate: (k,v) ->
    if k.length and k.charAt(0) == '^'
      k = k.substring(1)
      plug = k
    if typeof v == 'string' then v = { template: v, data: v }
    sockets = []
    @find_sockets(plug,sockets)
    if sockets.length == 0 then sockets.push([@,k])
    for [dest_part,dest_sel] in sockets
      dest_sel = dest_sel.split(' ')
      if v.data != ''
        sub_mc = @model_context.concat(v.data.split('.'))
      else
        sub_mc = @model_context
      sub_comp = @assembly.registry_get(v.template,sub_mc)
      dest_part.subs.push(sub_comp.make_part(@assembly,sub_mc,dest_part.view_context,dest_sel,dest_part))
      
  emit_directives: ->
    dirs = @component.emit_directives(@model_context,["."+@klass])
    for s in @subs
      dirs[a] = b for a,b of s.emit_directives()
    dirs

  emit_template: ->
    template = @component.emit_template(@klass)
    for s in @subs
      $(s.sub_vc.join(' '),template).append(s.emit_template())
    template

  run_postproc: (el,data) ->
    s.run_postproc(el,data) for s in @subs
    sub_data = data
    sub_data = sub_data[k] for k in @model_context
    sub_el = el
    if @sub_vc.length then sub_el = $('.'+@klass,el)
    for sel,fun of @component.decorate_get()
      fun.call(@,$(sel,sub_el),sub_data)
    @component.postproc_get().call(@,sub_el,sub_data)

class Assembly
  constructor: (@registry,@name,@data) ->

  get_fixes: (type,comp) ->
    fixes = []
    for sub in comp.get_all_subs()
      f = sub.get_fixes()?[type]
      if f? then fixes = fixes.concat(f)
      for c in comp.get_more_fixes()
        fixes = fixes.concat(@get_fixes(type,c))
    return fixes

  run_fixes: (comp,data,trigger) ->
    data.tp2 = new TextProc2()
    data.tp2_row = new TextProc2()
    fixes = @get_fixes(trigger ? 'global',comp)
    f.call(@,data) for f in fixes
    # XXX
    if data.table_row?
      for r in data.table_row
        tp2_row_out = data.tp2_row.run(r.cols)
        r[k] = v for k,v of tp2_row_out
        if r.cols?
          r.cols[k] = v for k,v of tp2_row_out
    tp2_out = data.tp2.run(data)
    data[k] = v for k,v of tp2_out
    if data.cols?
      data.cols[k] = v for k,v of tp2_out
    return data

  generate: (attach) ->
    root_comp = @registry_get(@name,[])
    @data = @run_fixes(root_comp,@data)
    all_subs = root_comp.get_all_subs()
    root_part = root_comp.make_part(@,[],[],[],undefined)
    template = root_part.emit_template()
    template = template.wrap("<div></div>").parent()
    out = template.render(@data,root_part.emit_directives())
    if attach? then attach(out)
    root_part.run_postproc(out,@data)
    out

  _read: (path) ->
    data = @data
    data = data?[k] ? undefined for k in path
    data

  _write: (path,value) ->
    if path.length
      data = @_read(path.slice(0,path.length-1))
      if data? then data[path[path.length-1]] = value
    else
      @data = value

  registry_get: (name,model_context) ->
    data = @_read(model_context)
    [spec,data] = @registry.get(name).run_preproc(data)
    @_write(model_context,data)
    spec

class Registry
  constructor: (sets) ->
    @registry = {}
    @register_sets(sets)

  register_sets: (sets) -> @register_all(s) for s in sets
  register_all: (specs) -> @register(k,v) for k,v of specs    
  register: (name,spec) ->
    @registry[name] = new Component(@,spec,name)
  
  get: (name) ->
    if @registry[name]?
      @registry[name] = @registry[name].resolved()
    @registry[name]

  generate: (name,data,attach) ->
    a = new Assembly(@,name,data)
    a.generate(attach)

  config: (name,key,data) -> @get(name).get_config(key,data)

window.Templates = Registry

