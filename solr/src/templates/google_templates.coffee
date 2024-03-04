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

