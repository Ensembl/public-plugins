#
code_select = -> $('#solr_config').length > 0

_kv_copy = (old) -> out = {}; out[k] = v for k,v of old; out

_clone_array = (a) -> $.extend(true,[],a)
_clone_object = (a) -> $.extend(true,{},a)

obj_to_str = (y,sort) ->
  if typeof y == 'string' or typeof y == 'number'
    (y.length + "-" + y)
  else if y instanceof Array
    if sort
      y = _clone_array(y)
      y.sort()
    "["+y.length+"-"+(obj_to_str(x) for x in y).join("")
  else if typeof y == 'object'
    keys = (k for k,v of y)
    keys.sort()
    "{"+obj_to_str([k,y[k]] for k in keys)
  else if y
    "+"
  else
    "-"

_is_prefix_of = (small,big) ->
  big.substr(0,small.length) == small

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
    $.when(
      $.solr_config({ url: config_url })
      $.getScript('/pure/pure.js')
    ).done () =>
      @params = {}
      @sections = {}
      @interest = {}
      @first_service = 1
      @source = new Source(@)
      @renderer = new Renderer(@,@source)
      @request_ = @source.make_request(@renderer)
      $(window).bind('popstate',((e) => @service()))
      $(document).ajaxError => @fail()
      @spin = 0
      @leaving = 0
      $(window).unload(() -> @leaving = 1)
      $(document).on 'force_state_change', () =>
        $(document).trigger('state_change',[@params])
      more(@)

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
    url = @fix_species_url(url,{0: qps['facet_species'] ? 'Multi' })
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

  ajax_url: -> "#{ $('#species_path').val() }/Ajax/search"
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

  all_facets: -> k.key for k in $.solr_config('static.ui.facets')

  request: -> @request_

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
    rigid = []
    favs = $.solr_config('user.favs.species')
    if favs.length
      rigid.push ['species',[favs],100]
    request.set_rigid_order(rigid)
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
        $img = $('img',$spec).attr("src","/i/species/16/#{names.url}.png")
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
class Source extends window.TableSource
  constructor: (@hub) ->
    @init($.solr_config('static.ui.all_columns'))
    @docsizes = {}

  make_request: (renderer) ->
    @req = new Request(@hub,@,renderer)

  chunk_size: -> 100 # XXX

  request: -> @req

  get: (filter,cols,order,start,rows,result,force) ->
    @req.get(filter,cols,order,start,rows,result,force)

  docsize: (params,extra,num) ->
    p = _clone_object(params)
    delete p.rows
    delete p.start
    str = obj_to_str([p,extra])
    if num? then @docsizes[str] = num
    @docsizes[str]

# XXX when failure
each_block = (num,fn) ->
  requests = []
  for i in [0...num]
    requests.push(fn(i))
  return $.when.apply($,requests).then (args...) ->
    Array.prototype.slice.call(args)

# XXX low-level cache

dispatch_main_requests = (request,cols,extras,query,start,rows) ->
  # Calculate block sizes
  ret = each_block extras.length,(i) =>
    return request.request_results(query,cols,extras[i], 0, 10)
      .then (data) ->
        return data.num

  return ret.then (sizes) =>
    # ... calculate the requests we will make
    requests = []
    offset = 0
    rows_left = rows
    for i in [0...extras.length]
      if start < offset+sizes[i] and start+rows > offset
        local_offset = start - offset
        if local_offset < 0 then local_offset = 0
        requests.push [local_offset,offset,rows_left]
        rows_left -= sizes[i] - local_offset
      else
        requests.push [-1,-1,-1]
      offset += sizes[i]
    # ... make the requests
    results = each_block extras.length, (i) =>
      if requests[i][0] != -1
        request.request_results(query,cols,extras[i],requests[i][0],requests[i][2])
    # ... weld together
    return results.then (docs_frags) =>
      docs = []
      for i in [0...docs_frags.length]
        if requests[i][0] != -1
          docs[requests[i][1]..requests[i][1]+docs_frags[i].num] =
            docs_frags[i].rows
      return docs

dispatch_facet_request = (hub,request,query) ->
  fq = query.fq.join(' AND ')
  params = {
    q: query.q
    fq
    rows: 1
    'facet.field': hub.all_facets()
    'facet.mincount': 1
    facet: true
  }
  return request.raw_ajax(params).then (data) =>
    return data.result?.facet_counts?.facet_fields

class RequestDispatch
  constructor: (@request,@hub,@source,@start,@rows,@renderer,@cols,@next) ->

  get: (rigid,filter,order) -> # XXX
    @request.abort_ajax()
    # Extract filter (from pseudo-column "q") and facets
    all_facets = @hub.all_facets()
    facets = {}
    for fr in filter
      for c in fr.columns
        if c == 'q'
          q = fr.value
        for fc in all_facets
          if fc == c
            facets[c] = fr.value
    if q?
      @request.some_query()
    else
      @request.no_query()
      return []
    if order.length
      sort = order[0].column+" "+(if order[0].order>0 then 'asc' else 'desc')
    #
    @input = {
      q, @rows, @start, sort
      fq: ("#{k}:\"#{v}\"" for k,v of facets)
      hl: 'true'
      'hl.fl': $.solr_config('static.ui.highlights').join(' ')
      'hl.fragsize': 500
    }
    @extra = @expand_criteria(rigid,@remainder_criteria(rigid))
    
    $.when(dispatch_main_requests(@request,@cols,@extra,@input,@start,@rows),
           dispatch_facet_request(@hub,@request,@input))
      .done (main,facet) =>
        @next.call(@,{ num: @rows, faceter: facet, rows: main, @cols })

  expand_criteria: (criteria,remainder) ->
    if criteria.length == 0 then return [[]]
    [ type,sets,boost ] = criteria[0]
    head = ( [type,false,s,boost] for s in sets )
    head.push([type,true,remainder[type]])
    rec = @expand_criteria(criteria.slice(1),remainder)
    all = []
    for r in rec
      for h in head
        out = _clone_array(r)
        out.push(h)
        all.push(out)
    all

  remainder_criteria: (criteria) ->
    out = {}
    for [type,sets] in criteria
      out[type] = []
      out[type] = out[type].concat(s) for s in sets
    out

# XXX Faceter orders
# XXX out of date responses / abort
xhr_idx = 1
class Request
  constructor: (@hub,@source,@renderer) ->
    @rate_limiter = new window.EphemoralRequestRateLimiter(1000,2000,
      ((v) =>
        {filter,cols,order,start,rows,next} = v
        @real_get(filter,cols,order,start,rows, (data) =>
          if @relevant_data(filter,cols,order,start,rows) then next(data)
        )),
      (a,b) =>
        a_s = obj_to_str(a,true)
        b_s = obj_to_str(b,true)
        a_s == b_s
    )
    @xhrs = {}

    @fc = @fc_key = undefined
    @current_q = undefined

  req_outstanding: -> (k for k,v of @xhrs).length

  cached_facet: (key,data) ->
    if data?
      @fc = data
      @fc_key = key
    if key == @fc_key then @fc else undefined

  _remove_q: (filter) ->
    out = []
    for f in filter
      q = undefined
      qout = f.value for c in f.columns when c == 'q'
      if not q? then out.push(f)
    [out,qout]

  relevant_data: (filter,cols,order,start,rows) ->
    a = {filter,cols,order,start,rows,next: true}
    b = _clone_object(@rate_limiter.get())
    [a.filter,aq] = @_remove_q(a.filter)
    [b.filter,bq] = @_remove_q(b.filter)
    # if any of the metadata is different it's not relevant
    if obj_to_str(a,true) != obj_to_str(b,true) then return false
    # if a isn't a prefix of b it's not relevant
    if not _is_prefix_of(aq,bq) then return false
    # if what's already there is a longer prefix, then it's irrelevant
    if @current_q? and @current_q.length > aq.length and _is_prefix_of(@current_q,bq)
      return false
    @current_q = aq
    true

  set_rigid_order: (@rigid) ->

  # XXX get rid of force by pushing rate limiter elsewhere in stack
  get: (filter,cols,order,start,rows,next,force) -> # XXX
    if force
      @real_get(filter,cols,order,start,rows,next)
    else
      @rate_limiter.set({filter,cols,order,start,rows,next})

  real_get: (filter,cols,order,start,rows,next) -> # XXX
    disp = new RequestDispatch(@,@hub,@source,start,rows,@renderer,cols,next)
    disp.get(@rigid,filter,order)

# XXX shortcircuit get on satisfied
# XXX first page optimise
# XXX table-based compisite renderers

  abort_ajax: ->
    x.abort() for k,x of @xhrs
    if @req_outstanding() then @hub.spin_down()
    @xhrs = {}

  raw_ajax: (params) ->
    idx = (xhr_idx += 1)
    xhr = $.ajax({
      url: @hub.ajax_url(), data: params,
      traditional: true, dataType: 'json'
    })
    @xhrs[idx] = xhr
    if !@req_outstanding() then @hub.spin_up()
    xhr.then (data) =>
      delete @xhrs[idx]
      if !@req_outstanding() then @hub.spin_down()
      if data.error
        @hub.fail()
        $('.searchdown-box').css('display','block')
        return $.Deferred().reject().promise()
      else
        @hub.unfail()
        return data
    return xhr

  substitute_highlighted: (input,output) ->
    for doc in output.rows
      snippet = input.result?.highlighting?[doc.uid]
      if snippet?
        for h in $.solr_config('static.ui.highlights')
          if doc[h] and snippet[h]
            doc[h] = snippet[h].join(' ... ')
  
  request_results: (params,cols,extra,start,rows) ->
    input = _clone_object(params)
    input.start = start
    input.rows = rows
    q = [input.q]
    for [field,invert,values,boost] in extra
      str = (field+':"'+s+'"' for s in values).join(" OR ")
      str = (if invert then "(NOT ( #{str} ))" else "( #{str} )")
      input.fq.push(str)
      bq = []
      if boost?
        for s,i in values
          v = Math.floor(boost*(values.length-i-1)/(values.length-1))
          bq.push(field+':"'+s+'"'+(if v then "^"+v else ""))
        q.push("( "+bq.join(" OR ")+" )")
    if q.length > 1
      input.q = ( "( "+x+" )" for x in q).join(" AND ")
    return @raw_ajax(input).then (data) =>
      num = data.result?.response?.numFound
      docs = data.result?.response?.docs
      table = { rows: docs, hub: @hub }
      @substitute_highlighted(data,table)
      out = []
      for d in table.rows
        obj = []
        obj.push(d[c]) for c in cols
        out.push(obj)
      return { docs: out, num, rows: table.rows, cols }

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
    @state = new SearchTableState(@hub,@source,$('#solr_content'))

    $(document).data('templates',@hub.templates())
    @table = new window.search_table(@hub.templates(),@source,@state,{
      multisort: 0
      filter_col: 'q'
      update : (data) =>
        facets = {} 
        for fr in @state.filter()
          for c in fr.columns
            if c == 'q'
              q = fr.value
            for fc in @hub.all_facets()
              if fc == c
                facets[c] = fr.value
        query = { q, facets }
        $(document).trigger('first_result',[query,data,@state])
        $(document).on 'update_state', (e,qps) =>
          @hub.update_url(qps)
    })
    @render_style(main,@table)
    more()

  render_results: ->
    @state.update()
    $('.preview_holder').trigger('preview_close')
    @table.draw_table()

  render_style: (root,table) ->
    clayout = @hub.layout()
    page = {
      layouts:
        entries: [
          { label: 'Standard', key: 'standard' }
          { label: 'Table',    key: 'table'    }
        ]
        title: 'Layout:'
        select: ((k) => @hub.update_url { style: k })
      table:
        table.generate_model()
    }
    @hub.templates().generate 'page',page, (out) ->
      root.append(out)

    if page.layouts.set_fn? then page.layouts.set_fn(clayout)

class SearchTableState extends window.TableState
  constructor: (@hub,source,element) ->
    super(source,element)

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
