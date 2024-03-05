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
window.google_templates = 
  chunk:
    template: """
      <div>
        <div style="width: 100%" class='table_row'>
          <div class='table_result'>
            <div class='preview_float_click'>
              <div class='preview_float'></div>
            </div>
            <a class='table_toplink'></a>
            <div class='green_data'>
              <span class='id'></span>
              <a href='#' class='location'></a>
            </div>
            <div class='description'></div>
            <div class='quick_links'>
              <ul>
                <li><a href=''>link</a></li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    """
    directives:
      '.table_row':
        'row<-table_row':
          '.table_toplink@href': 'row.cols.url'
          '.id': 'row.cols.id'
          '.location': 'row.cols.location'
          '.location@href': 'row.cols.location_url'
          '.description': 'row.cols.description'
          '.table_toplink': 'row.cols.title'
          '.quick_links li':
            'link<-row.cols.quick_links':
              'a@href': 'link.url'
              'a': 'link.title'
          '@class+': 'row.cols.facets'
          '.table_result@class+': 'row.klass'
    decorate:
      '.table_result': (els,data) ->
         els.hover (e) =>
            el = $(e.target)
            present = {}
            for c in el.closest('.table_row').attr('class').split(/\s+/)
              m = /result_facet_(.*)/.exec(c)
              if m?.length
                present["solr_menu_class_"+m[1]] = 1
            $('.remote_hover').removeClass('remote_hover')
            for p,v of present
              $('.'+p).addClass('remote_hover')
          , =>

      '.preview_float_click': (els,data) ->
        els.on 'resized', =>
          if $(window).width() < 1400 or $('#solr_content').hasClass('solr_useless_browser')
            els.css('display','none')
            $('.preview_holder').css('display','none')
            $('.sidecar_holder').css('display','none')
          else
            els.css('display','')
            $('.preview_holder').css('display','')
        els.click (e) ->
          tr = $(this).parents('.table_result')
          unless $(e.target).is('a')
            if $(this).is(':visible')
              $('.preview_holder').trigger('preview_close')
              toplink = tr.find('.table_toplink')
              url = toplink.attr('href')
              title = "Preview of " + toplink.text()
              left = tr.offset().left+tr.outerWidth()
              $('.preview_holder').css('left',left+"px")
              holder= $('.preview_holder')
              tr.addClass('table_result_fake_hover')
              templates = $(document).data('templates')
              preview = templates.generate('preview',{
                url, title
                #prepare_extract_info: (iframe) => @prepare_extract_info(iframe)
                prepare_extract_info: (iframe) =>
              }).find('.g_preview')
              holder.append(preview)
              # Can't set this in the template due to IE9 bug: must only set it
              # after it's been added to the DOM.
              preview.find('iframe').attr('src',url)

    preproc: (spec,data) ->
      data.table_row = data.rows
      [spec,data]
    postproc: (el,data) ->
      $('.table_toplink',el).click ->
        $(document).trigger('ga',[
            'SrchMainLink',
            'standard',
            $(this).text(),
          ])
      $('.quick_links a',el).click ->
        $(document).trigger('ga',[
            'SrchQuickLink',
            $(this).text(),
            $(this).closest('.table_result').find('.table_toplink').text()
          ])
      # position sidecar holder
      tr = $('.table_result',el)
      $('html').on 'resized', () ->
        if $(window).width() < 1400 or $('#solr_content').hasClass('solr_useless_browser')
          $('.sidecar_holder').hide()
        else
          $('.sidecar_holder').show()
      $(window).load(() => $('html').trigger('resized'))
      $(window).resize(() => $('html').trigger('resized'))
      $('html').trigger('resized')
      $('.preview_float_click',el).trigger('resized')
      $(window).resize => $('.preview_float_click',el).trigger('resized')
      $('.search_table').hover((  => true) , =>
        $('.remote_hover').removeClass('remote_hover')
      )
      $('.solr_page_p_side').hover( =>
        $('.remote_hover').removeClass('remote_hover')
      , => )

    # XXX recursive more_fixes
    more_fixes: ['page','fix_g_variation','fix_regulation','fix_terse','fix_minor_types']
    fixes:
      global: [
        (data) ->

          data.tp2_row.register 5000, () ->
            ft = data.tp2_row.best('feature_type')
            rename = $.solr_config('static.ui.facets.key=.members.key=.text.singular','feature_type',ft)
            if rename
              data.tp2_row.candidate('feature_type',rename,10)

          data.tp2_row.register 100, () ->
            ft = data.tp2_row.best('feature_type')
            data.tp2_row.candidate('title_feature_type',ft,10)

          data.tp2_row.register 150, () ->
            loc = data.tp2_row.best('location')
            dom = data.tp2_row.best('domain_url')
            if loc? and dom?
              dom = dom.replace(/^\/?/,'',).replace(/\/.*$/,'')
              data.tp2_row.candidate('location_url',"/#{dom}/Location/View?r="+loc,10)

          data.tp2_row.register 1000, () ->
            sp = data.tp2_row.best('species')
            db = data.tp2_row.best('database_type')
            ref = data.tp2_row.best('ref_boost')
            ft = data.tp2_row.best('title_feature_type')

            if ft? then data.tp2_row.add_value('bracketed-title',ft,300)
            if sp? and sp != 'All'
              data.tp2_row.add_value('bracketed-title',sp,200)

            id = data.tp2_row.best('id')
            if db == 'vega' or id.match(/^OTT/)
              data.tp2_row.add_value('bracketed-title','Havana',250)
            if (ref? and ref == 0) and ft == 'Gene'
              data.tp2_row.add_value('bracketed-title','Alternative sequence',275)
              data.tp2_row.add_value('new-contents','<i>Not a Primary Assembly Gene</i>',200)

          data.tp2_row.register 10000, () ->
            sp = data.tp2_row.best('species')
            ft = data.tp2_row.best('feature_type')
            if sp?
              data.tp2_row.add_value('facet','result_facet_species_'+sp)
            if ft?
              data.tp2_row.add_value('facet','result_facet_feature_type_'+ft)
            values = ( k.value for k in data.tp2_row.all_values('facet') ? [])
            data.tp2_row.send('facets',' '+values.join(' '))

          data.tp2_row.register 20000, () ->
            bracketed = data.tp2_row.all_values('bracketed-title')
            if bracketed?
              vals = ( k.value for k in bracketed.sort((a,b) -> a.position - b.position) )
              data.tp2_row.candidate('bracketed',vals.join(' '),10)

          data.tp2_row.register 50000, () ->
            title = data.tp2_row.best('main-title')
            bracketed = data.tp2_row.best('bracketed')
            if bracketed?
              title += " (" + bracketed + ")"
            data.tp2_row.send('title',title)
            data.tp2_row.send('location_url',data.tp2_row.best('location_url'))
      ] 


  outer:
    template: """
      <div class="solr_g_layout">
        <div class="sidecar_holder table_acc_sidecars">
          <div class="tophit"></div>
          <div class="noresults noresults_side"></div>
          <div class="topgene"></div>
        </div>
        <div class="preview_holder"></div>
        <div class="se_search">
          <div class="se_query">
            <div class='hub_spinner g_spinner'></div>
            <div class='hub_fail g_fail'></div>
            <div class="solr_query_box">
              <div class="search_table_prehead_filterctl table_acc_ne">
              </div>
              <div class="solr_result_summary"></div>
            </div>
          </div>
          <div class='search_table_holder page_some_query'>
            <div class='page_some_results'>
              <div class='main_topcars'>
                <div class='searchdown'></div>
                <div class='noresults noresults_main'></div>
                <div class='narrowresults'></div>
                <div class='sidecars'></div>
              </div>
              <div class='search_table_proper'>
              </div>
              <div class='se_search_table_posttail'>
                <div class='search_table_posttail_pager table_acc_sw'>
                  <div class="pager"></div>
                </div>
              </div>
            </div>
            <div class='page_no_results'>
              <div class="table_acc_noresults"></div>
              <div class='noresults_maincars'>
                <div class='sidecars'></div>
              </div>
            </div>
          </div>
          <div class='page_no_query g_page_no_results'>
          </div>
        </div>
      </div>
    """
    subtemplates:
      '.tophit': 'tophit'
      '.topgene': 'topgene'
      '.noresults': 'noresults'
      '.searchdown': { template: 'searchdown', data: '' }
      '.narrowresults': 'narrowresults'
      '.pager': { template: 'pager', data: '' }
      '.search_table_prehead_filterctl': {template: 'replacement-filter', data: '' }
    decorate:
      '.preview_holder': (els,data) ->
        els.on 'preview_close', () ->
          els.empty().css('left','100%')
          $('.table_result_fake_hover').removeClass('table_result_fake_hover')
      '.solr_result_summary': (els,data) ->
        $(document).on 'faceting_known', (e,faceter,used_facets,num,state,update_seq) =>
          templates = $(document).data('templates')
          els.empty()
          if $(document).data('update_seq') != update_seq then return
          els.append(templates.generate('result_summary',{
            query: state.q_query(), num, used_facets
          }))
          $('.search_table_holder').css('margin-top',$('.solr_query_box').height()+31)
    postproc: (el,data) ->
      $('html').on 'wrap', (e) ->
        $('.maybe_wrap').each () ->
          $el = $(@)
          $el.css('overflow','hidden')
          if @clientHeight != @scrollHeight or @clientWidth != @scrollWidth
            $el.addClass('was_wrapped')
#      $('html').on 'resize load', (e) ->
#        $('.search_table_holder').css('margin-top',$('.solr_query_box').height()+24)
      data.table_ready(el,data)

  'result_summary':
    template: """
      <div class="solr_result_stmt">
        <span class="solr_result_count">0</span> results
        match <span class="solr_result_query">your search</span>
        <span class="solr_result_restricted">
          when restricted to
          <ul>
            <li>
              <a href="#">
                <span class="solr_result_fname">A</span>: 
                <span class="solr_result_fval">AA</span>
              </a>
            </li>
          </ul>
        </span>
      </div>
    """
    directives:
      '.solr_result_count': 'num'
      '.solr_result_query': (e) ->
        $('<div/>').text(e.context.query).html()
      '.solr_result_restricted':
        'fs<-facets':
          'li':
            'f<-fs':
              '.solr_result_fname': 'f.left'
              '.solr_result_fval': 'f.right'
              'a@href': 'f.href'
    decorate:
      'li': (els,data) ->
        els.click (e) ->
          $(@).find('a').trigger('click')
          false
      'a': (els,data) ->
        els.each () ->
          $(@).click (e) =>
            el = $(e.currentTarget)
            href = el.attr('href')
            href = href.substring(href.indexOf('#')) # IE7, :-(
            state = { page: 1 }
            key = href.substring(1)
            state['facet_'+key] = ''
            # Remove any facets that depend on it
            # XXX should be de-duped from other use
            deps = $.solr_config('static.ui.facets_sidebar_deps')
            if deps?
              for dep,data of deps
                for sup,value of data
                  if sup == key
                    state['facet_'+dep] = ''
            #
            $(document).trigger('update_state',[state])
            $(document).trigger('ga',['SrchGreenCross',href.substring(1)])
            false

    preproc: (spec,data) ->
      facets = []
      facet_species = data?.used_facets?.species || '';
      strain_type = $.solr_config('static.ui.strain_type.%', facet_species);
      if !strain_type
        strain_type = 'strain';
      for k,v of data.used_facets
        value = $.solr_config('static.ui.facets.key=.members.key=.text.plural',k,v)
        if not value? then value = $.solr_config('static.ui.facets.key=.members.key=.key',k,v)
        if not value? then value = v

        facets.push {
          left: $.solr_config('static.ui.facets.key=.text.singular',k).replace(/__strain_type__/,strain_type)
          right: $('<div/>').text(value).html()
          href: '#'+k
        }
      if facets.length
        data.facets = [ facets ]
      [spec,data]

  'replacement-filter':
    template: """
      <div>
        <span>
          <div>
            <span class="replacement_filter">
              <div>
                <input type="text" placeholder="Enter search term..." data-role="none"/>
              </div>
            </span>
          </div>
          <span class="search_button"><span class="icon"></span></span>
        </span>
      </div>
    """
    decorate:
      '.search_button': (els,data) ->
        els.click =>
          q = els.parents('.se_search').find('.replacement_filter input:not(.solr_ghost)').val()
          $(document).trigger('maybe_update_state',{ q, page: 1 })
      'input': (els,data) ->
        $(document).on 'state_known', (e,state,update_seq) ->
          if $(document).data('update_seq') != update_seq then return
          els.val(state.q_query())
#        els.searchac().keyup (e) ->
#          $(document).trigger('update_state_incr',{ q: $(this).val(), page: 1 })
        els.searchac().keydown (e) ->
          if e.keyCode == 13
            $(this).trigger("blur")
            $(this).searchac('close')
            $(document).trigger('maybe_update_state',{ q: $(this).val(), page: 1 })
    postproc: (el,data) ->
      $(document).on 'maybe_update_state', (e,change,incr) ->
        facet_species = data?.state?.hub?.params?.facet_species
        query_params = { q: '' }
        query_params.q = change.q if change.q
        query_params.species = facet_species if facet_species
        $.getJSON "/Multi/Ajax/psychic", query_params , (data) ->
          if data?.redirect
            $(document).trigger('ga',['SrchPsychic','redirect',data.url])
            window.location.href = data.url
          else
            $(document).trigger('update_state',change)
      $(document).on 'state_known', (e,state,update_seq) ->
        if $(document).data('update_seq') != update_seq then return
        facets = state.q_facets()
        filter = $('.replacement_filter',el)
        texts = []
        ids = []
        filter.selbox {
          action: (id,text,opts) =>
            match = text.match(/<b>(.*)<\/b>/)
            label = if match and match[1] then "#{match[1]}-#{id}" else id
            $(document).trigger('ga', ['SearchInputFacetDropdown', 'SearchPageResults', label])
            state = { page: 1 }
            state['facet_'+id] = ''
            $(document).trigger('update_state',state)
          selchange: () ->
            @centered({ max: 14, inc: 2 })
        }
        filter.selbox("deactivate")
        title = []
        for f in $.solr_config("static.ui.facets")
          if not facets[f.key] then continue
          strain_type = $.solr_config('static.ui.strain_type.%', facets.species);
          if !strain_type
            strain_type = 'strain';
          left = ucfirst($.solr_config("static.ui.facets.key=.text.plural",f.key).replace(/__strain_type__/,strain_type))
          right = $.solr_config("static.ui.facets.key=.members.key=.text.plural",f.key,facets[f.key]) ? $('<div/>').text(facets[f.key]).html()
          texts.push """
            Search other <i>#{left}</i>,
            not just <b>#{right}</b>.
          """
          ids.push(f.key)
          title.push($('<div/>').text(right).html())
        data.title = "Only searching "+title.join(" ")
        if ids.length
          filter.selbox("activate",data.title,texts,ids)

  download:
    template: "<div></div>"

  preview:
    template: """
      <div class="g_preview">
        <div class="g_preview_closer"></div>
        <h1>Preview</h1>
        <ul class="g_preview_quick_links"></ul>
        <div class="g_preview_noclick">
          <div class="g_preview_noclick_textcarrier">
            <span class="g_preview_noclick_text">&#x25BA;</span>
          </div>
        </div>
        <div class='g_preview_spinner_outer preview_spinner'>
          <div class='g_preview_spinner'>
            <div class='g_preview_spinner_inner'>
              <div class='g_preview_spinner_img'></div>
            </div>
          </div>
        </div>
        <div class="g_preview_placer">
          <div class="g_preview_border">
            <div class="g_preview_shrinker">
              <iframe id="preview_iframe" name="preview_iframe" scrolling="no"></iframe>
            </div>
          </div>
          <div class="g_preview_border_s"></div>
        </div>
      </div>
    """
    directives:
      'h1': 'title'
    decorate:
      '.g_preview_placer': (el,data) ->
        el.on 'resized', =>
          el.css('width','')
          el.width(Math.floor(el.width()/30)*30+1)
          noclick = $('.g_preview_noclick')
          noclick
            .css('left',el.offset().left+50)
            .css('top',el.offset().top+50)
            .css('width',(el.outerWidth()-100)+'px')
            .css('height',(el.outerHeight()-70)+'px')
      '#preview_iframe': (el,data) -> 
        el.load ->
          scale = 0.6
          placer = $('.g_preview_placer')
          if el.attr('src') then $('.preview_spinner').hide()
          placer.show()
          placer.trigger('resized')
          $(window).resize(( => placer.trigger('resized')))
          # Overlay click preventer
          noclick = $('.g_preview_noclick')
          button = noclick.find('.g_preview_noclick_text')
          button.css('margin-top',(noclick.height()-button.height())/2)
          noclick.click (e) =>
            url = $(this).parents('.g_preview').find('iframe').attr('src')
            window.location.href = url
        data.prepare_extract_info(el)
        el.on 'try_extract_info', () ->
          setTimeout(() =>
            el.trigger('extract_info')
            if not el.hasClass('extracted')
              el.trigger('try_extract_info')
          ,50)
        el.on 'extract_info', () ->
          if el.hasClass('extracted') then return true
          contents = el.contents()
          if contents.find('.local_context').length == 0 then return false
          menu = $(".local_context",contents)
          items = menu.find('a').clone().wrap('<li></li>').parent()
          items.appendTo(el.parents('.g_preview').find('.g_preview_quick_links'))
          el.addClass('extracted')
        el.load => el.trigger('extract_info')
        el.trigger('try_extract_info')
      '.g_preview_closer': (el,data) ->
        el.on 'click', =>
          $('.preview_holder').trigger('preview_close')
    postproc: (el,data) ->
      el.mouseenter (e) => data.hover()
      el.mouseleave (e) => data.unhover()

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

ucfirst = (str) ->
  str.charAt(0).toUpperCase() + str.substring(1)

window.pedestrian_templates =
  current_facets_sidebar:
    template: """
      <div>
        <div class='solr_faceter solr_beak_p solr_faceter_current solr_menu_current'>
          <div class='solr_beak_p_title'>Title</div>
          <div class='solr_curfac_contents'>
            <div class='solr_curfac_row'>
              <a class='solr_curfac_left'>
                All x 
              </a>
              <span class='solr_curfac_right'>42</span>
            </div>
          </div>
        </div>
      </div>
    """
    directives:
      '.solr_beak_p_title': 't<-title': '.': 't'
      '.solr_curfac_row':
        'row<-rows':
          'a@href': 'row.href'
          '.solr_curfac_left': 'row.left'
          '.solr_curfac_right': 'row.right'
    preproc: (spec,data) ->
      rows = []

      # Get the facet_species from the URL
      facet_species_url_param = new RegExp('[?&;]facet_species(=([^&#;]*)|&|#|$)').exec(window.location.href) || [];
      if facet_species_url_param[2] 
        facet_species = decodeURIComponent(facet_species_url_param[2].replace(/\+/g, ' '));
      
      strain_type = $.solr_config('static.ui.strain_type.%',facet_species);
      if !strain_type
        strain_type = 'strain';

      for f in $.solr_config("static.ui.facets")
        if data.values[f.key]?
          rows.push {
            href: "#"+f.key
            left: "&lt; all " + ucfirst($.solr_config("static.ui.facets.key=.text.plural",f.key).replace(/__strain_type__/,strain_type))
            right: "Only searching " + ($.solr_config("static.ui.facets.key=.members.key=.text.plural",f.key,data.values[f.key]) ? $('<div/>').text(data.values[f.key]).html())
          }
      data.rows = rows
      if data.rows.length
        data.title = [ $.solr_config('static.ui.current_facets_heading') ]
      else
        data.title = []
      [spec,data]
    decorate:
      'a': (els,data) =>
        els.click (e) =>
          el = $(e.currentTarget)
          href = el.attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          state = { page: 1 }
          key = href.substring(1)
          state['facet_'+key] = ''
          # Remove any facets that depend on it
          deps = $.solr_config('static.ui.facets_sidebar_deps')
          if deps?
            for dep,data of deps
              for sup,value of data
                if sup == key
                  state['facet_'+dep] = ''
          #
          $(document).trigger('update_state',[state])
          $(document).trigger('ga',['SrchFacetLHSOff',href.substring(1)])
          false
    postproc: (el,data) ->
      $('#main_holder').css('min-height',
                            $('.solr_sidebar').outerHeight(true) +
                            $('.solr_sidebar').offset().top)
  
  beak:
    config:
      short_num: (data) ->
        return $.solr_config('static.ui.facets.key=.trunc',data.type)

    template: """
      <div>
        <div class='solr_faceter solr_beak_p'>
          <div class='solr_beak_p_title'>Title</div>
          <div class='solr_beak_p_contents'>
            <a>
              <span class='solr_beak_p_left'>Hello, World!</span>
              <span class='solr_beak_p_right'>42</span>
            </a>
          </div>
        </div>
      </div>
    """
    directives:
      '.solr_faceter@class+': (e) ->
        klass = ''
        if e.context.css_class then klass += ' ' + e.context.css_class
        klass
      '.solr_beak_p_title': 't<-title': '.': 't'
      'a':
        'entry<-entries':
          '@href': (e) -> "#"+e.item.key
          'span.solr_beak_p_left': 'entry.label.left'
          'span.solr_beak_p_right': 'entry.label.right'
          '@class+': (e) -> if e.item.klass? then ' '+e.item.klass else ''
    preproc: (spec,data) ->
      data.title = (if data?.title then [data.title] else [])
      e.label = { left: e.label } for e in data.entries when not e.label.left?
      [spec,data]
    decorate:
      'a': (els,data) =>
        els.click (e) =>
          el = $(e.currentTarget)
          href = el.attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          if href == '#'
            data.fold(data.folder_state)
          else
            data.select(href.substring(1),el)
          false
      '.solr_beak_p': (els,data) =>
        els.on 'mouseleave', (e) =>
          if data.fold
            data.fold(data.folder_state,true,30000)
          false
    postproc: (el,data) =>
      data.set_fn = (v) =>
        $('.solr_feet_p_current',el).removeClass('solr_feet_p_current')
        if v
          $("a[href='##{v}']",el).addClass('solr_feet_p_current')

  faceter_inner:
    config:
      short_num: (data) ->
        return $.solr_config('static.ui.facets.key=.trunc',data.type)

    template: """
      <div>
        <div class='solr_faceter solr_beak_p'>
          <div class='solr_beak_p_title'>Title</div>
          <div class='solr_beak_p_less'>
            <a href='#'>
              <span class='solr_beak_p_left'>show fewer species</span>
            </a>
          </div>
          <div class='solr_beak_p_contents'>
            <a>
              <span class='solr_beak_p_left'>Hello, World!</span>
              <span class='solr_beak_p_right'>42</span>
            </a>
          </div>
          <div class='solr_beak_p_more'>
            <a href='#'>
              <span class='solr_beak_p_left'>... <b>xxx</b> more species ...</span>
            </a>
          </div>
          <div class='solr_beak_p_less'>
            <a href='#'>
              <span class='solr_beak_p_left'>show fewer species</span>
            </a>
          </div>
        </div>
      </div>
    """
    directives:
      '.solr_beak_p_title': 't<-title': '.': 't'
      '.solr_beak_p_contents a':
        'entry<-entries':
          '@class+': (e) -> if e.item.klass? then ' '+e.item.klass else ''
          '@href': (e) -> "#"+e.item.key
          'span.solr_beak_p_left': 'entry.name'
          'span.solr_beak_p_right': 'entry.num'
      '.solr_beak_p_more a': 'more_text'
      '.solr_beak_p_less a': 'less_text'
    decorate:
      'a': (els,data) =>
        els.click (e) =>
          el = $(e.currentTarget)
          href = el.attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          state = { page: 1 }
          state["facet_#{data.key}"] = href.substring(1)
          $(document).trigger('update_state',[state])
          $(document).trigger('ga',['SrchFacetLHSOn',data.key,href.substring(1)])
          false
      '.solr_beak_p': (els,data) =>
        els.on 'mouseleave', (e) =>
          if data.fold
            data.fold(data.folder_state,true,30000)
          false
      '.solr_beak_p_more a': (els,data) ->
        els.click () ->
          state = {}
          state["fall_"+data.key] = '1'
          $(document).trigger('update_state',[state])
          $(document).trigger('ga',['SrchFacetLHSMore',data.key])
          false
      '.solr_beak_p_less a': (els,data) ->
        els.click () ->
          state = {}
          state["fall_"+data.key] = ''
          $(document).trigger('update_state',[state])
          $(document).trigger('ga',['SrchFacetLHSLess',data.key])
          false
    preproc: (spec,data) ->
      data.entries = []
      orders = data.order[..].reverse()
      reorder = $.solr_config('static.ui.facets.key=.reorder',data.key)
      for i in[0..data.values.length/2-1] by 1
        name = data.values[i*2]
        rename = $.solr_config("static.ui.facets.key=.members.key=.text.singular",data.key,name)
        if rename? then name = rename
        order = $.inArray(name,orders)
        if order == -1 and reorder
          for reo,j in reorder
            if name.match(reo)
              order = j
              break
        data.entries.push {
          key: data.values[i*2]
          name, order
          num: data.values[i*2+1]
        }
      data.entries = data.entries.sort (a,b) ->
        if a.order != -1 or b.order != -1
          return b.order - a.order
        return a.name.localeCompare(b.name)
      # Get the facet_species from the URL
      facet_species_url_param = new RegExp('[?&;]facet_species(=([^&#;]*)|&|#|$)').exec(window.location.href) || [];
      if facet_species_url_param[2] 
        facet_species = decodeURIComponent(facet_species_url_param[2].replace(/\+/g, ' '));
      
      # Get the strain type for the facet_species
      strain_type = $.solr_config('static.ui.strain_type.%',facet_species);
      
      # set the default strain type as strain
      if !strain_type
        strain_type = 'strain';
      

      short_num = $.solr_config('static.ui.facets.key=.trunc',data.key);
      title = $.solr_config('static.ui.facets.key=.heading',data.key).replace(/__strain_type__/,strain_type);
      data.more_text = $.solr_config("static.ui.facets.key=.more",data.key).replace(/__strain_type__/,strain_type);
      data.less_text = $.solr_config("static.ui.facets.key=.less",data.key).replace(/__strain_type__/,strain_type);

      data.title = ( if data.entries.length then [title] else [] )
      for e in data.entries
        e.klass = ' solr_menu_class_'+(data.key)+'_'+e.name
      
      data.more_text = data.more_text.replace(/\#\#/,data.entries.length-short_num)
      [spec,data]
    postproc: (el,data) ->
      $(el).on 'trim', (e,num) ->
        links = $('.solr_beak_p_contents a',el)
        $('.solr_beak_p_less',el).hide()
        $('.solr_beak_p_more',el).hide()
        if num > 0
          # trim
          links.css('display','block').each (i) ->
            if i >= num then $(@).hide()
          if links.length > num
            $('.solr_beak_p_more',el).css('display','block')
        else if links.length > -num
          # untrim
          links.css('display','block')
          $('.solr_beak_p_less',el).css('display','block')
        $('#main_holder').css('min-height',
                              $('.solr_sidebar').outerHeight(true) +
                              $('.solr_sidebar').offset().top)

      data.set_fn = (v) =>
        $('.solr_feet_p_current',el).removeClass('solr_feet_p_current')
        if v
          $("a[href='##{v}']",el).addClass('solr_feet_p_current')
     
      $(document).on 'state_change', (e,params) ->
        short_num = $.solr_config('static.ui.facets.key=.trunc',data.key)
        sense = params["fall_"+data.key]
        el.trigger('trim',[if sense then -short_num else short_num])
      $(document).trigger('force_state_change')

  feet:
    extends: 'beak'
    preproc: (spec,data) ->
      [spec,data] = spec.super.preproc(spec,data)
      data.css_class = (data.css_class ? '') + ' solr_feet_p'
      [spec,data]
 
  sctips:
    template: """
      <div class="sctips solr_beak_p">
        <div class="solr_beak_p_title">Tip:</div>
        <div class="sctips_contents"></div>
      </div>
      """
    subtemplates:
      '.sctips_contents': { template: 'sctips_contents', data: '' }
 
  sidesizer:
    template: """
      <div class="solr_faceter solr_beak_p solr_feet_p">
        <div class="solr_beak_p_title">Per page:</div>
        <div class='solr_beak_p_contents solr_perpage_list'>
          <a>
            <span class='solr_beak_p_left'>42</span>
            <span class='solr_beak_p_right'></span>
          </a>
        </div>
        <!-- not for now: need to re-engineer
        <div class='solr_beak_p_contents solr_perpage_all'>
          <a href="#0">
            <span class='solr_beak_p_left'>Show all results in one page</span>
            <span class='solr_beak_p_right'></span>
          </a>
        </div>
        -->
      </div>
    """
    directives:
      '.solr_perpage_list a':
        'entry<-entries':
          'span.solr_beak_p_left': 'entry.label'
          '@href': (e) -> '#'+e.item.key
    decorate:
      'a': (els,data) ->
        els.click (e) =>
          href = $(e.currentTarget).attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          $(document).trigger('update_state',{ perpage: href.substring(1) })
          $(document).trigger('ga',['SrchPerPage','LayoutLHSMenu',href.substring(1)])
          false
    preproc: (spec,data) ->
      data.entries = []
      for x in $.solr_config("static.ui.pagesizes")
        if x == 0 then continue
        data.entries.push({ label: (if x then x else "all"), key: x})
      [spec,data]
    postproc: (el,data) ->
      $(document).on 'state_known', (e,state,update_seq) ->
        if $(document).data('update_seq') != update_seq then return
        $('.solr_feet_p_current',el).removeClass('solr_feet_p_current')
        pp = state.pagesize()
        $("a[href='##{pp}']",el).addClass('solr_feet_p_current')

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
_ajax_json = (url,data,success) ->
  $.ajax({
    url, data, traditional: true, success, dataType: 'json',
  })

window.rhs_templates =
  tophit:
    template: """
      <div class="solr_tophit">
      </div>
    """
    postproc: (el,data) ->
      render_canvas = (canvas,location,text,colour) ->
        ctx = canvas.getContext('2d')
        line = (ctx,x,y,w,h) ->
          ctx.beginPath()
          ctx.moveTo(x+0.5,y+0.5)
          ctx.lineTo(x+w+0.5,y+h+0.5)
          ctx.closePath()
          ctx.stroke()
        arrow = ((ctx,x,y,s,d) -> line(ctx,x,y,d*s,-s) ; line(ctx,x,y,d*s,s))
        ctx.lineWidth = 1
        ctx.strokeStyle = '#cccccc'
        [chr,start,end,strand] = location.split /[:-]/
        start = parseInt(start)
        end = parseInt(end)
        len = end - start + 1
        size = parseInt('1'+new Array(len.toString().length+1).join('0'))
        sstr = size.toString().replace(/000$/,'k').replace(/000k$/,'M') + 'b'
        img_start = (end+start-size)/2
        bp_per_px = size / canvas.width
        h = canvas.height
        step = size/13/bp_per_px
        step_start = (Math.floor(img_start/step)*step - img_start)/bp_per_px
        for i in [0..13]
          offset = step_start + step * i
          line(ctx,offset,0,0,h)
          unless i%2
            ctx.fillRect(offset,0,step,3)
        ctx.fillStyle = colour
        ctx.fillRect((start-img_start)/bp_per_px,30,len/bp_per_px,6)
        ctx.font = '10px sans-serif'
        text = ( if parseInt(strand) > 0 then text+" >" else "< "+text )
        ctx.fillText(text,(start-img_start)/bp_per_px,25)
        ctx.fillText(location,step_start+step*4+4,45)
        ctx.strokeStyle = 'black'
        ctx.fillStyle = 'black'
        ctx.lineWidth = 1
        line(ctx,0,0,canvas.width,0)
        line(ctx,0,3,canvas.width,0)
        line(ctx,step_start+step*2,10,step*4,0)
        line(ctx,step_start+step*8,10,step*4,0)
        arrow(ctx,step_start+step*2,10,4,1)
        arrow(ctx,step_start+step*12,10,4,-1)
        ctx.fillText(sstr,step_start+step*6,15)
      
      $(document).on 'main_front_page', (e,results,state,update_seq) ->
        if state.page() != 1 or !results.length then return
        for tophit in results
          el.empty()
          if not tophit? then continue
          if tophit.feature_type != 'Gene' then continue
          extra = {}
          desc = tophit.description.replace /\[(.*?)\:(.*?)\]/g, (g0,g1,g2) ->
            extra[$.trim(g1).toLowerCase()] = $.trim(g2)
            ''
          if extra.source
            extra.source = extra.source.replace(/;/g,'; ')
          latin = $.solr_config('spnames.%',tophit.species)
          _ajax_json "/Multi/Ajax/extra", {
            queries: JSON.stringify({
              queries: [
                { ft: 'Gene', id: tophit.id, species: latin, req: ['biotype','bt_colour'], db: tophit.database_type }
              ]})
          }, (data) =>
            if $(document).data('update_seq') != update_seq then return
            [biotype,bt_colour] = data.result
            templates = $(document).data("templates")
            el.append(templates.generate('sctophit',{
              q: state.q_query(), url: tophit.url, name: tophit.name,
              ft: "Gene"
              species: tophit.species
              source: extra.source, latin: latin
              location: tophit.location
              render_canvas
              biotype, bt_colour, description: desc
            }))
            $('html').trigger('wrap')
          return
  
  sctophit:
    template: """ 
      <div class="sctophit scside">
        <div class="scth_play">&#x21AA;</div>
        <h1>Best gene match</h1>
        <div class="scth_left">
          <div class="scth_type"></div>
          <div class="scth_name maybe_wrap"></div>
          <div class="scth_source"></div>
        </div>
        <div class="scth_right">
          <div class="scth_top">
            <div class="scth_species">
              <img alt="" title=""/>
            </div>
            <div class="scth_canvas">
              <div class="scth_canvas_holder">
                <canvas width="221" height="58">
                  Click for full details
                </canvas>
              </div>
            </div>
          </div>
          <div class="scth_biotype"></div>
          <div class="scth_desc"></div>
        </div>
      </div>
    """ 
    directives:
      '.scth_name': 'name'
      '.scth_type': 'title'
      '.scth_source': 'source'
      '.scth_species img@src': 'img'
      '.scth_species img@alt': 'species'
      '.scth_species img@title': 'species'
      '.scth_biotype': 'biotype'
      '.scth_desc': 'description'
    decorate:
      '.scth_canvas canvas': (el,data) ->
        if el.length == 0 or not el[0]? or not el[0].getContext? then return
        ctx = el[0].getContext('2d')
        line = (ctx,x,y,w,h) ->
          ctx.beginPath()
          ctx.moveTo(x+0.5,y+0.5)
          ctx.lineTo(x+w+0.5,y+h+0.5)
          ctx.closePath()
          ctx.stroke()
        arrow = ((ctx,x,y,s,d) -> line(ctx,x,y,d*s,-s) ; line(ctx,x,y,d*s,s))
        ctx.lineWidth = 1
        ctx.strokeStyle = '#cccccc'
        [chr,start,end,strand] = data.location.split /[:-]/
        start = parseInt(start)
        end = parseInt(end)
        len = end - start + 1
        size = parseInt('1'+new Array(len.toString().length+1).join('0'))
        sstr = size.toString().replace(/000$/,'k').replace(/000k$/,'M') + 'b'
        img_start = (end+start-size)/2
        bp_per_px = size / el[0].width
        h = el[0].height
        step = size/13/bp_per_px
        step_start = (Math.floor(img_start/step)*step - img_start)/bp_per_px
        for i in [0..13]
          offset = step_start + step * i
          line(ctx,offset,0,0,h)
          unless i%2
            ctx.fillRect(offset,0,step,3)
        ctx.fillStyle = data.bt_colour
        ctx.fillRect((start-img_start)/bp_per_px,30,len/bp_per_px,6)
        ctx.font = '10px sans-serif'
        text = ( if parseInt(strand) > 0 then data.name+" >" else "< "+data.name )
        ctx.fillText(text,(start-img_start)/bp_per_px,25)
        ctx.fillText(data.location,step_start+step*4+4,45)
        ctx.strokeStyle = 'black'
        ctx.fillStyle = 'black'
        ctx.lineWidth = 1
        line(ctx,0,0,el[0].width,0)
        line(ctx,0,3,el[0].width,0)
        line(ctx,step_start+step*2,10,step*4,0)
        line(ctx,step_start+step*8,10,step*4,0)
        arrow(ctx,step_start+step*2,10,4,1)
        arrow(ctx,step_start+step*12,10,4,-1)
        ctx.fillText(sstr,step_start+step*6,15)
      
      '.sctophit': (el,data) ->
        el.on 'click', (e) =>
          $(document).trigger('ga',['SrchBoxes','tophit',data.url])
          window.location.href = data.url

    preproc: (spec,data) ->
      data.img = "/i/species/64/#{data.latin}.png"
      data.biotype = data.biotype.replace(/_/g,' ')
      data.biotype = "#{data.biotype} #{data.ft}"
      data.biotype = data.biotype.charAt(0).toUpperCase() + data.biotype.substring(1).toLowerCase()
      data.title = "#{data.species} #{data.ft}"
      [spec,data]

  'topgene':
    template: """
      <div class='solr_topgene'>
      </div>
    """
    postproc: (el,data) ->
      $(document).on 'main_front_page', (e,results,state,update_seq) ->
        el.empty()
        if state.page() != 1 or !results.length then return
        params = {
          q: 'name:"'+state.q_query()+'"'
          rows: 200
          fq: "feature_type:Gene AND database_type:core"
          'facet.field': "species"
          'facet.mincount': 1
          facet: true
        }
        # XXX currency
        _ajax_json "/Multi/Ajax/search", params, (data) =>
          if $(document).data('update_seq') != update_seq then return
          sp_glinks = {}
          docs = data.result?.response?.docs
          if docs?
            for d in docs
              if d.ref_boost >= 10 and d.species and d.domain_url
                url = d.domain_url
                if url?.charAt(0) != '/' then url = "/" + url
                sp_glinks[d.species] = "/"+d.domain_url
          if (k for k,v of sp_glinks).length > 0
            rows = ( k for k,v of sp_glinks )
            favord = []
            for s,i in $.solr_config('user.favs.species')
              favord[s] = i
            rows = rows.sort (a,b) ->
              if favord[a]? and ((not favord[b]?) or favord[a] < favord[b])
                return -1
              if favord[b]? then return 1
              return a.localeCompare(b)
            templates = $(document).data("templates")
            el.append(templates.generate('sctopgene',{ urls: sp_glinks, rows, q: state.q_query() }))

  sctopgene:
    template: """
      <div class="sctopgene scside">
        <h1>Direct link to genes named "<span></span>"</h1>
        <ul>
          <li>
            <a href="#">
              <img src="" alt="" title=""/>
            </a>
          </li>
        </ul>
        <div class="sctg_dots">more ...</div>
      </div>
    """
    directives:
      'li':
        'sp<-entries':
          'img@src': 'sp.url'
          'img@alt': 'sp.name'
          'img@title': 'sp.name'
          'a@href': 'sp.link'
      'h1 span': 'q'
    decorate:
      '.sctg_dots': (el,data) ->
        if data.entries.length <= 8 # num on first row
          el.hide()
      '.sctopgene': (el,data) ->
        if data.entries.length <= 8 # num on first row
          el.css('max-height','inherit')
    preproc: (spec,data) ->
      entries = []
      for n in data.rows
        latin = $.solr_config("spnames.%",n)
        if latin
          entries.push {
            url: "/i/species/48/#{latin}.png" 
            link: data.urls[n]
            name: n
          }
      data.entries = entries
      [spec,data]
    
  noresultssuggest:
    template: """
      <div class="scsuggest">
        <div class="scsug-fold"><a href='#'>Did you mean... <small>&#x25BC;</small></a></div>
        <div class="scsug-main">
          <h1>Suggestions</h1>
          <div class="cloud">
            <a href="#">word</a>
          </div>
        </div>
      </div>
    """
    directives:
      '.cloud a':
        'word<-suggestions':
          '.': 'word.word'
          '@href': (e) -> "#" + e.item.word
          '@style': (e) ->
            w = e.item.weight
            col = [3*16,6*16,11*16] # #36b
            col[i] = Math.floor(w*c + 255*(1-w)) for c,i in col
            out = "background: rgb(" + col.join(",") + "); color: rgb("
            s = Math.floor((1-w)*64)
            f = Math.floor(w*12)+10
            out += [s,s,s].join(",")+"); font-size: #{f}px;"
            out
    decorate:
      '.cloud a': (els,data) ->
        els.on 'click', (e) =>
          el = $(e.currentTarget)
          href = el.attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          state = { page: 1 }
          for f in $.solr_config('static.ui.facets')
            if f.key == 'species' then continue
            state["facet_"+f.key] = ''
          state.q = href.substring(1)
          $(document).trigger('update_state',[state])
          $(document).trigger('ga',['SrchSuggest','click',state.q])
          false
      '.scsug-main': (els,data) ->
        if data.someresults and data.mainflow
          els.addClass('scnbox-hidden')
        els.addClass(if data.mainflow then 'scnarrow' else 'scside')
      '.scsug-fold': (els,data) ->
        if not data.someresults or not data.mainflow then els.hide()
      '.scsug-fold a': (els,data) ->
        els.on 'click', () =>
          els.closest('.scsuggest').find('.scsug-main')
            .toggleClass('scnbox-hidden')
          false

  noresults:
    template: """
      <div></div>
    """
    postproc: (el,data) ->
      $(document).on 'num_known', (e,num,state,update_seq) ->
        if !state.q_query() then return
        species = window.solr_current_species()
        if !species then species = 'all'
        sp_q = species+'__'+state.q_query().toLowerCase()
        _ajax_json "/Multi/Ajax/search", {
          'spellcheck.q': sp_q
          spellcheck: true
          'spellcheck.count': 50
          'spellcheck.onlyMorePopular': false
        }, (data) =>
          if $(document).data('update_seq') != update_seq then return
          suggestions = []
          words = data.result?.spellcheck?.suggestions?[1]?.suggestion
          unless words?.length then return
          for word,i in words
            word = word.replace(/^.*?__/,'')
            w = Math.sqrt(((words.length-i)/words.length))
            if num then w = w/2
            suggestions.push {
              word
              weight: w*w
            }
          mainflow = ( num == 0 or
              not $('.sidecar_holder').is(':visible') or
              not $('.sidecar_holder').length )
          dest = null
          el.empty()
          el.each () ->
            if mainflow and $(@).closest('.noresults_main').length
              dest = $(@)
            else if (not mainflow) and $(@).closest('.noresults_side').length
              dest = $(@)
          templates = $(document).data("templates")
          dest.append(templates.generate('noresultssuggest',{
            suggestions,
            someresults: ( num != 0 )
            mainflow
          }))

  narrowresults:
    template: """
      <div></div>
    """
    postproc: (el,data) ->
      $(document).on 'num_known', (e,num,state,update_seq) ->
        el.empty()
        query = state.q_query()
        facets = state.q_facets()
        if !query or num then return
        all_facets = (f.key for f in $.solr_config('static.ui.facets'))
        _ajax_json "/Multi/Ajax/search", {
            q: query
            rows: 1
            'facet.field': all_facets
            'facet.mincount': 1
            facet: true
          }, (data) =>
            if $(document).data('update_seq') != update_seq then return
            cur_values = []
            othervalues = []
            for f in all_facets
              if facets[f] then cur_values.push([f,facets[f]])
              if data.result?.facet_counts?.facet_fields?[f]?
                entries = 0
                total = 0
                for e,i in data.result?.facet_counts?.facet_fields?[f]
                  if i%2
                    entries += 1
                    total += e
                if entries > 0
                  facet_species = facets?.species || '';
                  strain_type = $.solr_config('static.ui.strain_type.%', facet_species);
                  if !strain_type
                    strain_type = 'strain';
                  name = $.solr_config('static.ui.facets.key=.text.plural',f).replace(/__strain_type__/,strain_type)
                  othervalues.push({ entries, total, name, facet: f })
            yoursearch = (k[1] for k in cur_values).join(" ")
            yoursearch = $('<div/>').text(yoursearch).html()
            wholesite = (cur_values.length == 0)
            templates = $(document).data('templates')
            el.append(templates.generate('noresultsnarrow',{
              q: query, yoursearch, othervalues, wholesite
              unrestrict_facets: () =>
                state = { page: 1 }
                for f in all_facets
                  state["facet_"+f] = ''
                $(document).trigger('update_state',[state])
                false
            }))

  searchdown:
    template: """
      <div class="scnarrow searchdown-box" style="display: none">
        <h1>Search server failed to respond</h1>
        <ul>
          <li><div><a href="#" onclick="location.reload(true); return false;">Retry this search in a few moments</a></div></li>
          <li class="mirrors"><div>Use one of our mirror sites: <span class="mirror_list"><a href="#">mirror</a> </span></li>
          <li><div><a href="/Help/Contact/">Contact us</a> if the problem persists</div></li>
        </ul>
      </div>
    """
    directives:
      '.mirrors':
        'mirrors<-mirror_list':
          '.mirror_list':
            'mirror<-mirrors':
              'a@href': 'mirror.href',
              'a': 'mirror.text'
    preproc: (spec,data) ->
      href = window.location.href
      mirrors = $.solr_config('static.ui.mirrors')
      if mirrors.length
        data.mirror_list = [
          for mirror in mirrors
            href = window.location.href.replace(/\/\/.*?\//,
                                                "//#{mirror.host}/")
            { href, text: mirror.name }
        ]
      [spec,data]

  noresultsnarrow:
    template: """
      <div class="scnarrow">
        <h1>No results for <em>thing</em> '<i class='search'>search</i>'</h1>
        <ul>
          <li class="wide"><div>
            You were searching the whole site, but still nothing was found.
          </div></li>
          <li class="narrow_rsid"><div><strong>
            You appear to have been searching for a variation rsid.
            There may be new variants which have not yet been incorporated
            into Ensembl. If this is the case, you may find information
            about this variant on the
            <a href="https://www.ncbi.nlm.nih.gov/snp"
            >NCBI website</a>
          </strong></div></li>
          <li class="narrow"><div>
            You were only searching <em>thing</em>.
          </div></li>
          <li class="narrow_any"><div>
            And there are <i class="count">42</i> results in
            <i class="all">all</i> on the whole site.
            <a href="#">Search full site</a>.
          </div></li>
          <li class='narrow_none'><div>
            But there are no results in
            any category on the whole site, anyway.
          </div></li>
          <li><div class="roll_hidden">
            <a href="#">More help on searching ...</a>
            <div class="roll_hidden_text">
            </div>
          </div></li>
        </ul>
      </div>
    """
    directives:
      'em': 'yoursearch'
      '.roll_hidden_text': 'noresults_help'
      '.search': (e) ->
        $('<div/>').text(e.context.q).html()
      '.narrow_any':
        'x<-narrow_n':
          '.all': 'all'
          '.count': 'total'
      '.narrow_none': 'y<-narrow_none': {}
      '.wide': 'w<-wide': {}
      '.narrow': 'z<-narrow':
        'em': 'yoursearch'
      '.narrow_rsid': 'y<-rsid': {}
    decorate:
      '.narrow_any a': (els,data) =>
        els.click (e) =>
          data.unrestrict_facets()
          false
      '.roll_hidden': (els,data) ->
        els.children('div').hide()
        els.children('a').on 'click', (e) =>
          els.children('div').toggle()
          false
    preproc: (spec,data) ->
      list = []
      if data.wholesite
        data.wide = [true]
      else
        data.narrow = [true]
        for ov in data.othervalues
          list.push(ov.entries+" "+ov.name)
          data.total = ov.total
        if data.othervalues.length == 0
          data.narrow_none = [true]
        else
          data.all = list.join(", ")
          data.narrow_n = [true]
      data.noresults_help = $.solr_config('static.ui.noresults_help')
      if data.q.match(/^rs(\d+)$/)
        data.rsid = [true]
      [spec,data]

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
_valueevent = (obj,ev,fn) ->
  obj.on('change keydown keypress paste cut input',{}, (e) =>
    val = ev()
    if e.data.old != val then fn(val)
    e.data.old = val
  )
_clone_object = (a) -> $.extend(true,{},a)

window.table_templates =
  # General layout of table and surroundings
  outer:
    template: """
      <div class='search_table_holder'>
        <div class='t_spinner_outer hub_spinner'>
          <div class='t_spinner'>
            <div class='t_spinner_inner'>
              <div class='t_spinner_img'></div>
            </div>
          </div>
        </div>
        <div class='t_fail_outer hub_fail'>
          <div class='t_fail'>
            <div class='t_fail_inner'>
              <div class='t_fail_img'></div>
            </div>
          </div>
        </div>
        <div class="searchdown">
        </div>
        <div class='search_table_prehead'>
          <div class="search_table_prehead_pagectl table_acc_nw">
            <div class="sizer"></div>
          </div>
          <div class="search_table_prehead_filterctl table_acc_ne">
            <div class="search_table_filter"></div>
            <div class="t_download"></div>
          </div>
          <div class="search_table_prehead_colctl table_acc_n">
            <div class="showhide"></div>
          </div>
        </div>
        <div class='page_some_query'>
          <div class='search_table_proper page_some_results'>
          </div>
        </div>
        <div class='page_no_query t_page_no_results'>Enter query &#x2197;</div>
        <div class='search_table_posttail'>
          <div class='search_table_posttail_pager table_acc_sw'>
            <div class="pager"></div>
          </div>
        </div>
        <div class='main_topcars t_main_topcars'><div class='sidecars'></div></div>
      </div>
    """
    subtemplates:
      '.sizer': { template: 'sizer', data: '' }
      '.showhide': { template: 'showhide', data: '' }
      '.t_download': { template: 'download', data: '' }
      '.pager': { template: 'pager', data: '' }
      '.search_table_filter': { template: 'filter', data: '' }
      '.searchdown': { template: 'searchdown', data: '' }
    decorate:
      '.t_page_no_query': (el,data) -> el.hide()
    postproc: (el,data) ->
      data.table_ready(el,data)
      el.on('download_curpage', (e,fn) -> data.download_curpage(el,fn))
      el.on('download_all', (e,fn) -> data.download_all(el,fn))

  # Pager
  pager:
    template: """
      <div class="table_pager"></div>
    """
    postproc: (els,data) ->
      class Pager
        constructor: (@templates,@state,@i,@n) ->
          @p = @i
          if @p < 6 then @p = 6        # Not too far to the left
          if @p > @n-4 then @p = @n-4  # Not too far to the right
          if @p < 1 then @p = 1        # But in bounds
          @added = 0
          @items = []

        add_page: (i, text) ->
          item = { text }
          if i == @i then item.disabled = 1 else item.page = i
          @items.push(item)
          item

        add_num: (i) ->
          if i <= @n
            if i > @added+1
              @items.push({ text: '...', disabled: 1, background: 1 })
            if i > @added
              item = @add_page(i,i)
              if i == @i then item.current = 1
              @added = i

        add_jump: (i,text) ->
          if i > @n then i = @n
          if i < 1  then i = 1
          @add_page(i,text)

        render: ->
          unless @n then return
          @add_jump(1,'&lt;&lt;')
          @add_jump(@i-1,'&lt;')
          @add_num(i) for i in [1..3]
          @add_num(i) for i in [@p-2..@p+2]
          @add_num(i) for i in [@n-1..@n]
          @add_jump(@i+1,'&gt;')
          @add_jump(@n,'&gt;&gt;')
          click = (i) =>
            @state.page(i)
            @state.set()
          @templates.generate('real_pager',{ @items, click })

      $(document).on 'num_known', (e,num,state,update_seq) ->
        if $(document).data('update_seq') != update_seq then return
        els.empty()
        if state.pagesize()
          pagesize = state.pagesize()
          pages = Math.floor((num + pagesize - 1) / pagesize)
          start = Math.floor((state.start() + pagesize) / pagesize)
          templates = $(document).data('templates')
          rpager = new Pager(templates,state,start,pages)
          els.append(rpager.render())
 
  real_pager:
    template: """
      <div class="solr_pager">
        <a class="solr_pager_entry" href="#">#</a>
      </div>
    """
    directives:
      '.solr_pager_entry':
        'i<-items':
          '.': 'i.text'
          '@class+': (e) ->
            for k in ['background','current','disabled']
              if e.item[k]
                return " solr_pager_entry_#{k}"
            ""
          '@href': (e) -> '#'+(e.item.page ? '')
    decorate:
      'a': (els,data) ->
        els.click (e) =>
          el = $(e.currentTarget)
          href = el.attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          p = href.substring(1)
          if p? and p then data.click(p)
          false

  # Filter: ie text entry box
  filter:
    template: """
      <div>
        <input type="text"/>
      </div>
    """
    decorate:
      'input': (els,data) ->
        els.each (i,e) =>
          el = $(e)
          _valueevent el,( => el.val()), (value) =>
            $(document).trigger('update_state',{ q: value })
          $(document).on 'state_known', (e,state,update_seq) ->
            if $(document).data('update_seq') != update_seq then return
            el.val(state.q_query())

  # Sizer, ie results per page selector 
  sizer:
    template: """
      <div class='search_table_sizer'>
        Show
        <select>
          <option>An option</option>
        </select>
        entries
      </div>
    """
    directives:
      'option':
        'size<-sizes':
          '.': (e) ->  (if e.item then e.item else '&#8734;')
          '@value': 'size'
    decorate:
      'select': (els,data) ->
        els.change (e) ->
          el = $(e.currentTarget).parents().andSelf().find('select')
          $(document).trigger('ga', ['SrchPerPage', 'Table', el.val()]);
          $(document).trigger('update_state',{ perpage: el.val(), page: 1 })
        $(document).on 'state_known', (e,state,update_seq) ->
          if $(document).data('update_seq') != update_seq then return
          els.val(state.e().data('pagesize'))
    preproc: (spec,data) ->
      data.sizes = $.solr_config('static.ui.pagesizes')
      [spec,data]

  # Showhide, ie Columns to show/hide 
  showhide:
    template: """
      <div class="search_table_showhide">
        <div class="search_table_showhide_toggle">Show/hide columns</div>
        <ul class="search_table_showhide_list">
          <li>
            <input type="checkbox"/>
            <span>Column</span>
          </li>
        </ul>
      </div>
    """
    directives:
      'li':
        'col<-columns':
          'span': 'col.name'
          '@data-key': 'col.key'
    decorate:
      'ul': (els,data) ->
        $(document).on 'state_known', (e,state,update_seq) ->
          if $(document).data('update_seq') != update_seq then return
          onoff = {}
          (onoff[k] = 1) for k in state.e().data('columns')
          $('li',@).each ->
            m = $(@)
            if onoff[m.data('key')]
              $('input',m).attr('checked','checked')
            else
              $('input',m).removeAttr('checked')
      '.search_table_showhide_toggle': (els,data) ->
        list = els.parent().find('.search_table_showhide_list')
        els.click( (e) => list.toggle() )
        list.hide()
      'input': (els,data) ->
        els.change (e) ->
          cols = {}
          $(@).closest('ul').find('li').each () ->
            key = $(@).data('key')
            if $('input',$(@))[0].checked then cols[key] = 1
          new_cols = []
          for k in $.solr_config('static.ui.all_columns')
            if cols[k.key] then new_cols.push(k.key)
          $(document).trigger('update_state',{ columns: new_cols.join('*') })
          true
    preproc: (spec,data) ->
      data.columns = $.solr_config('static.ui.all_columns')
      [spec,data]

  # CSV
  # XXX impl depends on EnsEMBL.
  download:
    template: """
      <div>
        <div class='t_download_click'>
          <div class="t_download_popup">
            <a href="#curpage">Download what you see</a>
            <a href="#all">Download whole table (max <i>0</i>)</a>
          </div>
        </div>
        <form class="t_download_export" action="/Ajax/table_export" method="post" style="display: none">
          <input type="hidden" class="filename" name="filename" value="output.csv" />
          <input type="hidden" class="expopts" name="expopts" value="{}" />
          <input type="hidden" class="data" name="data" value="" />
      </form>
      </div>
    """
    directives:
      'i': 'limit'
    decorate:
      '.t_download_click': (els,data) ->
        els.click (e) ->
          $('.t_download_popup',@).toggle()
      '.t_download_popup': (els,data) -> els.hide()
      ".t_download_popup a[href='#curpage']": (els,data) ->
        els.click (e) =>
          $(document).trigger('ga', ['SearchPageResults', 'TableExport', 'download_curpage']);
          els.closest('.search_table_holder').trigger('download_curpage',[data.filename])
          els.parents('.t_download_popup').hide()
          false
      ".t_download_popup a[href='#all']": (els,data) ->
        els.click (e) =>
          $(document).trigger('ga', ['SearchPageResults', 'TableExport', 'download_all']);
          els.closest('.search_table_holder').trigger('download_all',[data.filename])
          els.parents('.t_download_popup').hide()
          false
    preproc: (spec,data) ->
      data.limit = $.solr_config('static.ui.downloadmaxrows')
      data.filename = $.solr_config('static.ui.downloadfilename')
      [spec,data]

  # Chunk, ie a quantity of real table 
  chunk:
    template: """
      <table style="width: 100%; table-layout: fixed">
        <thead>
          <tr><th><span>col</span><div></div></th></tr>
        </thead>
        <tbody>
          <tr><td>data</td></tr>
        </tbody>
      </table>
    """
    directives:
      'thead':
        'head<-table_thead':
          'th':
            'col<-head':
              'span': 'col.text'
              '@style': 'col.width'
              'div@class+': (e) ->
                state = e.item.state
                if state
                  " search_table_sorter search_table_sorter_#{state}"
                else
                  ""
              'div@data-key': 'col.key'
              'div@data-dir': 'col.dir'
      'tbody tr':
        'row<-table_row':
          '@class': 'row.klass'
          'td':
            'col<-row.table_col':
              '.': 'col.data'
              '@style': 'col.width'
    preproc: (spec,data) ->
      data = _clone_object(data)
      data.table_row = data.rows
      if data.first
        head = []
        head.push(data.headings[c]) for c in data.cols
        c.width = "width: #{data.widths[i]}%" for c,i in head
        data.table_thead = [ head ]
      else
        data.widths[i] = "width: #{data.widths[i]}%" for c,i in data.cols
        data.table_thead = []
      [spec,data]
    # XXX makes non-portable
    # XXX cleaner intra-column formatting
    more_fixes: ['page','fix_g_variation','fix_regulation','fix_terse','fix_minor_types']
    postproc: (el,data) ->
      $('td a',el).click ->
        $(document).trigger('ga',['SrchMainLink','table',$(this).text()])
    fixes:
      global: [
        (data) -> # Merge id_with_url back in
          data.tp2_row.register 2000, () ->
            url = data.tp2_row.best('url')
            id = data.tp2_row.best('id')
            id_with_url = "<a href='#{url}'>#{id}</a>"
            data.tp2_row.candidate('id_with_url',id_with_url,300)

          data.tp2_row.register 30000, () ->
            data.tp2_row.send('id_with_url',data.tp2_row.best('id_with_url'))
          # THESE WOULD APPLY TO ANY TABLE
          data.tp2.register 10000, () ->
            row_data = []
            table_row = data.tp2.best('table_row')
            cols = data.tp2.best('cols')
            for r,i in table_row
              row = { klass: r.klass, table_col: [] }
              for c,j in cols
                cv = { data: r.cols[c] ? '' }
                if !i then cv.width = data.widths[j]
                row.table_col.push cv
              row_data.push(row)
            data.tp2.candidate('table_row',row_data,1000)

          data.tp2.register 100000, () ->
            data.tp2.send('table_row',data.tp2.best('table_row'))

          true
      ]
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

sequence_type =
  'contig': 'Contig'
  'clone': 'Clone'
  'chromosome': 'Chromosome'
  'lrg': 'LRG'

window.fixes ?= {}
window.fixes.fix_minor_types =
  fixes:
    global: [
      (data) -> # Extract good info from description
        data.tp2_row.register 1000, () ->
          ft = data.tp2_row.best('feature_type')
          sp = data.tp2_row.best('species')
          if ft == 'Phenotype'
            data.tp2_row.candidate('id',sp+' Phenotype',1000)

        data.tp2_row.register 25000, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'Protein Domain'
            sp = data.tp2_row.best('species')
            data.tp2_row.candidate('bracketed',ft+' in '+sp,10000)

        data.tp2_row.register 26000, () ->
          strain = data.tp2_row.best('strain')
          if strain?
            sp = data.tp2_row.best('species')
            br = data.tp2_row.best('bracketed')
            strain = strain.replace(/_/g,' ')
            strain = strain.replace(new RegExp('^'+sp+' '),'')
            
            strain_type = $.solr_config('static.ui.strain_type.%', sp);
            if !strain_type
              strain_type = 'Strain';
            strain_type = strain_type.charAt(0).toUpperCase() + strain_type.substring(1)
            data.tp2_row.candidate('bracketed',br+', '+strain_type+': '+strain,15000)

        data.tp2_row.register 300, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'Family'
            inner_desc = undefined
            main_desc = data.tp2_row.best('description')
            main_desc = main_desc.replace /\[(.*?)\]/g, (g0,g1) ->
              inner_desc = $.trim(g1)
              ''
            main_desc = $.trim(main_desc.replace(/has$/,''))
            data.tp2_row.candidate('domfam_inner_desc',inner_desc,1000)
            data.tp2_row.candidate('domfam_rem_desc',main_desc,1000)
          if ft == 'Family'
            data.tp2_row.candidate('title_feature_type','Protein Family',300)
          if ft == 'Marker'
            id = data.tp2_row.best('id')
            data.tp2_row.add_value('new-contents',"Marker "+id,300)
            data.tp2_row.add_value('new-contents',data.tp2_row.best('description'),1000)
          if ft == 'Sequence'
            id = data.tp2_row.best('id')
            desc = data.tp2_row.best('description')
            if id.match(/^LRG_/)
              data.tp2_row.add_value('new-contents',"<i>LRG sequence (Locus Reference Genomic)</i>",1000)
              data.tp2_row.add_value('new-contents',data.tp2_row.best('description'),100)
            for k,v of sequence_type
              if desc.toLowerCase().substring(0,k.length) == k
                data.tp2_row.add_value('bracketed-title',v,295)
          if ft == 'GenomicAlignment'
            desc = data.tp2_row.best('description')
            if desc.match(/ESTs?/)
              data.tp2_row.candidate('title_feature_type','EST',300)
            else
              data.tp2_row.candidate('title_feature_type','Genomic Alignment',150)
          if ft == 'ProbeFeature'
            type = ['Probe']
            desc = data.tp2_row.best('description')
            m = desc.match /^([A-Z]+) probe/
            if m?[0]? then type.unshift(m[1])
            data.tp2_row.candidate('title_feature_type',type.join(' '),300)

        data.tp2_row.register 1000, () ->
          prefix_contents = undefined
          ft = data.tp2_row.best('feature_type')
          rem = data.tp2_row.best('domfam_rem_desc')
          inner = data.tp2_row.best('domfam_inner_desc')
          main = undefined
          if ft == 'Protein Domain'
            main = inner
            prefix_contents = [rem,inner]
          else if ft == 'Family'
            main = 'Protein Family ' + data.tp2_row.best('id')
            prefix_contents = [main,inner]
          if prefix_contents?
            # XXX use existing contents
            for p,idx in prefix_contents
              if p?.match /\w/
                data.tp2_row.add_value('new-contents',p,100*idx+100)
          if main? then data.tp2_row.candidate('main-title',main,300)

        true
    ]

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

title_reword =
  'cisRED motifs': 'cisRED'
  'cisRED search regions': 'cisRED'
  'VISTA enhancer set': 'VISTA'
  'miRanda miRNA targets': 'miRanda'

expand_for_desc =
  'VISTA': 'the VISTA enhancer set'
  'miRanda': 'the miRanda miRNA target predictions'

expand_for_title =
  'RNA': 'miRNA'
  'Search Region': 'Search region'

feature_type =
  'Regulatory Motif': 'Feature'

format =
  _default: "{reg_id} is [${reg_what_desc}$] from {reg_from_desc} {reg_tail}"
  miranda: "{reg_id} is a miRanda miRNA target prediction {reg_tail}"
  cisred: "{reg_id} is [{reg_from_desc}] <{reg_what_desc}> {reg_tail}"

_a = (word) ->
  a_an = ('aeiouAEIOU'.indexOf(word.charAt(0)) != -1 or
          $.inArray(word.toLowerCase(),['rna']) != -1)
  return ( if a_an then 'an ' else 'a ' ) + word

_lc = (word) ->
  w = word.toLowerCase()
  if $.inArray(w,['rna']) != -1
    word.toUpperCase()
  else
    w

window.fixes ?= {}
window.fixes.fix_regulation =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 150, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'RegulatoryFeature'
            desc = data.tp2_row.best('description')
            m = desc.match(/^(\S+) is a (.*?) from (.*?) (which hits .*)$/)
            if m?
              [reg_id,reg_what,reg_from,reg_tail] = m[1..4]
              for from,to of title_reword
                if reg_what == from then reg_what = to
                if reg_from == from then reg_from = to
              data.tp2_row.candidate('reg_id',  reg_id,50)
              data.tp2_row.candidate('reg_what',reg_what,50)
              data.tp2_row.candidate('reg_from',reg_from,50)
              data.tp2_row.candidate('reg_tail',reg_tail,50)
          true

        data.tp2_row.register 300, () ->
          reg_what = data.tp2_row.best('reg_what')
          reg_from = data.tp2_row.best('reg_from')
          for match,name of feature_type
            if reg_what == match or reg_from == match
              data.tp2_row.candidate('title_feature_type',name,100)
          if data.tp2_row.best('feature_type') == 'RegulatoryFeature'
            data.tp2_row.candidate('title_feature_type','Regulatory Feature',80)
          true

        data.tp2_row.register 1000, () ->
          reg_what = data.tp2_row.best('reg_what')
          reg_from = data.tp2_row.best('reg_from')
          if reg_from
            from = expand_for_title[reg_from] ? reg_from
            data.tp2_row.add_value('bracketed-title',from,260)
          if reg_what
            what = expand_for_title[reg_what] ? reg_what
            data.tp2_row.add_value('bracketed-title',what,280)
          #
          for from, to of expand_for_desc
            if reg_what == from then reg_what = to
            if reg_from == from then reg_from = to
          data.tp2_row.candidate('reg_what_desc',reg_what,100)
          data.tp2_row.candidate('reg_from_desc',reg_from,100)
          true

        data.tp2_row.register 2000, () -> 
          reg_from = data.tp2_row.best('reg_from')
          if not reg_from then return
          c = (format[reg_from.toLowerCase()]  ? format._default)
            .replace(/\{(.*?)\}/g,((g0,g1) -> data.tp2_row.best(g1)))
            .replace(/\$(.*?)\$/g,((g0,g1) -> _lc(g1)))
            .replace(/\[(.*?)\]/g,((g0,g1) -> _a(g1)))
          data.tp2_row.add_value('new-contents',c,100)
          data.tp2_row.candidate('description','',500)
          true
    ] 

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

verbose =
  Documentation:
    id: '{subtype} #'
    title: '{article_title}'

_make_string = (r,template) ->
  failed = false 
  out = template.replace /\{(.*?)\}/g,(g0,g1) ->
    v = r.best(g1)
    if not v? then failed = true
    return v
  if failed then return undefined
  return out

window.fixes ?= {}
window.fixes.fix_terse =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 100, () -> # Subtypes for doucmentation
          url = data.tp2_row.best('domain_url')
          url = url.replace(/https?:\/\/.*?\//,'/')
          if url != '' and url[0] != '/'
            url = '/' + url
          data.tp2_row.candidate('url',url,500)
          ft = data.tp2_row.best('feature_type')
          if url
            data.tp2_row.candidate('subtype','ID',10)
            m = url.match /Help\/([a-zA-z]+)/
            if m?
              data.tp2_row.candidate('subtype',m[1],100)

        data.tp2_row.register 150, () -> # Better IDs for doucmentation
          if data.tp2_row.best('feature_type') == 'Documentation'
            data.tp2_row.candidate('id',data.tp2_row.best('url'),100)

        data.tp2_row.register 300, () -> # Overly terse titles
          ft = data.tp2_row.best('feature_type')
          v = verbose[ft]
          if v?.title?
            t = data.tp2_row.best('main-title')
            title = _make_string(data.tp2_row,v.title)
            data.tp2_row.candidate('main-title',title,300)
          if v?.id?
            id = data.tp2_row.best('id')
            id = _make_string(data.tp2_row,v.id) + id
            data.tp2_row.candidate('id',id,300)
        true
    ]

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

_list_string = (singular,plural,data,tail,flip,wrap) ->
  head = (if data.length > 1 then plural else singular)
  tail ?= ''
  wrap ?= ''
  if not $.isArray(wrap) then wrap = [wrap,wrap]
  if flip then [head,tail] = [tail,head]
  data = ( wrap[0]+d+wrap[1] for d in data )
  if data.length == 0 then return ''
  if data.length == 1 then return $.trim([head,data[0],tail].join(' '))
  end = data.pop()
  return $.trim([head,(data.join(', ')),'and',end,tail].join(' '))

title_type = {
  CNV: 'CNV Probe'
  DGVa: 'DGVa'
}

window.fixes ?= {}
window.fixes.fix_g_variation =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 100, () ->
          ft = data.tp2_row.best('feature_type')
          if $.inArray(ft,["Variation","Somatic Mutation"]) != -1
            desc = data.tp2_row.best('description')
            extract = (re,key) ->
              out = undefined
              desc = desc.replace(re,((g0,g1) => out = g1 ; ''))
              out
            source = extract(/A (.*?) (Variation|Somatic Mutation)\. /)
            phenotypes = extract(/Phenotype\(s\): (.*?)\./)
            genes = extract(/Gene Association\(s\): (.*?)\./)
            if phenotypes?
              for p,i in phenotypes.split(';') 
                data.tp2_row.add_value('v-phenotypes-raw',p,i*100+500)
            if genes?
              for g,i in genes.split(',')
                data.tp2_row.add_value('v-genes',g,i*100+500)
            if desc.match /\w/
              data.tp2_row.add_value('new-contents',desc,100)
              data.tp2_row.candidate('description','',900)
            data.tp2_row.candidate('v-source',source,100)
          else if ft == 'Phenotype'
            desc = data.tp2_row.best('description')
            name = data.tp2_row.best('name')
            title = desc?.replace(/\.$/,'')
            title ?= name.toLowerCase()
            data.tp2_row.candidate('main-title',title,200)
          else if ft == 'StructuralVariation'
            data.tp2_row.candidate('title_feature_type','Structural Variation',200)
            desc = data.tp2_row.best('description')
            re = /A structural variation from (.*?)\, identified by (.*)$/
            m = desc.match(re)
            if m?
              data.tp2_row.candidate('sv-source',m[1],100)
              n = m[2].replace(/\(study (.*)\)/,'')
              if n?
                data.tp2_row.candidate('sv-study',n[1],100)
              data.tp2_row.candidate('sv-method',m[2],100)
              type = undefined
              for pattern,t of title_type
                if m[1].indexOf(pattern) != -1
                  type = t
              if type then data.tp2_row.add_value('bracketed-title',type,290)

        # Standardise phenotypes
        data.tp2_row.register 500, () ->
          vpr = data.tp2_row.all_values('v-phenotypes-raw')
          if not vpr then return
          vpr = ( k.value for k in vpr.sort((a,b) -> a.position - b.position) )
          cosmic = {}
          forms = {}
          for p in vpr
            m = p.match(/(COSMIC):(tumour_site):(.*)/)
            if m?
              cosmic[m[2]] ?= []
              cosmic[m[2]].push(m[3])
            else if p.match(/HGMD_MUTATION/)
              data.tp2_row.add_value('new-contents', "<i>Annotated by HGMD but no phenotype description is publicly available (HGMD_MUTATION)</i>",5000)
            else
              # Neither COSMIC nor HGMD_MUTATION
              parts = ($.trim(x) for x in p.toLowerCase().split(','))
              std = parts.sort((a,b) -> a.localeCompare(b)).join(' ')
                .replace(/\s+/g,' ')
              if (not forms[std]?) or forms[std][1] > parts.length
                forms[std] = [p,parts.length]
          vp = ( v[0] for k,v of forms )
          for p,i in vp
            if p.toUpperCase() == p
              vp[i] = p.charAt(0)+p.substring(1).toLowerCase()
          data.tp2_row.add_value('v-phenotypes',p,200+i) for p in vp
          i = 0
          for ctype,csites of cosmic
            type = ctype.replace(/_/g,' ')
            i += 1
            str = "Associated with COSMIC "+
              _list_string(type,type+"s",csites,'',false,'"')
            data.tp2_row.add_value('new-contents',str,4000+i)
        
        data.tp2_row.register 1000, () ->
          # Source
          vs = data.tp2_row.best('v-source')
          if vs
            vs = vs.replace(/_/g,' ')
            data.tp2_row.add_value('bracketed-title',vs,255)
          # Description
          assocs = []
          vp = data.tp2_row.all_values('v-phenotypes')
          if vp
            vp = ( k.value for k in vp.sort((a,b) -> a.position - b.position))
            assocs.push(_list_string("phenotype","phenotypes",vp,'',true,'"'))
          vg = data.tp2_row.all_values('v-genes')
          if vg and vg.length
            vg = ( k.value for k in vg.sort((a,b) -> a.position - b.position))
            assocs.push(_list_string("gene","genes",vg))
          if assocs.length
            data.tp2_row.add_value('new-contents',"Associated with "+assocs.join(' and '),10)
        true 
    ] 

