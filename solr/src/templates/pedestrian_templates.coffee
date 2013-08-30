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
      for f in $.solr_config("static.ui.facets")
        if data.values[f.key]?
          rows.push {
            href: "#"+f.key
            left: "&lt; all " + ucfirst($.solr_config("static.ui.facets.key=.text.plural",f.key))
            right: "Only searching " + ($.solr_config("static.ui.facets.key=.members.key=.text.plural",f.key,data.values[f.key]) ? data.values[f.key])
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
          state['facet_'+href.substring(1)] = ''
          $(document).trigger('update_state',[state])
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
          false
      '.solr_beak_p_less a': (els,data) ->
        els.click () ->
          state = {}
          state["fall_"+data.key] = ''
          $(document).trigger('update_state',[state])
          false
    preproc: (spec,data) ->
      data.entries = []
      data.order.reverse()
      for i in[0..data.values.length/2-1] by 1
        name = data.values[i*2]
        rename = $.solr_config("static.ui.facets.key=.members.key=.text.singular",data.key,name)
        if rename? then name = rename
        data.entries.push {
          key: data.values[i*2]
          name
          num: data.values[i*2+1]
          order: $.inArray(data.values[i*2],data.order)
        }
      data.entries = data.entries.sort((a,b) -> b.order - a.order)
      short_num = $.solr_config('static.ui.facets.key=.trunc',data.key)
      title = $.solr_config('static.ui.facets.key=.heading',data.key)
      data.title = ( if data.entries.length then [title] else [] )
      for e in data.entries
        e.klass = ' solr_menu_class_'+(data.key)+'_'+e.name
      data.more_text = $.solr_config("static.ui.facets.key=.more",data.key)
      data.less_text = $.solr_config("static.ui.facets.key=.less",data.key)
      data.more_text = data.more_text.replace(/\#\#/,data.entries.length-short_num)
      [spec,data]
    postproc: (el,data) ->
      $(el).on 'trim', (e,num) ->
        links = $('.solr_beak_p_contents a',el)
        $('.solr_beak_p_less',el).hide()
        $('.solr_beak_p_more',el).hide()
        if num != 0
          # trim
          links.css('display','block').each (i) ->
            if i >= num then $(@).hide()
          if links.length > num
            $('.solr_beak_p_more',el).css('display','block')
        else
          # untrim
          links.css('display','block')
          $('.solr_beak_p_less',el).css('display','block')

      data.set_fn = (v) =>
        $('.solr_feet_p_current',el).removeClass('solr_feet_p_current')
        if v
          $("a[href='##{v}']",el).addClass('solr_feet_p_current')
     
      $(document).on 'state_change', (e,params) ->
        short_num = $.solr_config('static.ui.facets.key=.trunc',data.key)
        sense = params["fall_"+data.key]
        el.trigger('trim',[if sense then 0 else short_num])
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
        <div class='solr_beak_p_contents'>
          <a>
            <span class='solr_beak_p_left'>42</span>
            <span class='solr_beak_p_right'></span>
          </a>
        </div>
      </div>
    """
    directives:
      'a':
        'entry<-entries':
          'span.solr_beak_p_left': 'entry.label'
          '@href': (e) -> '#'+e.item.key
    decorate:
      'a': (els,data) ->
        els.click (e) =>
          href = $(e.currentTarget).attr('href')
          href = href.substring(href.indexOf('#')) # IE7, :-(
          $(document).trigger('update_state',{ perpage: href.substring(1) })
          false
    preproc: (spec,data) ->
      data.entries = []
      for x in $.solr_config("static.ui.pagesizes")
        data.entries.push({ label: (if x then x else "all"), key: x})
      [spec,data]
    postproc: (el,data) ->
      $(document).on 'first_result', (e,query,data,state) ->
        $('.solr_feet_p_current',el).removeClass('solr_feet_p_current')
        pp = state.pagesize()
        $("a[href='##{pp}']",el).addClass('solr_feet_p_current')

