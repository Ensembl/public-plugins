# EphemoralRequestRateLimiter is used to avoid punishing servers for data
#   which is quickly changing, like when a user is entering a search
#   string and we are doing incremental queries. It takes the current
#   value for the data but only submits it to the supplied function
#   after it hasn't changed for the interval "nochange" or the last
#   request was more than the interval "lastreq" ago. The operation is
#   not resubmitted if the data is the same as the last data. Equality
#   for this test can be overridden in the constructor.

class window.EphemoralRequestRateLimiter
  constructor: (@nochange_ms,@lastreq_ms,@operation,
                @equal = ((a,b) -> a==b)) ->
    @timeout = undefined
    @last_request = undefined
    @last_data = undefined
    @_trigger()

  set: (@data) ->
    if @timeout then clearTimeout(@timeout)
    @timeout = setTimeout(((v) => @_trigger(v)),@nochange_ms)
    now = new Date().getTime()
    if (not @last_request?) or now - @last_request > @lastreq_ms
      @_trigger()
    
  _trigger: ->
    if not @equal(@last_data,@data)
      @last_data = @data
      @last_request = new Date().getTime()
      @operation(@data)

  get: -> @data

