window.rate_limiter = (nochange_ms,lastreq_ms) ->
  timer = null
  last_request = null
  pending = null

  return (data) ->
    d = $.Deferred()
    # cancel any outstanding reuqests
    if pending
      pending.reject()
      clearTimeout(timer)
      pending = null
    # have we waited long enough, anyway?
    now = new Date().getTime()
    if (not last_request) or now - last_request > lastreq_ms
      last_request = now 
      d.resolve(data)
    else
      pending = d
      last_request = now
      timer = setTimeout((() -> d.resolve(data)),nochange_ms)
    return d

window.ensure_currency = () ->
  idx = 0

  return () ->
    idx += 1
    return ((cidx) ->
      return ((data) ->
        if cidx == idx
          return data
        else
          return $.Deferred().reject()
        )
    )(idx)
   
