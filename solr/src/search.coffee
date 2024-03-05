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

#
code_select = -> $('#solr_config').length > 0

_kv_copy = (old) -> out = {}; out[k] = v for k,v of old; out

_clone_array = (a) -> $.extend(true,[],a)
_clone_object = (a) -> $.extend(true,{},a)

class Hub
  _pair: /([^;&=]+)=?([^;&]*)/g
  _decode: (s) -> decodeURIComponent s.replace(/\+/g," ")
  _encode: (s) -> encodeURIComponent(s).replace(/\ /g,"+")

  _params_used = {
    q:       ['results']
    page:    ['results']
    perpage: ['results']
    sort:    ['results']
    species: ['results']
    facet:   ['results','species']
    columns: ['results']
    style:   ['style']
  }

  _section_keys = {
    facet: /^facet_(.*)/
    fall: /^fall_(.*)/
  }

  _style_map = {
    'standard': ['page','fixes','table','google','pedestrian','rhs']
    'table':    ['page','fixes','table','pedestrian','rhs']
  }

  constructor: (more) ->
    config_url = "#{ $('#species_path').val() }/Ajax/config"
    @ga_init()
    $.when(
      $.solr_config({ url: config_url })
      $.getScript('/pure/pure.js')
    ).done () =>
      @params = {}
      @sections = {}
      @interest = {}
      @first_service = 1
      @source = new Request(@)
      @renderer = new Renderer(@,@source)
      $(window).bind('popstate',((e) => @service()))
      $(document).ajaxError => @fail()
      @spin = 0
      @leaving = 0
      $(window).unload(() -> @leaving = 1)
      $(document).on 'force_state_change', () =>
        $(document).trigger('state_change',[@params])
      more(@)

  ga_init: ->
    if Ensembl.GA
      @ga = new Ensembl.GA.EventConfig({
        category: (-> this.category),
        action: (-> this.action),
        label: (-> this.label),
        value: (-> this.value),
        nonInteraction: false
      })

  code_select: -> code_select

  spin_up: ->
    if @spin == 0
      $('.hub_fail').hide()
      $('.hub_spinner').show()
    @spin += 1

  spin_down: ->
    if @spin > 0 then @spin -= 1
    if @spin == 0 then $('.hub_spinner').hide()

  fail: ->
    if @leaving then return # don't show failed during click away
    $('.hub_spinner').hide()
    #$('.hub_fail').show()

  unfail: ->
    $('.hub_fail').hide()
    if @spin then $('.hub_spinner').show()

  register_interest: (key,fn) ->
    @interest[key] ?= []
    @interest[key].push(fn)

  activate_interest: (key,value) ->
    w.call(@,key) for w in ( @interest[key] ? [] )

  render_stage: (more) ->
    @set_templates(@layout())
    if @useless_browser() then $('#solr_content').addClass('solr_useless_browser')
    $(document).on 'update_state', (e,qps) =>
      @update_url(qps)
    $(document).on 'ga', (e,category,action,label='',value=1) =>
      if not @ga or not Ensembl.GA then return
      Ensembl.GA.sendEvent(@ga,{ category, action, label, value })
    $(document).on 'update_state_incr', (e,qps) =>
      rate_limiter(qps).then((data) => @update_url(data))
    @renderer.render_stage(more)

  _add_changed: (changed,k) ->
    if _params_used[k]
      changed[a] = 1 for a in _params_used[k]
    changed[k] = 1

  set_templates: (style) ->
    @cstyle = style
    src = _style_map[style]
    @tmpl = new window.Templates((window[k+"_templates"] ? window[k] for k in src))

  templates: -> @tmpl

  add_implicit_params: ->
    hub = @
    any = 0
    $('#solr_context span').each ->
      j = $(@)
      if j.text() and not hub.params[@id]?
        hub.params[@id] = j.text()
        any = 1
      j.remove()
    return any

  refresh_params: ->
    changed = {}
    old_params = _kv_copy(@params)
    old_sections = {}
    old_sections[x] = _kv_copy(@sections[x]) for x of @sections
    @params = {}
    @sections = {}
    @_pair.lastIndex = 0
    if window.location.hash.indexOf('=') != -1
      param_source = window.location.hash.substring(1)
    else
      param_source = window.location.search.substring(1)
    while m = @_pair.exec param_source
      @params[@_decode(m[1])] = @_decode(m[2])
    if @add_implicit_params()
      @replace_url({})
    @ddg_style_search()
    for section, match of _section_keys
      match.lastIndex = 0
      @sections[section] = {}
      @sections[section][m[1]] = @params[p] for p of @params when m = match.exec(p)
    @_add_changed(changed,k) for k,v of old_params when @params[k] != old_params[k]
    @_add_changed(changed,k) for k,v of @params when @params[k] != old_params[k]
    for section of _section_keys
      a = @sections[section] ? {}
      b = old_sections[section] ? {}
      @_add_changed(changed,section) for k,v of a when a[k] != b[k]
      @_add_changed(changed,section) for k,v of b when a[k] != b[k]
    return changed

  remove_unused_params: ->
    changed = {}
    changed[k] = undefined for k in ['species','idx'] when @params[k]?
    if (k for k,v of changed).length
      @replace_url(changed)

  layout: -> @params.style ? 'standard'

  query: -> @params['q']
  species: -> @params['species'] ? ''
  sort: -> @params['sort']
  page: -> if @params['page']? then parseInt(@params['page']) else 1
  per_page: ->
    parseInt(@params['perpage'] ? $.solr_config('static.ui.per_page'))
  fall: (type) -> @sections['fall'][type]?
  base: -> @config('base')['url']
  columns: ->
    if @params['columns']
      @params['columns'].split('*')
    else
      $.solr_config('static.ui.columns')

  fix_species_url: (url,actions) ->
    base = ''
    main = url.replace(/^(https?\:\/\/[^/]+)/,((g0,g1) -> base = g1; '' ))
    if main.length == 0 or main.charAt(0) != '/'
      return url
    parts = main.split('/')
    for pos,repl of actions
      parts[parseInt(pos)+1] = repl
    main = parts.join('/')
    return base + main

  make_url: (qps) ->
    url = window.location.href.replace(/\?.*$/,"")+"?"
    url += ("#{@_encode(a)}=#{@_encode(b)}" for a,b of qps).join(';')
    # Species fix XXX make more generic
    species = 'Multi'
    if qps['facet_species']? and qps['facet_species'] != 'CrossSpecies'
      species = qps['facet_species']
    url = @fix_species_url(url,{0: species })
    url

  fake_history: () -> !(window.history && window.history.pushState)

  set_hash: (v) ->
    w = window.location
    if v.length
      w.hash = v
    else
      w.href = w.href.substr(0,w.href.indexOf('#')+1)

  fake_history_onload: () ->
    if @fake_history()
      # Transfer any QPs into a hash via reload.
      @set_hash(window.location.search.substring(1))
      unless window.location.search.length > 1
        # Bug in hash rewriting code when no params, so insert fake one
        window.location.search = 'p=1'
    else if window.location.href.indexOf('#') != -1
      @set_hash('')

  update_url: (changes,service = 1) ->
    qps = _kv_copy(@params)
    if qps.perpage? and parseInt(qps.perpage) == 0
      qps.perpage = $.solr_config('static.ui.pagesizes')[0]
    qps[k] = v for k,v of changes when v?
    delete qps[k] for k,v of changes when not v
    url = @make_url(qps)
    if @really_useless_browser()
      window.location.hash = url.substring(url.indexOf('?')+1)
    else
      if @fake_history()
        window.location.hash = url.substring(url.indexOf('?')+1)
      else
        window.history.pushState({},'',url)
    if service then @service()
    url

  replace_url: (changes) ->
    qps = _kv_copy(@params)
    qps[k] = v for k,v of changes when v?
    delete qps[k] for k,v of changes when not v
    url = @make_url(qps)
    if @really_useless_browser()
      window.location.hash = url.substring(url.indexOf('?')+1)
    else
      if @fake_history()
        window.location.hash = url.substring(url.indexOf('?')+1)
      else
        window.history.replaceState({},'',url)
    url

  sidebar_div: -> $('#solr_sidebar')

  useless_browser: () -> # IE8--, too daft for fancy bits (preview, etc)
    if document.documentMode? and document.documentMode < 9
      return true # IE8 or IE9 in an emulation mode
    return @really_useless_browser()

  really_useless_browser: () -> # IE7--, too daft for URL manipulation, &c
    if $('body').hasClass('ie67')
      return true
    return false

  configs: {}

  config: (key) ->
    unless @configs[key]?
      @configs[key] = $.parseJSON($("#solr_config span.#{key}").text() ? '{}')
    @configs[key]

  request: -> @source

  current_facets: ->
    out = {}
    for k,v of @sections['facet']
      if v then out[k] = v
    return out

  ddg_style_search: ->
    if @params.species # Detect off-page submissions. Ugh! XXX
      delete @params.species
      ddg = []
      @params.q = @params.q.replace(/!([a-z]+)/g, (g0,g1) ->
        ddg.push(g1)
        ''
      )
      for key,map of $.solr_config('static.ui.ddg_codes')
        for code in ddg
          if map[code]?
            @params[key] = map[code]

  service: ->
    if @first_service
      if document.documentMode and document.documentMode < 8
        $('body').addClass('ie67') # IE8+ in dumb mode
      @fake_history_onload()
    changed = @refresh_params()
    @ddg_style_search()
    @remove_unused_params()
    request = @request()
    if @first_service
      if parseInt(@params.perpage) == 0 # Override "all" on first load
        @replace_url({ perpage: 10 })
        @params.perpage = $.solr_config('static.ui.pagesizes')[0]
      @render_stage( =>
        @actions(request,changed)
      )
      @first_service = 0
    else
      @actions(request,changed)

  actions: (request,changed) ->
    if changed['results'] then @renderer.render_results()
    if changed['style']
      if @cstyle != @params.style
        window.location.href = @make_url(@params)
    @fix_species_search()
    @activate_interest(k) for k,v of changed
    $(document).trigger('state_change',[@params])
    $(window).scrollTop(0)

  fix_species_search: ->
    if not $.solr_config('static.ui.topright_fix') then return
    if @params.facet_species
      unless $('.site_menu .ensembl').length
        $menu = $('.site_menu')
        $menu.prepend($menu.find('.ensembl_all')
          .clone(true).addClass('ensembl').removeClass('ensembl_all'))
      $spec = $('.site_menu .ensembl')
      window.sp_names @params.facet_species, (names) =>
        if !names then return
        $img = $('img',$spec).attr("src","/i/species/#{names.url}.png")
        $input = $('input',$spec).val("Search #{@params.facet_species}…")
        $spec.empty().append($img).append("Search #{@params.facet_species}")
          .append($input)
        $spec.trigger('click') # update box via SeachPanel
        $spec.parents('form').attr('action',"/#{@params.facet_species}/psychic")
    else
      $('.site_menu .ensembl').remove()
      $('.site_menu .ensembl_all').trigger('click') # Update box via SearchPanel
      $('.site_menu').parents('form').attr('action',"/Multi/psychic")

# XXX protect page in rerequest
# XXX clear and spin during rerequest
# XXX no results

# XXX local sort
# Send queries
# XXX more generic cache

# XXX when failure
each_block = (num,fn) ->
  requests = []
  for i in [0...num]
    requests.push(fn(i))
  return $.when.apply($,requests).then (args...) ->
    Array.prototype.slice.call(args)

# XXX low-level cache

body_embeded_species = () ->
  sp_home = (input,request,start,len) ->
    if start == -1 # size request
      return $.Deferred().resolve([input,if input.english then 1 else 0])
    else
      if input.english
        return $.Deferred().resolve([input,[{
            name: input.english
            description: input.english+" species home page for full details of "+input.english+" resources in Ensembl"
            domain_url: '/'+input.latin
            db: 'none'
            id: input.latin
            species: input.english
            feature_type: 'Species Home Page'
            result_style: 'result-type-species-homepage'
        }]])
      else
        return $.Deferred.resolve([{},{}])
          
  return {
    context: (state,update_seq) ->
      latin = null
      for k,v of $.solr_config('spnames')
        if state.q_query().match(new RegExp("\\b#{k}\\b","gi"))
          latin = v
          english = $.solr_config('revspnames.%',latin)
      return { state, update_seq, latin, english }

    prepare: (context,input,tags_in,depart) ->
      if !tags_in.main then return null
      if context.english?
        if not tags_in.target_species? then tags_in.target_species = []
        tags_in.target_species.push(context.english)
      queries = [[input,tags_in,depart]]
      if context.english
        queries.unshift [{ english: context.english, latin: context.latin },{ sphome: 1 },sp_home]
      return queries
  }

body_hgvs_names = () ->
  hgvs_name = (input,request,start,len) ->
    if start == -1
      return $.Deferred().resolve([input,1])
    else
      id = input.id
      return request.raw_ajax({ id },'hgvs').then (data) =>
        if data.links.length
          list = "<ul>"
          for m in data.links ? []
            list += '<li><a href="'+m.url+'">'+m.text+'</a>'+(m.tail ? '')+'</li>'
          list += "</ul>"
          return [input,[{
            name: "HGVS Identifier"
            description: "'#{data.id}' is an HGVS identifier."+list
            result_style: 'result-type-species-homepage no-preview'
            id: data.id
          }]]
        else
          return [input,[]]

  return {
    context: (state,update_seq) ->
      return { state, update_seq }

    prepare: (context,input,tags_in,depart) ->
      if !tags_in.main then return null
      queries = [[input,tags_in,depart]]
      id = input.q
      if id.match(/^ENS[GTP]\d{11}\S*[cgp]\./) or
         id.match(/^(\d{1,2}|[A-Z])\:g\./) or
         id.match(/^[A-Z]{2}\_\d{5,}\S*\:[cgp]\./)
        queries.unshift [{ id: input.q },{},hgvs_name]
      return queries
  }

body_elevate_quoted = () ->
  return {
    context: (state,update_seq) -> return { state, update_seq }
    prepare: (context,input,tags_in,depart) ->
      if !tags_in.main then return null
      if !input.q.match(/[^\w\s]/) then return null
      if input.q.match(/"/) then return null # already quoted, don't mess
      qq = '"'+input.q.replace(/\s+/,'" "','g')+'"'
      tags_quoted = _clone_object(tags_in)
      tags_quoted.quoted = 1
      input_quoted   = _clone_object(input)
      input_quoted.q = qq
      input_unquoted   = _clone_object(input)
      input_unquoted.q = input.q+' AND ( NOT ( '+qq+' ) )'
      return [[input_quoted,  tags_quoted,depart]
              [input_unquoted,tags_in,    depart]]
  }

traditional_boost = (q,field,values,boost) ->
  bq = []
  for s,i in values
    v = boost*(values.length-i-1)/(values.length-1)
    v = Math.floor(Math.pow(v,1.25))
    bq.push(field+':"'+s+'"'+(if v then "^"+v else ""))
  q.push("( "+bq.join(" OR ")+" )")
  return q

# Only better in the limited circumstances in which it works!
better_boost = (q,field,values,boost) ->
  out = []
  for s,i in values
    v = boost*(values.length-i-1)/(values.length-1)
    v = Math.floor(Math.pow(v,1.25))
    if v then v = '^'+v else v = ''
    out.push("#{q[0]}#{v} AND #{field}:\"#{s}\"")
  out = ( "( "+x+" )" for x in out).join(' OR ')
  return [out]

add_extra_constraints = (q_in,fq_in,extra) ->
  q = [q_in]
  fq = fq_in[..]
  # Which boost should we use (if any)
  use_better_boost = true
  if q_in.match(/[ \t]/)
    use_better_boost = false
  if q_in.match(/^(\w+:)?"[\w ]+"$/)
    use_better_boost = true
  for [field,invert,values,boost] in extra
    # Add to facets (fq=)
    data = $.solr_config('static.ui.facets.key=',field)
    parts = []
    for s in values
      part = data.key+':"'+s+'"'
      if data.filter?
        part = " " + part + " AND ( " + data.filter + " ) "
      parts.push(" ( "+part+" ) ")
    str = parts.join(" OR ")
    str = (if invert then "(NOT ( #{str} ))" else "( #{str} )")
    fq.push(str)
    # Add boosts
    bq = []
    if boost?
      if use_better_boost
        q = better_boost(q,field,values,boost)
      else
        q = traditional_boost(q,field,values,boost)
  if q.length > 1
    q = ( "( "+x+" )" for x in q).join(" AND ")
  [q,fq]

body_raw_request = () ->
  raw_request = (input,request,start,len) ->
    params = _clone_object(input)
    if start == -1 # size request
      params.start = 0
      params.rows = 10
      return request.raw_ajax(params).then (data) =>
        num = data.result?.response?.numFound
        return [data,num]
    else # regular request
      params.rows = len
      params.start = start
      return request.raw_ajax(params).then (data) =>
        docs = data.result?.response?.docs
        # substitue highlights XXX not here!
        for doc in docs
          snippet = data.result?.highlighting?[doc.uid]
          if snippet?
            for from,to of $.solr_config('static.ui.hl_transfers')
              snippet[to] = snippet[from]
            for h in $.solr_config('static.ui.highlights')
              if snippet[h]
                doc[h] = snippet[h].join(' ... ')
        #
        return [data,docs]

  return {
    prepare: (context,input,tags,depart) ->
      return [[input,tags,raw_request]]
  }

# XXX expire cache
size_cache_q = ""
size_cache = {}
stringify_params = (params) ->
  vals = []
  keys = []
  for k,v of params
    keys.push(k)
  keys.sort()
  for k in keys
    vals.push("0",k)
    vs = params[k]
    if not $.isArray(params[k]) then vs = [""+vs]
    vs.sort()
    for v in vs
      vals.push("1",v)
  out = []
  for v in vals
    out.push(v.length+"-"+v)
  return out.join('')

body_cache = () ->
  try_cache = (orig) ->
    return (input,request,start,len) ->
      if start == -1
        key = stringify_params(input)
        if size_cache[key]?
          return $.Deferred().resolve(size_cache[key])
        else
          return orig(input,request,start,len).then (v) ->
            size_cache[key] = v
            return v
      else
        return orig(input,request,start,len)

  return {
    context: (state,update_seq) ->
      q = state.q_query()
      if size_cache_q != q then size_cache = {}
      size_cache_q = q
      return { state, update_seq }
    prepare: (context,input,tags,depart) ->
      return [[input,tags,try_cache(depart)]]
  }

body_split_favs = () ->
  make_extras = (target) ->
    rigid = []
    favs = _clone_array($.solr_config('user.favs.species'))
    if target? then favs = target.concat(favs)
    if favs.length
      rigid.push ['species',[favs],100]
    return generate_block_list(rigid)
  
  normal_extras = make_extras(null)

  prepare = (context,input_in,tags_in,depart) ->
    tags = _clone_object(tags_in)
    if !tags.main then return null
    tags.blocks = 1
    out = []
    if tags_in.target_species?
      extras = make_extras(tags_in.target_species)
    else
      extras = normal_extras
    for x in extras
      input = _clone_object(input_in)
      [q,fq] = add_extra_constraints(input.q,(k+':"'+v+'"' for k,v of input.fq),x)
      input.q = q
      input.fq = fq
      order = context.state.order()
      if order.length
        input.sort = order[0].column+" "+(if order[0].order>0 then 'asc' else 'desc')
      out.push [input,tags,depart]
    return out

  return {
    context: (state,update_seq) -> return { state, update_seq }
    prepare
  }

body_restrict_categories = () ->
  return {
    context: (state,update_seq) -> return { state, update_seq }
    prepare: (context,input,tags,depart) ->
      types = $.solr_config("static.ui.restrict_facets")
      if types and types.length
        filter = ("feature_type:\"#{x}\"" for x in types).join(" OR ")
        input.q = "#{input.q} AND ( #{filter} )"
      return [[input,tags,depart]]
  }

body_frontpage_specials = () ->
  return {
    context: (state,update_seq) -> return { state, update_seq }
    inspect: (context,requests,docs_frags) ->
      tops = []
      if context.state.start() == 0
        for i in [0...requests.length]
          if requests[i][0] != -1 and tops.length < context.state.pagesize()
            tops = tops.concat(docs_frags[i])
        tops = tops.slice(0,context.state.pagesize())
      if context.update_seq != current_update_seq
        return $.Deferred().reject()
      $(document).trigger('main_front_page',[tops,context.state,context.update_seq])
      return $.Deferred().resolve()
  }

body_highlights = () ->
  add_highlight_fields = (orig) ->
    return (input,request,start,len) ->
      v = orig(input,request,start,len)
      if start != -1
        return v.then ([data,docs]) =>
          # Add _hr highlighting to description
          if data.result?.highlighting?
            for doc in docs
              if doc.uid?
                if data.result.highlighting[doc.uid]
                  if data.result.highlighting[doc.uid]._hr
                    doc.description += ' <div class="result-hr"> ' +
                      data.result.highlighting[doc.uid]._hr.join(" ") +
                      '</div>'
                  for k,v in data.result.highlighting[doc.uid]
                    if k == '_hr' then continue
                    for h in $.solr_config('static.ui.highlights')
                      if doc[h] and snippet[h]
                        doc[h] = snippet[h].join(' ... ')
          return [data,docs]
      return v

  return {
    prepare: (context,input,tags,depart) ->
      if !tags.main then return null
      input.hl = 'true'
      input['hl.fl'] = $.solr_config('static.ui.highlights')
      input['hl.fragsize'] = 500
      tags.highlighted = 1
      return [[input,tags,add_highlight_fields(depart)]]
  }

body_quicklinks = () ->
  add_quicklinks = (orig) ->
    return (input,request,start,len) ->
      v = orig(input,request,start,len)
      if start == -1 then return v
      return v.then ([data,docs]) ->
        for doc in docs
          quicklinks = []
          for link,i in $.solr_config('static.ui.links')
            ok = true
            if should_exclude_from_quicklinks(link.title, doc)
              continue

            # Check if conditions from config are met
            for value,regex of ( link.conditions ? {} )
              lhs = value.replace /\{(.*?)\}/g, (g0,g1) ->
                return doc[g1] ? ''
              if not lhs.match(new RegExp(regex))
                ok = false
                break
            if not ok then continue
            # Check result condition (if any)
            if link.result_condition?
              found = false
              for res in doc.quick_links ? []
                if link.result_condition == res
                  found = true
                  break
              if not found then continue
            if link.result_condition_not?
              for res in doc.quick_links ? []
                if link.result_condition_not == res
                  ok = false
            if not ok then continue
            # Extract URL parts for quicklinks
            if doc.domain_url
              doc['url1'] = doc.domain_url.split('/')[0]
            # Build URL
            url = link.url.replace /\{(.*?)\}/g, (g0,g1) ->
              return doc[g1] ? ''
            quicklinks.push({ url, title: link.title })
          doc.quicklinks = quicklinks
        return [data,docs]

  return {
    prepare: (context,input,tags,depart) ->
      if !tags.main then return null
      return [[input,tags,add_quicklinks(depart)]]
  }

should_exclude_from_quicklinks = (title, doc) ->
  # if a doc contains a quick_links field (which is an array)
  # and if that array contains:
  # - either the string "none" (meaning that no quick links should be shown)
  # - or a string of a format "title: 0"
  # (where title equals the first argument of the function,
  # this quick link should not be shown on the page
  rules = doc.quick_links || []

  for rule in rules
    if rule == 'none'
      return true
    [name, score] = rule.split(':')
    if name == title.toLowerCase() and score == '0'
      return true

  return false

body_elevate_crossspecies = () ->
  return {
    prepare: (context,input,tags,depart) ->
      if tags.main
        if not tags.target_species? then tags.target_species = []
        tags.target_species.unshift("CrossSpecies")
      return [[input,tags,depart]]
  }

body_requests = [
  body_raw_request
  body_cache
  body_embeded_species
  body_hgvs_names
  body_elevate_crossspecies
  body_frontpage_specials
  body_highlights
  body_elevate_quoted
  body_restrict_categories
  body_quicklinks
  body_split_favs
]

run_all_prepares = (contexts,plugins,input) ->
  tags_in = { main: 1 }
  run = $.Callbacks("once")
  input = [[input,tags_in,run,null]]
  for p,i in plugins
    if p.prepare?
      output = []
      for query in input
        v = p.prepare(contexts[i],query[0],query[1],query[2])
        if !v then v = [query]
        output = output.concat(v)
      input = output
  return output
 
dispatch_main_requests = (request,state,table,update_seq) ->
  plugins = (b() for b in body_requests)
  # Determine what the blocks are to be: XXX cache this
  contexts = []
  prepares = []
  for p,i in plugins
    contexts.push(if p.context? then p.context(state,update_seq) else null)
  prepares =
    run_all_prepares(contexts,plugins,{ q: state.q_query(), fq: state.q_facets() })
  blocks = []
  for pr in prepares
    ((pp) ->
      blocks.push (request,start,len) ->
        pp[2](pp[0],request,start,len).then((data) -> data[1])
    )(pr)
  # Calculate block sizes
  total = 0
  ret = $.Deferred().resolve()
  ret = ret.then () =>
    each_block blocks.length,(i) =>
      return blocks[i](request,-1)
        .then (data) ->
          total += data
          return data
  return ret.then (sizes) =>
    if update_seq != current_update_seq then return $.Deferred().reject()
    $(document).trigger('num_known',[total,state,update_seq])
    # Calculate the requests we will make
    requests = []
    offset = 0
    rows_left = state.pagesize()
    for i in [0...blocks.length]
      if state.start() < offset+sizes[i] and state.start()+state.pagesize() > offset
        local_offset = state.start() - offset
        if local_offset < 0 then local_offset = 0
        requests.push [local_offset,rows_left]
        rows_left -= sizes[i] - local_offset
      else
        requests.push [-1,-1]
      offset += sizes[i]
    # Make the requests
    results = each_block blocks.length, (i) =>
      if requests[i][0] != -1
        blocks[i](request,requests[i][0],requests[i][1])
    # Run inspects from plugins
    results = results.then (docs_frags) =>
      each_block plugins.length, (i) =>
          if plugins[i].inspect?
            plugins[i].inspect(contexts[i],requests,docs_frags)
        .then(() => return docs_frags)
    # XXX order
    return [requests,results]

draw_main_requests = (t,state,requests,results,update_seq) ->
  return results.then((docs_frags) ->
    if update_seq != current_update_seq then return $.Deferred().reject()
    each_block requests.length,(i) =>
      if requests[i][0] != -1
        return t.draw_rows({ rows: docs_frags[i], cols: state.columns() })
      else
        return $.Deferred().resolve(null)
  )

dispatch_draw_main = (request,state,table,update_seq) ->
  t = table.xxx_table()
  t.reset()
  dispatch_main_requests(request,state,table,update_seq).then ([req,res]) =>
    draw_main_requests(t,state,req,res,update_seq)

# TODO plugin mechanism for these as well
dispatch_facet_request = (request,state,table,update_seq) ->
  fq = ("#{k}:\"#{v}\"" for k,v of state.q_facets()).join(' AND ')
  q = state.q_query()
  # This is a hack to get around a SOLR BUG
  q = "( NOT species:xxx ) AND ( #{q} ) AND ( NOT species:yyy )"
  
  types = $.solr_config("static.ui.restrict_facets")
  if types and types.length
    filter = ("feature_type:\"#{x}\"" for x in types).join(" OR ")
    q = "#{q} AND ( #{filter} )"
  params = {
    q
    fq
    rows: 1
    'facet.field': (k.key for k in $.solr_config('static.ui.facets'))
    'facet.mincount': 1
    facet: true
  }
  if (params['facet.field'].indexOf('species') > -1 or params['facet.field'].indexOf('strain') > -1)
    # if search facets include species or strains, do not limit the number of results in the response
    params['facet.limit'] = -1
  $(document).trigger('faceting_unknown',[update_seq])
  return request.raw_ajax(params)
    .then (data) =>
      if update_seq != current_update_seq then return $.Deferred().reject()
      all_facets = (k.key for k in $.solr_config('static.ui.facets'))
      facets = state.q_facets()
      $(document).trigger('faceting_known',[data.result?.facet_counts?.facet_fields,facets,data.result?.response?.numFound,state,update_seq])

# Generate the criteria for the various blocks by converting
# configured list to ordered power-set thereof.

generate_block_list = (rigid) ->
  expand_criteria = (criteria,remainder) ->
    if criteria.length == 0 then return [[]]
    [ type,sets,boost ] = criteria[0]
    head = ( [type,false,s,boost] for s in sets )
    head.push([type,true,remainder[type]])
    rec = expand_criteria(criteria.slice(1),remainder)
    all = []
    for r in rec
      for h in head
        out = _clone_array(r)
        out.push(h)
        all.push(out)
    return all

  remainder_criteria = (criteria) ->
    out = {}
    for [type,sets] in criteria
      out[type] = []
      out[type] = out[type].concat(s) for s in sets
    return out

  return expand_criteria(rigid,remainder_criteria(rigid))
 
all_requests = {
  main: dispatch_draw_main
  faceter: dispatch_facet_request
}

dispatch_all_requests = (request,state,table,update_seq) ->
  request.abort_ajax()
  q = state.q_query()
  if q?
    request.some_query()
  else
    request.no_query()
    return $.Deferred().reject()

  # run all plugins
  plugin_list = []
  plugin_actions = []
  $.each all_requests, (k,v) =>
    plugin_list.push k
    plugin_actions.push v(request,state,table,update_seq)
  return $.when.apply(@,plugin_actions)

rate_limiter = window.rate_limiter(1000,2000)

# XXX Faceter orders
# XXX out of date responses / abort
current_update_seq = 0
xhr_idx = 1
class Request
  constructor: (@hub) ->
    @xhrs = {}
  
  req_outstanding: -> (k for k,v of @xhrs).length 

  render_table: (table,state) ->
    current_update_seq += 1
    $(document).data('update_seq',current_update_seq)
    $(document).trigger('state_known',[state,current_update_seq])
    return dispatch_all_requests(@,state,table,current_update_seq)

# XXX shortcircuit get on satisfied
# XXX first page optimise
# XXX table-based compisite renderers

  abort_ajax: ->
    x.abort() for k,x of @xhrs
    if @req_outstanding() then @hub.spin_down()
    @xhrs = {}

  raw_ajax: (params,url) ->
    if not url? then url = 'search'
    url = $('#species_path').val()+"/Ajax/"+url
    idx = (xhr_idx += 1)
    xhr = $.ajax({
      url, data: params,
      traditional: true, dataType: 'json'
    })
    if !@req_outstanding() then @hub.spin_up()
    @xhrs[idx] = xhr
    xhr = xhr.then (data) =>
      delete @xhrs[idx]
      if !@req_outstanding() then @hub.spin_down()
      if data.error
        @hub.fail()
        $('.searchdown-box').css('display','block')
        return $.Deferred().reject()
      else
        @hub.unfail()
        return data
    return xhr

  some_query: ->
    $('.page_some_query').show()
    $('.page_no_query').hide()

  no_query: ->
    $('.page_some_query').hide()
    $('.page_no_query').show()

# XXX compile
# XXX current search
# XXX species-independent indices
# XXX filterfocus to table

class Renderer
  constructor: (@hub,@source) ->

  page: (results) ->
    page = parseInt(@hub.page())
    if page < 1 or page > results.num_pages() then 1 else page

  render_stage: (more) ->
    $('.nav-heading').hide()
    main = $('#solr_content').empty()
    # Move from solr_content to table
    @state = new SearchTableState(@hub,$('#solr_content'),$.solr_config('static.ui.all_columns'))

    $(document).data('templates',@hub.templates())
    @table = new window.search_table(@hub.templates(),@state,{
      multisort: 0
      filter_col: 'q'
      chunk_size: 100
      style_col: 'result_style'
    })
    @render_style(main,@table)
    more()

  render_results: ->
    @state.update()
    $('.preview_holder').trigger('preview_close')
    @hub.request().render_table(@table,@state)
  
  get_all_data: (start,num) ->
    fixed_state = $.extend(true,{},@state)
    fixed_state.pagesize_override = 1000
    return @get_data(fixed_state)
  
  get_data: (state) ->
    state = @state unless state?
    update_seq = current_update_seq
    return dispatch_main_requests(@hub.request(),state,@table,update_seq).then ([req,res]) =>
      return res.then (docs) =>
        data = { rows: [], cols: state.columns() }
        for d in docs
          if d?
            data.rows = data.rows.concat(d)
        return data

  render_style: (root,table) ->
    clayout = @hub.layout()
    page = {
      layouts:
        entries: [
          { label: 'Standard', key: 'standard' }
          { label: 'Table',    key: 'table'    }
        ]
        title: 'Layout:'
        select: ((k) => $(document).trigger('ga',['SrchLayout','switch',k]) ; @hub.update_url { style: k })
      table:
        table_ready: (el,data) => @table.collect_view_model(el,data)
        state: @state
        download_curpage: (el,fn) =>
          @get_data().done((data) =>
            @table.transmit_data(el,fn,data)
          )
        download_all: (el,fn) =>
          @get_all_data().done((data) => @table.transmit_data(el,fn,data))
    }
    @hub.templates().generate 'page',page, (out) ->
      root.append(out)

    if page.layouts.set_fn? then page.layouts.set_fn(clayout)

class SearchTableState extends window.TableState
  constructor: (@hub,source,element,columns) ->
    super(source,element,columns)

  update: ->
    if @hub.sort()
      parts = @hub.sort().split('-',2)
      if parts[0] == 'asc' then dir = 1 else if parts[0] == 'desc' then dir = -1
      if dir then @order([{ column: parts[1], order: dir }])
    @page(@hub.page())
    @e().data('pagesize',@hub.per_page())
    @e().data('columns',@hub.columns())
    @e().trigger('fix_widths')

    filter = [{columns: ['q'], value: @hub.query()}]
    for k,v of @hub.current_facets()
      filter.push({columns: [k], value: v})
    @filter(filter)

  _is_default_cols: (columns) ->
    count = {}
    count[k] = 1 for k in $.solr_config('static.ui.columns')
    count[k]++ for k in columns
    for k,v of count
      if v != 2 then return false
    true

  _extract_filter: (col) ->
    for f in @filter()
      val = f.value for c in f.columns when c == col
    val

  set: ->
    state = {}
    if @order().length
      dir = (if @order()[0].order > 0 then 'asc' else 'desc')
      state.sort = dir+"-"+@order()[0].column
    state.page = @page()
    state.perpage = @pagesize()
    if state.perpage != @hub.per_page() # page size changed!
      state.page = 1
    columns = @columns()
    if @_is_default_cols(columns)
      state.columns = ''
    else
      state.columns = columns.join("*")
    state.q = @_extract_filter('q')
    @hub.update_url(state)

  q_query: () ->
    for fr in @filter()
      for c in fr.columns
        if c == 'q'
          return fr.value
    return ''

  q_facets: () ->
    facets = {}
    for fr in @filter()
      for c in fr.columns
        if c != 'q'
          facets[c] = fr.value
    return facets
# Go!

$ ->
  if code_select()
    window.hub = new Hub (hub) ->
      hub.service()
      $(window).on 'statechange', (e) ->
        hub.service()

# XXX move to utils

remote_log = (msg) ->
  $.post('/Ajax/report_error',{
    msg, type: 'remote log',
    support: JSON.stringify($.support)
  })

double_trap = 0
window.onerror = (msg,url,line) ->
  if double_trap then return
  double_trap = 1
  $.post('/Ajax/report_error',{
    msg, url, line, type: 'onerror catch'
    support: JSON.stringify($.support)
  })
  return false
