#
code_select = -> $('#solr_config').length > 0

_div = (klass) -> $("<div class='#{klass}'></div>")
_span = (klass) -> $("<span class='#{klass}'></span>")
_a = (url) -> a = $("<a href='#{url}'></a>")

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

ucfirst = (str) ->
  str.charAt(0).toUpperCase() + str.substring(1)

_is_prefix_of = (small,big) ->
  big.substr(0,small.length) == small

class Sensible
  constructor: (@nochange_ms,@lastreq_ms,@operation) ->
    @timeout = undefined
    @last_request = undefined
    @last_data = undefined
    @equal = (a,b) -> a == b
    @trigger()

  set_equal_fn: (@equal) ->

  submit: (@data) ->
    if @timeout then clearTimeout(@timeout)
    @timeout = setTimeout(((v) => @trigger(v)),@nochange_ms)
    now = new Date().getTime()
    if (not @last_request?) or now - @last_request > @lastreq_ms
      @trigger()
    
  trigger: ->
    if not @equal(@last_data,@data)
      @last_data = @data
      @last_request = new Date().getTime()
      @operation(@data)

  current: -> @data

class AllDone
  constructor: (@that,@complete) ->
    @data = {}
    @outstanding = {}
    @num = 0
    @_go = 0

  add_task: (key) ->
    @outstanding[key] = 1
    @num++

  done: (key,data) ->
    @data[key] = data
    delete @outstanding[key]
    @num--
    if @num == 0 and @_go
      @complete.call(@that,@data)

  go: ->
    @_go = 1
    if @num == 0
      @complete.call(@that,@data)

# XXX to perl
ddg_codes = {
  facet_feature_type:
    g: 'Gene'
    t: 'Transcript'
    rf: 'RegulatoryFeature'
    doc: 'Documentation'
    ph: 'Phenotype'
    sm: 'SomaticMutation'
    sv: 'StructuralVariation'
    v: 'Variation'
    dom: 'Domain'
    fam: 'Family'
    pf: 'ProteinFamily'
    m: 'Marker'
    s: 'Sequence'
    ga: 'GenomicAlignment'
    pf: 'ProbeFeature'
  facet_species:
    hs: 'Human'
    mm: 'Mouse'
    dr: 'Zebrafish'
    rn: 'Rat'
}

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

  _upgrade_first_used = {}

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
      for key,map of ddg_codes
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
    request.set_rigid_order [
      ['species',[$.solr_config('user.favs.species')],100]
# re-enable if genes should always be top
#      ['feature_type',[['Gene']],10]
    ]
    if @first_service
      for k of changed
        changed[x] = 1 for x in (_upgrade_first_used[k] ? [])       
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

# We need traditional to be true to send multiple params so can't use $.getJSON
_ajax_json = (url,data,success) ->
  $.ajax({
    url, data, traditional: true, success, dataType: 'json',
  })

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

class RequestDispatch
  constructor: (@request,@hub,@source,@start,@rows,@renderer,@cols,@next) ->

  completion_fn: (values) ->
    if values.facet?
      if values.facet.result? # real response
        @fdata = values.facet.result?.facet_counts?.facet_fields
        params = values.facet.result?.responseHeader?.params
        fkey = { q: params.q, fq: params.fq }
        @request.cached_facet(obj_to_str(fkey),@fdata)
      else # cached response
        @fdata = values.facet
    more = false
    offset = @start
    num = @rows
    @completion = new AllDone(@,@completion_fn)
    for i in [0..@lens.length-1]
      if offset < @lens[i] and num > 0
        numhere = Math.min(@lens[i] - offset,num)
        extract = @extract_results(@results[i],offset,numhere)
        if extract?
          @docs = @docs.concat(extract)
        else
          more = true
          @dispatch_request(i,offset,numhere)
        num -= numhere
        offset = 0       
      else
        offset -= @lens[i]
    if more
      @completion.go()
    else
      num = 0
      num += x for x in @lens
      @next.call(@,{ num, faceter: @fdata, rows: @docs, @cols })

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
    @docs = []
    @results = []
    @lens = []
    @completion = new AllDone(@,@completion_fn)
    @dispatch_facet_request()
    # Need to know the number of results in each category
    # If we don't, fire off requests starting at zero
    # When that's done completion_fn will do the requests proper.
    for x in [0..@extra.length-1]
      num = @source.docsize(@input,@extra[x])
      if not num?
        @dispatch_request(x,0,@input.rows)
      else
        @lens[x] = num
    @completion.go()

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

  extract_results: (results,ex_start,ex_rows) ->
    if results?
      [got_start,got_rows,got_docs,got_rdocs] = results
      delta = ex_start - got_start
      if delta < 0 then return undefined
      docs = got_rdocs.slice(delta,delta+ex_rows)
      if docs.length < ex_rows then return undefined      
      docs

  dispatch_request: (idx,start,rows) ->
    params = _clone_object(@input)
    params.start = start
    params.rows = rows
    @completion.add_task(idx)
    c = @completion
    @request.do_ajax(params,@cols,( (data) =>
      @lens[idx] = data.num
      @results[idx] = [start,rows,data.docs,data.rows]
      @source.docsize(@input,@extra[idx],data.num)
      c.done(idx,data)
    ),@extra[idx])

  dispatch_facet_request: ->
    fq = @input.fq.join(' AND ')
    @completion.add_task('facet')
    cached = @request.cached_facet(obj_to_str({ q: @input.q, fq }))
    if cached?
      @completion.done('facet',cached)
    else
      params = {
        q: @input.q
        fq
        rows: 1
        'facet.field': @hub.all_facets()
        'facet.mincount': 1
        facet: true
      }
      @request.raw_ajax params, (data) =>
        @completion.done('facet',data)  

# XXX Faceter orders
# XXX out of date responses / abort
xhr_idx = 1
class Request
  constructor: (@hub,@source,@renderer) ->
    @sensible = new Sensible(1000,2000, (v) =>
      {filter,cols,order,start,rows,next} = v
      @real_get(filter,cols,order,start,rows, (data) =>
        if @relevant_data(filter,cols,order,start,rows) then next(data)
      )
    )
    @sensible.set_equal_fn (a,b) =>
      a_s = obj_to_str(a,true)
      b_s = obj_to_str(b,true)
      a_s == b_s

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
    b = _clone_object(@sensible.current())
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

  # XXX get rid of force by pushing sensible elsewhere in stack
  get: (filter,cols,order,start,rows,next,force) -> # XXX
    if force
      @real_get(filter,cols,order,start,rows,next)
    else
      @sensible.submit({filter,cols,order,start,rows,next})

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

  # XXX AJAX to plugin
  raw_ajax: (params,more) ->
    idx = (xhr_idx += 1)
    xhr = _ajax_json @hub.ajax_url(), params, (data) =>
      delete @xhrs[idx]
      if !@req_outstanding() then @hub.spin_down()
      if data.error
        @hub.fail()
      else
        @hub.unfail()
        more.call(@,data) 
    if !@req_outstanding() then @hub.spin_up()
    @xhrs[idx] = xhr

  substitute_highlighted: (input,output) ->
    for doc in output.rows
      snippet = input.result?.highlighting?[doc.uid]
      if snippet?
        for h in $.solr_config('static.ui.highlights')
          if doc[h] and snippet[h]
            doc[h] = snippet[h].join(' ... ')

  do_ajax: (input,cols,result,extra) ->
    input = _clone_object(input)
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
    @raw_ajax input, (data) =>
      num = data.result?.response?.numFound
      docs = data.result?.response?.docs
      table = { rows: docs, hub: @hub }
      @substitute_highlighted(data,table)
      out = []
      for d in table.rows
        obj = []
        obj.push(d[c]) for c in cols
        out.push(obj)
      result.call(@,{ docs: out, num, rows: table.rows, cols })

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

  render_doc: (results,doc) ->
    html = _div('solr_result')
    html.append(_a(results.url(doc)).text(results.id(doc)))
    html.append(" #{ results.name(doc) } #{ results.type(doc) } #{ results.species(doc) } #{ results.description(doc) }")
    html

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
