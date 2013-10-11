class TextProc2
  constructor: () ->
    @candidates = {}
    @values = {}
    @running = []

  ## CANDIDATES ##
  candidate: (key,value,priority) ->
    if not priority? then priority = @candidates[key]?.priority ? 0
    if not value? then return
    if (not @candidates[key]?) or @candidates[key].priority < priority
      @candidates[key] = { value, priority }
  
  best: (key) -> @candidates[key]?.value

  ## VALUE SETS ##
  add_value: (key,value,position) ->
    if not @values[key] then @values[key] = []
    @values[key].push({value, position})

  all_values: (key) -> @values[key]

  ## OUTPUT ##
  send: (key,value) -> @output[key] = value

  ## RUNNING ##
  register: (prio,method) ->
    @running.push({prio, method })

  _sort_running: () ->
    return (r.method for r in @running.sort((a,b) -> a.prio - b.prio))

  run: (data) ->
    @candidates = {}
    @values = {}
    @output = {}
    @candidate(k,v,0) for k,v of data
    for r in @_sort_running()
      r.call(@)
    return @output

window.TextProc2 = TextProc2

