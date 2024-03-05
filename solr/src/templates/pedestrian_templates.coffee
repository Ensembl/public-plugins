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

