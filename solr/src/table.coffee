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

# The table code exports two classes.
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
_clone_array = (a) -> $.extend(true,[],a)

# XXX clear footer

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
  pagesize: () ->
    if @pagesize_override then @pagesize_override else @el.data('pagesize')
  start: -> (@page()-1)*@pagesize()
  coldata: -> (@_colkey[k] for k in @el.data('columns'))
  sortkey: (k) -> @_sortkey[k]
  associate: (@table) ->

class TableHolder
  constructor: (@templates,@state,@options = {}) ->
    @state.associate(@)
    if not @options.chunk_size? then @options.chunk_size = 1000

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

  collect_view_model: (el,data) ->
    @outer = el

  element: -> @outer

  draw_table: ->
    table = new Table(@)
    table.render() 
  xxx_table: -> return new Table(@)

  table_ready: (html) ->
    table = $('.search_table_proper',@outer)
    table.empty()
    table.append(html)

class Table
  _idx = 0

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
    klass = ''
    if @stripe then klass = ' stripe'
    if @holder.options.style_col? and data[@holder.options.style_col]?
      klass += ' ' + data[@holder.options.style_col]
    { cols: data, stripe: @stripe, klass }

# XXX if top not moved then body not moved

  render_data: (data,first) ->
    t_data = { table_row: [], rows: [], cols: data.cols }
    widths = (c.percent for c in @holder.state.coldata())
    t_data.widths = widths
    if first then @render_head(t_data,data,first)
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
    outer = @render_data(data,first)
    outer.appendTo(@container)
    return d.resolve(data)

  # XXX new
  reset: () ->
    if @container? then @container.remove()
    @container = $('<div/>').addClass('search_table')
    @stripe = 1
    @empty = 1
    @holder.table_ready(@container)

  draw_top: () ->

  draw_rows: (rows) ->
    d = @render_chunk(rows,@empty) # XXX not false
    @empty = 0
    return d

  draw_bottom: () ->

  # XXX done new

  render: ->
    if @container? then @container.remove()
    @container = $('<div/>').addClass('search_table')
    @stripe = 1
    start = @holder.state.start()
    page = @holder.state.pagesize()
    chunk = @holder.options.chunk_size
    return @get_page(page,start,chunk)

# XXX periodic headers

window.TableState = TableState
window.search_table = TableHolder

