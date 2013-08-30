# Comment on next line is for js output only. Please ignore here.
### Do not edit this .js, edit the .coffee file and recompile ###

(($) ->
  $.solr_config = (options,params...) ->
    if $.type(options) == 'string'
      get(options,params)
    else
      opts = $.extend({},$.solr_config.defaults,options)
      setup(opts)

  setup = (opts) ->
    if $('html').data('config') then return new $.Deferred().resolve()
    return $.ajax({ url: opts.url, dataType: 'json' }).done((data) ->
      $('html').data('config',data)
    )

  get = (path,params) ->
    data = $('html').data('config')
    argidx = 0
    for k in path.split('.')
      if not data? then continue
      if k == '%'
        data = data[params[argidx]]
        argidx += 1 
      else if k.charAt(k.length-1) == '='
        k = k.substring(0,k.length-1)
        val = params[argidx]
        argidx += 1
        next = null
        for e in data
          if e[k] == val
            next = e
        data = next
      else
        data = data[k]
    return data

  $.solr_config.defaults = {
  }
)(jQuery)
