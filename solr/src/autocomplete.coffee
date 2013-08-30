#

$.fn.getCursorPosition = () ->
  input = @get(0)
  if not input then return # No (input) element found
  if input.selectionStart?
    # Standard-compliant browsers
    return input.selectionStart
  else if document.selection
    # IE
    input.focus();
    sel = document.selection.createRange()
    selLen = document.selection.createRange().text.length
    sel.moveStart('character', -input.value.length)
    return sel.text.length - selLen

class ACSensible # Move into util class to dedup this from Sensible
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

favs = undefined

sp_map = {}
sp_fav = []
sp_names = (name,callback) ->
  if sp_map[name]? then callback(sp_map[name],sp_fav) ; return
  ajax_json "/Multi/Ajax/species",{ name }, (data) ->
    if data.favs?
      sp_fav = data.favs
    if data.result?[0]
      sp_map[name] = data.result[0]
      callback(data.result[0],sp_fav)
    else
      callback(undefined,sp_fav)

favourite_species = (element,callback) ->
  skip = false
  if element?
    site = element.parents('form').find("input[name='site']")
    if site.length != 0 and site.val() != 'ensembl' and site.val() != 'ensembl_all'
      skip = true
  unless skip
    url_name = decodeURIComponent(window.location.pathname.split('/')[1])
    if (not url_name?) or url_name == 'Multi'
      url_name = ''
    sp_names url_name, (names,favs) ->
      if names?
        callback([names.common])
      else
        callback(s.common for s in favs)

# XXX to common
ajax_json = (url,data,success) ->
  $.ajax({
    url, data, traditional: true, success, dataType: 'json', cache: false,
  })

# XXX to config
_score = {}
score_of = (doc,favs) ->
  if _score[doc.uid] then return _score[doc.uid]
  sp = $.inArray(doc.species,favs)
  sp = ( if sp > -1 then favs.length-sp+1 else 0 )
  score  = 200 * sp
  score += 100 * $.inArray(doc.feature_type,direct_order)
  score += ( if doc.location?.indexOf('_') != -1 then 0 else 10 ) # XXX is_reference
  score += ( if doc.database_type == 'core' then 40 else 0 )
  _score[doc.uid] = score
  score

sort_docs = (url,docs,favs,callback) ->
  docs = ( d.doc for d in docs )
  docs.sort (a,b) -> score_of(b,favs) - score_of(a,favs)
  out = []
  for d in docs
    fmts = direct_format[d.feature_type]
    if not fmts? then fmts = direct_format['']
    entry = {}
    for key,str of fmts
      entry[key] = str.replace(/\{(.*?)\}/g,((m0,m1) -> d[m1] ? d.id ? 'unnamed'))
    # XXX pull server root from config
    entry.link = "/" + d.domain_url
    out.push(entry)
  callback(out)

ac_string_q = (url,q) ->
  data = {
    q, spellcheck: true
  }
  return ajax_json(url,data)

ac_string_a = (input,output) ->
  docs = input.result?.spellcheck?.suggestions[1]?.suggestion
  unless docs? then return
  while docs.length
    q = docs.shift()
    output.push {
      left: "Search for '#{q}'"
      link: "/Multi/Search/Results?q="+q
      text: q
    }

# Last are first
direct_order = ['Phenotype','Gene']

direct_format =
  Phenotype:
    left: "{name}"
    right: '{species} Phenotype #{id}'
  Gene:
    left: "{name}"
    right: "<i>{species}</i> Gene {id}"
  '':
    left: "{name}"
    right: "{id} {feature_type}"

direct_searches = [
  {
    ft: ['Phenotype']
    fields: ['name*','description*']
  },{
    ft: ['Gene']
    fields: ['name*']
  },{
    ft: ['Sequence']
    fields: ['id']
    minlen: 6
  },{
    fields: ['id']
    minlen: 6
  }
]

jump_searches = [
  {
    fields: ['id']
    minlen: 3
  },{
    ft: ['Gene','Sequence']
    fields: ['name']
  }
]

boost = (i,n) -> if n>1 then Math.pow(10,(2*(n-i-1))/(n-1)) else 1

ac_name_q = (config,url,query,favs) ->
  fav = "( "+("species:\"#{s}\"" for s in favs).join(" OR ")+" )"
  # XXX configurable AC feature types
  q = []
  for s in config
    if s.minlen? and query.length < s.minlen
      continue
    if s.ft?
      ft_part = ( "feature_type:"+t for t in s.ft ).join(' OR ')
    q_parts = []
    for f in s.fields
      wild = false
      f = f.replace(/\*$/,(() -> wild = true ; ''))
      fk = ( if f == '' then '' else f+':' )
      q_parts.push(fk+query)
      if wild
        q_parts.push(fk+query+'*')
    q_part = q_parts.join(' OR ')
    if q_parts.length > 1 then q_part = "( "+q_part+" )"
    if s.ft?
      q.push("( ( #{ft_part} ) AND #{q_part} )")
    else
      q.push(q_part)
  # Add fav-sp to q as well as fq so that we can boost to get spp in
  # right order
  favqs = []
  for s,i in favs
    favqs.push("species:\""+s+"\"^"+boost(i,favs.length))
  q = "( "+q.join(' OR ')+" ) AND ( "+favqs.join(" OR ")+" )" 
  data = { q, fq: fav }
  return ajax_json(url,data)

ac_name_a = (input,output) ->
  docs = input.result?.response?.docs
  unless docs? then return
  for d in docs
    output.push({ doc: d })

# XXX not really ac functionality, but methods are here: refactor
jump_to = (q) ->
  url = $('#se_q').parents("form").attr('action')
  url = url.split('/')[1]
  if url == 'common' then url = 'Multi'
  url = "/#{url}/Ajax/search"
  favourite_species undefined,(favs) ->
    $.when(ac_name_q(jump_searches,url,q,favs)).done( (id_d) ->
      direct = []
      ac_name_a(id_d,direct)
      if direct.length != 0
        window.location.href = '/'+direct[0].doc.domain_url
    )

sensible = new ACSensible 500,1000, (data) ->
  url = $('#se_q').parents("form").attr('action')
  url = url.split('/')[1]
  if url == 'common' then url = 'Multi'
  url = "/#{url}/Ajax/search"
  q = data.q
  favourite_species data.element, (favs) ->
    $.when(ac_string_q(url,q),
            ac_name_q(direct_searches,url,q,favs))
      .done((string_d,id_d) ->
        searches = []
        direct = []
        out = []
        ac_string_a(string_d[0],searches)
        ac_name_a(id_d[0],direct)
        sort_docs(url,direct,favs, (sorted) ->
          direct = sorted
          s.type = 'search' for s in searches
          d.type = 'direct' for d in direct
          out = searches.concat(direct)
          data.response(out)))

internal_site = (el) ->
  site = el.parents('form').find("input[name='site']").val()
  if site
    return (site == 'ensembl' or site == 'ensembl_all')
  else
    return true

sections = [
  { type: 'search', label: '' }
  { type: 'direct',   label: 'Direct Links' }
]

$.widget('custom.searchac',$.ui.autocomplete,{
  _create: () ->
    $b = $('body')
    if $b.hasClass('ie67') or $b.hasClass('ie8') or 
        $b.hasClass('ie9') or $b.hasClass('ie10')
      # XXX probably possible to get working in ie10
      @element.clone().addClass('solr_ghost').css('display','none')
        .insertAfter(@element)
      $.ui.autocomplete.prototype._create.call(@)
      return
    tr_gif = "url(data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==)"
    eh = @element.height()
    ew = @element.width()
    box = $('<div></div>')
      .css({ position: 'relative', display: 'inline-block', 'vertical-align': 'bottom' })
      .width(ew).height(eh)
    for d in ['left','right','top','bottom']
      for p in ['margin','padding']
        box.css("#{p}-#{d}",@element.css("#{p}-#{d}"))
      for t in ['style','color','width']
        box.css("border-#{d}-#{t}",@element.css("border-#{d}-#{t}"))

    for p in ['background-color']
      box.css(p,@element.css(p))

    box.insertAfter(@element)
    @element.css('background-image',tr_gif).css('padding',0).css('margin',0).appendTo(box).css('border','none').css('outline','none').css('background-color','transparent')
    @element.css({ 'z-index': 2, position: 'absolute' })
    pos = @element.position()
    ghost = @element.clone()
      .css({ 'left': pos.left+"px", 'top': pos.top+"px" })
      .css({ position: 'absolute', 'z-index': 1 })
      .css({ background: 'none' }).val('')
      .addClass('solr_ghost').attr('placeholder','').attr('id','')
      .insertBefore(@element).attr('name','')
    $.ui.autocomplete.prototype._create.call(@)
    oldval = @element.val()
    @element.on 'change keypress paste focus textInput input', (e) =>
      val = @element.val()
      if val != oldval
        if ghost.val().substring(0,val.length) != val
          ghost.val('')
        oldval = val
    @element.on 'keydown', (e) =>
      if e.keyCode == 39 # right arrow
        val = @element.val()
        gval = ghost.val()
        if gval and gval.substring(0,val.length) == val and
            @element.getCursorPosition() == val.length
          @element.val(gval)

  _renderMenu: (ul,items) ->
    for s in sections
      rows = ( i for i in items when i.type == s.type )
      if s.label and rows.length
        ul.append("<li class='search-ac-cat'>#{s.label}</li>")
      $.each(rows,((i,item) => @_renderItemData(ul,item)))

  _renderItem: (ul,item) ->
    $a = $("<a class=\"search-ac\"></a>").html(item.left)
    if item.right then $a.append($('<em></em>').append(item.right))
    $("<li>").append($a).appendTo(ul)

  options:
    source: (request,response) ->
      if internal_site(@element)
        sensible.submit({ q: request.term, response, @element })
      else
        response([])
    select: (e,ui) ->
      if window.hub and window.hub.code_select
        if ui.item.text
          $(e.target).val(ui.item.text)
          window.hub.update_url({q: ui.item.text })
          return false
        else if ui.item.link
          window.hub.spin_up()
      if ui.item.link
        window.location.href = ui.item.link
    focus: (e,ui) ->
      ghost = $(e.target).parent().find('input.solr_ghost')
      val = $(e.target).val()
      if (ui.item.text ? '').substring(0,val.length) == val
        ghost.val(ui.item.text)
        ghost.css('font-style',$(e.target).css('font-style'))
      else
        ghost.val('')
      return false
    close: (e,ui) ->
      ghost = $(e.target).parent().find('input.solr_ghost')
      ghost.val('')
})

$ ->
  form = $('#SpeciesSearch .search-form')
  if not form.hasClass('homepage-search-form')
    url = $('#q',form).parents("form").attr('action')
    if url
      url = url.split('/')[1]
      $.solr_config({ url: "/#{url}/Ajax/config"}).done () ->
          selbox = $('#q',form).parent()
          ids = []
          text= []
          for m in $.solr_config('static.ui.facets.key=.members','feature_type')
            text.push (m.text?.plural ? m.key)
            ids.push m.key
          ids.unshift ""
          text.unshift "Search all categories"
          selbox.selbox({
            action: (id,text) ->
              selbox.selbox("maintext",text)
            selchange: () ->
              @centered({ max: 14, inc: 1 })
            field: "facet_feature_type"
          }).selbox("activate","",text,ids).selbox("select","")

window.sp_names = sp_names
window.solr_jump_to = jump_to # XXX hack. Should be moved into panel
