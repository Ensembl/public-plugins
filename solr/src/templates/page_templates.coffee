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

# table_extras can be filled by subtemplates if they wish
window.page_templates =
  page:
    template: """
      <div>
        <div class='solr_page_p_side'>
          <div class='solr_sidebar  ui-panel ui-panel-position-left ui-panel-display-reveal ui-body-c ui-panel-animate ui-panel-closed' data-role='panel'  id='search_nav'>
            <div class='new_current_faceter'></div>
            <div class='faceters'></div>
            <div class='table_extras'></div>
            <div class='sizer'></div>
            <div class='layout_select'></div>
            <div class='leftcars'><div class='sidecars'></div></div>
            <div class='tips'></div>
          </div>
        </div>
        <div class='solr_page_p_main'>
          <div class='table'>
          </div>
        </div>
      </div>
    """
    sockets:
      '.table_extras': 'sidebar_table_extra'
    decorate:
      '.hub_spinner': (el,data) -> el.hide()
      '.hub_fail': (el,data) ->
        # Force preload before hiding
        m = /url\("?(.*?)"?\)/.exec(el.css('background-image'))
        if m?
          $('<img/>').attr('src',m[1]).appendTo($('<body></body>')).css('display','none')
      '.new_current_faceter': (el,data) ->
        $(document).on 'faceting_known', (e,faceting,values,num,state,update_seq) ->
          if $(document).data('update_seq') != update_seq then return
          templates = $(document).data('templates')
          el.empty()
          el.append(templates.generate('current_facets_sidebar',{values}))
    subtemplates:
      '.faceters': { template: 'faceter', data: '' }
      '.sizer': { template: 'sidesizer', data: '' }
      '.layout_select': { template: 'feet', data: 'layouts' }
      '.table': { template: 'outer', data: 'table' }
      '.tips': { template: 'tips', data: '' }
    postproc: (el,data) =>
      $('#ensembl-webpage').addClass('solr_page_p_page')
    fixes:
      global: [
        (data) ->
          data.tp2_row.register 50, () ->
            url = data.tp2_row.best('domain_url')
            if url
              if not url?.match(/^\//) and not url?.match(/^https?\:/)
                url = "/" + url
              data.tp2_row.candidate('url',url,50)

          data.tp2_row.register 100, () ->
            # setup title 
            if data.tp2_row.best('name') then data.tp2_row.candidate('main-title',data.tp2_row.best('name'),200) # XXX make ideomatic
            if data.tp2_row.best('id') then data.tp2_row.candidate('main-title',data.tp2_row.best('id'),100) # XXX make ideomatic
            if data.tp2_row.best('description') then data.tp2_row.candidate('main-title',data.tp2_row.best('description'),10) # XXX make ideomatic
            
            # Remove source/type etc
            desc = data.tp2_row.best('description')
            if desc?
              desc = desc.replace /\[(.*?)\:(.*?)\]/g, (g0,g1,g2) ->
                data.tp2_row.candidate($.trim(g1).toLowerCase(),$.trim(g2),50)
                ''
              data.tp2_row.candidate('description',desc)

          data.tp2_row.register 300, () ->
            id = data.tp2_row.best('id')
            if id?
              if id.match(new RegExp("^OTT"))
                data.tp2_row.add_value('new-contents','<i>Havana annotation</i>',150)
          true

          # Add quick links
          data.tp2_row.register 1000, () ->
            links = data.tp2_row.best('quicklinks')
            for link in ( links ? [] )
              data.tp2_row.add_value("quick_link",link)

          data.tp2_row.register 30000, () ->
            data.tp2_row.send("quick_links",(k.value for k in @all_values("quick_link") ? []))
          true

          data.tp2_row.register 30000, () ->
            name = data.tp2_row.best('name')
            id   = data.tp2_row.best('id')
            desc = data.tp2_row.best('description')
            if desc then data.tp2_row.candidate('description',desc,4)
            if name then data.tp2_row.candidate('description',name,3)
            if id   then data.tp2_row.candidate('description',id,2)
            data.tp2_row.candidate('description',"<em>No description</em>",1)

          # Put old description into new-contents
          # (you've had plenty of time to nuke it).
          data.tp2_row.register 40000, () ->
            desc = data.tp2_row.best('description')
            data.tp2_row.add_value('new-contents',desc,10)
            data.tp2_row.best('description','',100000)

          # Build description from contents
          data.tp2_row.register 50000, () ->
            vals = data.tp2_row.all_values('new-contents')
            vals = ( k.value for k in vals.sort((a,b) -> a.position - b.position) )
            desc = []
            tail = ""
            for c in vals
              if not c then continue
              c = $.trim(c).replace(new RegExp("\\.$"),'')
              if c == c.toUpperCase()
                c = c.toLowerCase()
              c = c.charAt(0).toUpperCase() + c.substring(1)
              desc.push(c)
              if not c.match(/\</) then tail = "."
            if desc.length
              data.tp2_row.candidate('description',desc.join(' ')+tail,10000)
            true

          data.tp2_row.register 51000, () ->
            data.tp2_row.send('description',data.tp2_row.best('description'))
            data.tp2_row.send('id',data.tp2_row.best('id'))
            data.tp2_row.send('url',data.tp2_row.best('url'))
            true
      ]

  faceter:
    template: """
      <div>
        <div class="table_faceter">
        </div>
      </div>
    """
    directives:
      '.table_faceter':
        'f<-faceters':
          '@data-key': 'f'
    preproc: (spec,data) ->
      data.faceters = $.solr_config('static.ui.facets_sidebar_order')
      [spec,data]
    postproc: (el,odata) =>
      $(document).on 'faceting_unknown', (e,update_seq) =>
        $('.table_faceter',el).each () ->
          if $(document).data('update_seq') != update_seq then return
          if $(@).data('update_seq') == update_seq then return
          $(@).empty()
      $(document).on 'faceting_known', (e,faceter,query,num,state,update_seq) =>
        $('.table_faceter',el).each () ->
          if $(document).data('update_seq') != update_seq then return
          key = $(@).data('key')
          order = []
          fav_order = $.solr_config('static.ui.facets.key=.fav_order',key)
          if fav_order? then order = $.solr_config('user.favs.%',fav_order)
          members = $.solr_config('static.ui.facets.key=.members',key)
          if members?
            for k in members
              order.push(k.key)
          model = { values: faceter[key], order }
          short_num = $.solr_config('static.ui.facets.key=.trunc',key)
          # Remove faceters which are already faceted on
          if query[key] then model.values = []
          # Remove faceters whose dependencies are not met
          deps = $.solr_config('static.ui.facets_sidebar_deps.%',key)
          if deps?
            for k, values of deps
              ok_value = false
              for value in values
                if query[k]? and query[k] == value
                  ok_value = true
                  break
              if not ok_value
                model.values = []
                break
          #
          model.key = key
          templates = $(document).data('templates')
          # in case we get triggered before faceting_unknown
          $(@).data('update_seq',update_seq)
          $(@).empty().append(templates.generate('faceter_inner',model))
        $('#main_holder').css('min-height',
                              $('.solr_sidebar').outerHeight(true) +
                              $('.solr_sidebar').offset().top)

  current_faceter:
    template: """<div class="current_table_faceter"></div>"""
    postproc: (el,data) =>
      data.els ?= []
      data.els.push(el)

  'current_faceter_inner':
    extends: 'beak'
    preproc: (spec,data) ->
      [spec,data] = spec.super.preproc(spec,data)
      [spec,data]
  
  sidecars:
    template: """<div class="sidecars"></div>"""

  'tips':
    template: """
      <div>
        <div class="sctips solr_beak_p">
          <div class="solr_beak_p_title">Tip:</div>
          <div class="sctips-buttons">
            <div class="sctips-b-prev"></div>
            <div class="sctips-b-next"></div>
          </div>
          <ul>
            <li>A tip</li>
          </ul>
        </div>
      </div>
    """
    directives:
      'li':
        'tip<-tips':
          '.': 'tip'
    decorate:
      'ul': (els,data) ->
        els.on 'incr', (e,incr) =>
          tip = els.data('tip') ? 0
          $(els.find('li')[tip]).css('opacity',0)
          len = els.find('li').length
          tip = (tip+len+(incr ? 1)) % len
          els.data('tip',tip)
          $(els.find('li')[tip]).css('opacity',1)

        els.on 'timeout', (e) =>
          now = new Date().getTime()
          past = els.data('timeout') ? now-1
          if past < now and not els.closest('.sctips').hasClass('sctinside')
            els.trigger('incr')
            past = now + 15000
            els.data('timeout',past)
          setTimeout((() => els.trigger('timeout')),past-now)

        els.find('li').css('opacity',0)
        els.trigger('timeout')

      '.sctips': (els,data) ->
        els.on 'mouseenter', () =>
          els.closest('.sctips').addClass('sctinside')
        els.on 'mouseleave', () =>
          els.closest('.sctips').removeClass('sctinside')

      '.sctips-b-next': (els,data) ->
        els.on 'click', () =>
          els.closest('.sctips').find('ul').trigger('incr')

      '.sctips-b-prev': (els,data) ->
        els.on 'click', () =>
          els.closest('.sctips').find('ul').trigger('incr',[-1])
    preproc: (spec,data) ->
      data.tips = $.solr_config('static.ui.tips')
      [spec,data]

