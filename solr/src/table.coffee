# The table code exports three classes.
#
# TableHolder -- the main class, one per table implemented here.
#
# TableState  -- you subclass this and override methods and then supply it.
#                  Contains callbacks whereby this code can record state
#                  changes, eg column ordering, filtering, etc. and methods
#                  to retrieve that info. Usually your implementation will
#                  put these things in URLs, etc.
#
#                  There is a getter/setter method in the superclass for
#                  each piece of state, which you should leave alone.
#                  Subclasses just override set() which should pull info
#                  from these getters and then call their persistence layer.
#
# TableSource -- you subclass this and override methods and then supply it.
#                  Contains callbacks which the table code uses to retrieve
#                  table contents. Typically this will trigger AJAX calls
#                  or suchlike. When the data is returned, methods in this
#                  class are called by you to populate the table.
#
#                  You only need implement two methods, columns, which
#                  contains a list of columns and get to get the data.
#                  A default implementation of columns is provided which is
#                  usually fine and is initialised by a call to init in
#                  your constructor.

_clone_array = (a) -> $.extend(true,[],a)

# XXX clear footer

class Source

# XXX lowercase filter
# XXX non-string comparison
# XXX internal sort, filter etc
# XXX delay search
# XXX general ephemora

class TableState
  constructor: (el,scols) ->
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

class TableHolder
  constructor: (@templates,@source,@state,@options = {}) ->
    @state.associate(@)
    if not @options.chunk_size? then @options.chunk_size = 1000

  # Used for download links
  get_all_data: () ->
    num = 100
    chunk_loop = (window.then_loop ([acc,start,halt]) =>
      console.log(acc,start,halt)
      if halt then return acc
      else
        return @get_data(start,num).then (data) =>
          if data.cols? and not acc.cols? then acc.cols = data.cols
          if data.rows.length == 0 or (@max? and start+data.rows.length > @max)
            halt = 1
          acc.rows = acc.rows.concat(data.rows)
          return [acc,start+data.rows.length,halt]
    )
    return $.Deferred().resolve([{ rows: [] },0,0]).then(chunk_loop)

  get_data: (start,num) ->
    return @source.get(@state.filter(),@state.columns(),@state.order(),
                       start,num,true)

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
    return {
      table_ready: (el,data) => @collect_view_model(el,data)
      state: @state
      download_curpage: (el,fn) =>
        @get_data(@state.start(),@state.pagesize()).done((data) =>
          @transmit_data(el,fn,data)
        )
      download_all: (el,fn) =>
        @get_all_data().done((data) => @transmit_data(el,fn,data))
    }

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
      @options.update(@,data)

class Table
  _idx = 0

  new_idx: -> @idx = _idx++

  constructor: (@holder) ->
    @multisort = (@holder.options.multisort ? true)

  render_head: (t_data,data,first) ->
    t_data.headings = {}
    for c in @holder.state.coldata()
      state = 'off'
      dir = @holder.state.sortkey(c.key)
      if dir? then state = (if dir>0 then "asc" else "desc")
      if c.nosort then state = ''
      t_data.headings[c.key] = { text: c?.name, state, key: c.key, dir}
    t_data.first = first


  render_row: (data) ->
    @stripe = !@stripe
    { cols: data, stripe: @stripe }

# XXX if top not moved then body not moved

  render_data: (data,first) ->
    t_data = { table_row: [], rows: [], cols: data.cols }
    widths = (c.percent for c in @holder.state.coldata())
    t_data.widths = widths
    @render_head(t_data,data,first)
    for r in data.rows
      t_data.rows.push(@render_row(r))
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

  render_chunk: (data,first) ->
    # Not async right now, but probably will be one day, so use deferred
    d = $.Deferred()
    if first then @holder.data_actions(data)
    outer = @render_data(data,first)
    outer.appendTo(@container)
    if first then @holder.table_ready(@container)
    return d.resolve(data)

  get_page: (total,start,maxchunksize) ->
    first = true
    chunk_loop = (window.then_loop (got) =>
      if total - got <= 0 then return null
      chunksize = total - got
      if chunksize > maxchunksize then chunksize = maxchunksize
      return @get_data(start+got,chunksize)
        .then (data) =>
          got += data.rows.length
          return @render_chunk(data,first)
        .then (data) =>
          first = false
          return got
    )
    return $.Deferred().resolve(0).then(chunk_loop)

  render_main: (idx) ->
    @stripe = 1
    start = @holder.state.start()
    page = @holder.state.pagesize()
    chunk = @holder.options.chunk_size
    return @get_page(page,start,chunk)

# XXX only deform on giant tables
# XXX reorderable cols
# XXX stripes and hidden chunks
# XXX odd page sizes

  get_data: (start,num) ->
    @holder.source.get(@holder.state.filter(),@holder.state.columns(),@holder.state.order(),start,num)

  render: ->
    if @container? then @container.remove()
    @new_idx()
    @container = $('<div/>').addClass('search_table')
    return @render_main(@idx)

# XXX periodic headers

window.TableSource = Source
window.TableState = TableState
window.search_table = TableHolder

