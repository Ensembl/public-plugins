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
