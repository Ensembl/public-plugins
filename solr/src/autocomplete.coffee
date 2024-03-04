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

gi_direct = ->
  if Ensembl.GA
    return new Ensembl.GA.EventConfig({
      category: (-> if this.ui.item.link.substr(0,13) == '/Multi/Search' then 'SrchAuto' else 'SrchDirect' ),
      action: (-> if $(this.target).parents('#masthead').length then 'masthead' else 'results' ),
      label: (-> this.ui.item.link ),
      nonInteraction: false
    })

$.fn.getCursorPosition = () ->
  input = @get(0)
  if not input then return # No (input) element found
  if input.selectionStart?
    # Standard-compliant browsers
    return input.selectionStart
  else if document.selection
    # IE
    input.focus()
    sel = document.selection.createRange()
    selLen = document.selection.createRange().text.length
    sel.moveStart('character', -input.value.length)
    return sel.text.length - selLen

load_config = () ->
  config_url = "#{ $('#species_path').val() }/Ajax/config"
  return $.solr_config({ url: config_url })

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
    if site.length != 0 and site.val() != 'ensembl' and site.val() != 'ensembl_all' and site.val() != 'vega'
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
  docs.sort (a,b) -> score_of(b,favs) - score_of(a,favs)
  out = []
  for d in docs
    fmts = direct_format[d.feature_type]
    if not fmts? then fmts = direct_format['']
    entry = {}
    for key,str of fmts
      entry[key] = str.replace(/\{(.*?)\}/g,((m0,m1) -> d[m1] ? d.id ? 'unnamed'))
    # XXX pull server root from config
    entry.link = "/" + d.url
    out.push(entry)
  callback(out)

ac_string_q = (url,q) ->
  q = q.toLowerCase()
  species = window.solr_current_species()
  if !species then species = 'all'
  q = species+'__'+q
  data = {
    q, spellcheck: true
  }
  return ajax_json(url,data)

ac_string_a = (input,output) ->
  docs = input.result?.spellcheck?.suggestions[1]?.suggestion
  unless docs? then return
  while docs.length
    q = docs.shift()
    q = q.replace(/^.*?__/,'')
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
    right: '{species} Phenotype'
  Gene:
    left: "{name}"
    right: "<i>{species}</i> Gene {id}"
  '':
    left: "{name}"
    right: "{id} {feature_type}"

direct_link =
  Phenotype: "{ucspecies}/Phenotype/Locations?ph={id}"
  Gene: "{ucspecies}/Gene/Summary?g={id};{rest}"

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

# exponentially-scaled numbers between 1 and 100, of various lengths 
boost = (i,n) -> if n>1 then Math.pow(10,(2*(n-i-1))/(n-1)) else 1

ac_name_q = (config,url,query,favs) ->
  return load_config().then (x) =>
    if not $.solr_config('static.ui.enable_direct')
      return new $.Deferred().resolve()
    spp = []
    spp_h = {}
    for s in favs
      s = $.solr_config('spnames.%',s.toLowerCase())
      spp.push(s.toLowerCase())
      spp_h[s.toLowerCase()] = 1
    cursp = window.solr_current_species()
    if cursp and (not spp_h[cursp.toLowerCase()]?)
      spp.push(cursp.toLowerCase())
    qs = []
    for sp in spp
      sp = sp.replace(/_/g,'_-').replace(/\s+/g,'_+')
      q = query.toLowerCase().replace(/_/g,'_-').replace(/\s+/g,'_+')
      qs.push(sp+"__"+q)
    q = qs.join(' ')
    data = {
      q, directlink: true, spellcheck: true
    }
    return ajax_json(url,data)

direct_limit = 6
ac_name_a = (input,output) ->
  j = 0
  for s,i in input.result?.spellcheck?.suggestions
    if not i%2 then continue
    if j >= direct_limit then break
    docs = s.suggestion
    unless docs? then continue
    for d in docs
      parts = []
      for p in d.split('__')
        parts.push(p.replace(/_\+/g,' ').replace(/_\-?/g,'_'))
      species = $.solr_config('revspnames.%',parts[0].toLowerCase())
      ucspecies = parts[0].charAt(0).toUpperCase() + parts[0].slice(1)
      doc = {
        name: parts[4], id: parts[3], species, ucspecies, rest: parts[5],
        feature_type: parts[2]
      }
      doc.url = direct_link[parts[2]]
      doc.url = doc.url.replace(/\{(.*?)\}/g,((m0,m1) -> doc[m1] ? ''))
      output.push(doc)
      j += 1
      if j >= direct_limit then break

# XXX not really ac functionality, but methods are here: refactor
jump_to = (q) ->
  url = $('#se_q').parents("form").attr('action')
  if url
    url = url.split('/')[1]
    if url == 'common' then url = 'Multi'
    url = "/#{url}/Ajax/search"
    favourite_species undefined,(favs) ->
      $.when(ac_name_q(jump_searches,url,q,favs)).done( (id_d) ->
        direct = []
        ac_name_a(id_d,direct)
        if direct.length != 0
          window.location.href = '/'+direct[0].url
      )

rate_limit = null

make_rate_limiter = (params) ->
  if rate_limit then return rate_limit(params)
  return load_config().then (x) =>
    limits = $.solr_config('static.ui.direct_pause')
    rate_limit = window.rate_limiter(limits[0],limits[1])
    return rate_limit(params)

internal_site = (el) ->
  site = el.parents('form').find("input[name='site']").val()
  if site
    return (site == 'ensembl' or site == 'ensembl_all' or site == 'vega')
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
      .attr('tabindex','5000')
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
        make_rate_limiter({q: request.term, response, @element }).done (data) =>
          url = $('#se_q').parents("form").attr('action')
          if url
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
                  if id_d?[0] then ac_name_a(id_d[0],direct)
                  sort_docs(url,direct,favs, (sorted) ->
                    direct = sorted
                    s.type = 'search' for s in searches
                    d.type = 'direct' for d in direct
                    out = searches.concat(direct)
                    data.response(out)))
      else
        response([])
    select: (e,ui) ->
      if window.hub and window.hub.code_select
        if ui.item.text
          $(e.target).val(ui.item.text)
          ga_direct = gi_direct()
          if Ensembl.GA and ga_direct
            Ensembl.GA.sendEvent(ga_direct,{ target: e.target, ui: ui })
          window.hub.update_url({q: ui.item.text })
          return false
        else if ui.item.link
          window.hub.spin_up()
      if ui.item.link
        ga_direct = gi_direct()
        if Ensembl.GA and ga_direct
          Ensembl.GA.sendEvent(ga_direct,{ target: e.target, ui: ui })
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
  if not form.hasClass('no-sel')
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
