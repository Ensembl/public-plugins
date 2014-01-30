#
_clone_array = (a) -> $.extend(true,[],a)

# XXX clear footer

class Source
  init: (cols) ->
    @cols = $.extend(true,[],cols)
    @colidx = []
    @colidx[@cols[i].key] = i for i in [0..@cols.length-1]

  columns: -> @cols

# XXX lowercase filter
# XXX non-string comparison
# XXX internal sort, filter etc
# XXX delay search
# XXX general ephemora

class TableState
  constructor: (@source,el) ->
    scols = @source.columns()
    @_filter = []
    @_order = []
    @_colkey = {}
    @_colkey[c.key] = c for c in scols
    @_sortkey = {}
    @el = $(el)
    @el.data('columns',c.key for c in scols)
    @el.data('pagesize',10)
    @el.on 'fix_widths', () =>
      # convert widths to percentages
      columns = @el.data('columns')
      @_colkey[c].width = 1 for c in columns when @_colkey[c].width == 0
      units_used = 0
      units_used += @_colkey[c].width for c in columns
      perc_per_unit = 100 / units_used
      total = 0
      for c in columns
        @_colkey[c].total = @_colkey[c].width*perc_per_unit + total
        total += @_colkey[c].width*perc_per_unit
        @_colkey[c].percent = 0
      col = 0
      for i in [0..99]
        if i > @_colkey[columns[col]].total and col < columns.length then col++
        @_colkey[columns[col]].percent++
  
  e: -> @el

  _update_sortkey: ->
    @_sortkey = {}
    for r in @_order
      @_sortkey[r.column] = r.order

  filter: (f) -> (if f? then @_filter = f); @_filter
  columns: () -> @el.data('columns')
  order: (r) -> 
    if r?
      @_order = r
      @_update_sortkey()
    @_order
  page: (p) -> (if p? then @el.data('page',p)); @el.data('page') ? 1
  pagesize: () -> @el.data('pagesize')
  start: -> (@page()-1)*@pagesize()
  coldata: -> (@_colkey[k] for k in @el.data('columns'))
  sortkey: (k) -> @_sortkey[k]
  associate: (@table) ->
  set: -> @table.render()


class TableHolder
  constructor: (@templates,@source,@state,@options = {}) ->
    @state.associate(@)

  # Used for download links
  get_all_data: (callback) ->
    out = { rows: [] }
    @get_some_data(0,100,out,callback)

  get_some_data: (start,num,acc,callback) ->
    @get_data start,num, (data) =>
      if data.rows.length == 0 or (@max? and start+data.rows.length > @max)
        callback(acc)
      else
        if data.cols? and not acc.cols? then acc.cols = data.cols
        acc.rows = acc.rows.concat(data.rows)
        @get_some_data(start+data.rows.length,num,acc,callback)

  get_data: (start,num,callback) ->
    @source.get(@state.filter(),@state.columns(),@state.order(),
                start,num,callback,true)

  # XXX abstract better
  transmit_data: (el,fn,data) ->
      rows = []
      rows.push(data.cols)
      for r in data.rows
        row = []
        for c in data.cols
          if c == 'id_with_url' # XXX ugly! Not General!
            r[c] = r['id']
          row.push(r[c])
        rows.push(row)
      $form = $('.t_download_export',el)
      $('.filename',$form).val(fn)
      $('.data',$form).val(JSON.stringify(rows))
      $('.expopts',$form).val(JSON.stringify({} for c in data.cols))
      $form.trigger('submit')
  # END used for download links

  generate_model: (extra) ->
    model = {
      table_ready: (el,data) => @collect_view_model(el,data)
      state: @state
      download_curpage: (el,fn) =>
        @get_data(@state.start(),@state.pagesize(), (data) =>
          @transmit_data(el,fn,data)
        )
      download_all: (el,fn) =>
        @get_all_data((data) => @transmit_data(el,fn,data))
    }
    model

  collect_view_model: (el,data) ->
    @outer = el

  element: -> @outer

  draw_table: ->
    table = new Table(@)
    table.render() 

  table_ready: (html) ->
    table = $('.search_table_proper',@outer)
    table.empty()
    table.append(html)

  data_actions: (data) ->
    if @options.update?
      @options.update.call(@,data)

class Table
  _idx = 0

  new_idx: -> @idx = _idx++

  constructor: (@holder) ->
    @multisort = (@holder.options.multisort ? true)
    @last_scroll_fire = 0
    @artificial_seq = 1
    $(window).scroll( => @scroll_event(0) )

  scroll_event: (artificial) ->
    now = new Date().getTime()
    if artificial != 0 and @artificial_seq != artificial then return
    if now > @last_scroll_fire + 500
      @last_scroll_fire = now
      @did_scroll()
    else
      if artificial == 0
        if @timer then clearTimeout(@timer)
        @timer = setTimeout(( => @scroll_event(++@artificial_seq)),500)

  did_scroll: ->
    @reinstate_chunks()

  reinstate_chunks: ->
    top = $(window).scrollTop()
    height = $(window).height()
    start = top - height
    end = top + 2 * height
    table = @
    count = 0
    targets = []
    $('.search_table_buffer').each( ->
      buffer = $(@)
      buffer_start = buffer.offset().top
      buffer_end = buffer_start + buffer.height()
      unless buffer_start > end or buffer_end < start
        targets.push(buffer)
    )
    if targets.length
      table.reinstate_chunk targets,0, =>
        if targets.length
          @reinstate_chunks()

  render_head: (t_data,data,first) ->
    t_data.headings = {}
    for c in @holder.state.coldata()
      state = 'off'
      dir = @holder.state.sortkey(c.key)
      if dir? then state = (if dir>0 then "asc" else "desc")
      if c.nosort then state = ''
      t_data.headings[c.key] = { text: c?.name, state, key: c.key, dir}
    t_data.first = first

  render_tail: (table,data) ->

  render_row: (data) ->
    @stripe = !@stripe
    { cols: data, stripe: @stripe }

# XXX lru table
# XXX if top not moved then body not moved

  reinstate_chunk: (targets,i,rest) ->
    buffer = targets[i]
    start = buffer.data('start')
    num = buffer.data('num')
    idx = buffer.data('idx')
    first = buffer.data('first')
    last = buffer.data('last')
    @get_data start,num, (data) =>
      if idx != @idx then return
      @render_chunk(data,first,last,false,buffer, (table) =>
        if i < targets.length-1
          @reinstate_chunk(targets,i+1,rest)
        else
          rest()
      )

  fake_chunk: (height,start,num,idx,first,last) ->
    $('<div/>')
      .addClass('search_table_buffer')
      .height(height)
      .data('start',start)
      .data('num',num)
      .data('idx',idx)
      .data('first',first)
      .data('last',last)

  hide_chunk: (table,height,start,num,idx,first,last) ->
    table.replaceWith(@fake_chunk(height,start,num,idx,first,last))

  hide_distant_chunks: ->
    top = $(window).scrollTop()
    height = $(window).height()
    start = top - height
    end = top + 2 * height
    distant = []
    @container.find('.chunk').each( ->
      table = $(@)
      table_start = table.offset().top
      table_end = table_start + table.height()
      if table_start > end or table_end < start
        height = table.outerHeight(true)
        start = table.data('start')
        num = table.data('num')
        idx = table.data('idx')
        first = table.data('first')
        last = table.data('last')
        distant.push([table,height,start,num,idx,first,last])
    )
    @hide_chunk(t[0],t[1],t[2],t[3],t[4],t[5],t[6]) for t in distant

  markup_chunk: (table,start,num,idx,first,last) ->
    table.data('start',start).data('num',num).data('idx',idx).data('first',first).data('last',last)

  render_data: (data,first,last) ->
    t_data = { table_row: [], rows: [], cols: data.cols }
    widths = (c.percent for c in @holder.state.coldata())
    t_data.widths = widths
    @render_head(t_data,data,first)
    for r in data.rows
      t_data.rows.push(@render_row(r))
    if last then @render_tail(t_data,data)
    t_main = @holder.templates.generate('chunk',t_data)
    # Bind events
    table = @
    $('.search_table_sorter',t_main).on 'click', (e) ->
      order = []
      key = $(@).data('key')
      dir = $(@).data('dir')
      if e.shiftKey and table.multisort
        order.push(e) for e in @holder.state.order() when e.column != key
      order.push { column: key, order: (if dir>0 then -1 else 1) }
      table.holder.state.order order
      table.holder.state.set()
      false
    t_main

  render_chunk: (data,first,last,fire,replace,next) ->
    if first and fire then @holder.data_actions(data)
    outer = @render_data(data,first,last)
    if replace?
      replace.replaceWith(outer)
    else
      outer.appendTo(@container)
    if first and fire then @holder.table_ready(@container)
    next.call(@,outer)

  average_chunk_height: ->
    height = 0
    num = 0
    @container.find('.chunk').each ->
      height += $(@).outerHeight(true)
      num++
    if num == 0 then num = 1
    height / num

# XXX calculate actual effective size not 1000000 in case smaller
# XXX giant clear sidebar

  get_page: (page,start,got,chunk,idx,getter,iter = 0) ->
    toget = (if page then page - got else chunk)
    if toget > chunk then toget = chunk
    getter.call @, start+got, toget, (data) =>
      if idx != @idx then return # usurped!
      if data.fake?
        more = !!(data.fake_length)
        fake = @fake_chunk(data.fake_height,start+got,toget,idx,got==0,!more)
        got_here = data.fake_length
        fake.appendTo(@container)
        if more
          @get_page(page,start,got+got_here,chunk,idx,getter,iter+1)
      else
        more = !!((got+data.rows.length < page or page == 0) and data.rows.length )
        @render_chunk data,got==0,!more,true,undefined, (table) =>
          @markup_chunk(table,start+got,toget,idx,got==0,!more)
          got_here = data.rows.length
          setTimeout(( => @hide_distant_chunks()),0)
          if iter == 10 # XXX sensible criterion
            avg = @average_chunk_height()
            getter = @fake_data(data.num,avg)
          if more
            @get_page(page,start,got+got_here,chunk,idx,getter,iter+1)

  render_main: (idx) ->
    @stripe = 1
    got = 0
    start = @holder.state.start()
    page = @holder.state.pagesize()
    chunk = @holder.source.chunk_size()
    @get_page(@holder.state.pagesize(),@holder.state.start(),0,@holder.source.chunk_size(),idx,@get_data)

# XXX only deform on giant tables
# XXX reorderable cols
# XXX stripes and hidden chunks
# XXX odd page sizes

  get_data: (start,num,more) ->
    @holder.source.get(@holder.state.filter(),@holder.state.columns(),@holder.state.order(),start,num,more)

  fake_data: (total,height) ->
    (start,num,more) =>
      setTimeout( =>
        if start+num > total then num = total-start
        if num < 0 then num = 0
        more({ docs: [], num: total, fake: true, fake_length: num, fake_height: height })
      ,0) # Avoid crowding out user interaction

  render: ->
    if @container? then @container.remove()
    @new_idx()
    @container = $('<div/>').addClass('search_table')
    @render_main(@idx)

# XXX periodic headers

window.TableSource = Source
window.TableState = TableState 
window.search_table = TableHolder

