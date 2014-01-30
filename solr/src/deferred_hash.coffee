# DeferredHash is a little like jquery's Deferred.

# A single completion function is registered at construction time. That
# completion function eventually gets a hash. That hash has a key for
# every task added to the object with a value equal to the data it
# returned. Also, the completion function is guaranteed not to be called
# until the go method is called (whereupon it may be called immediately
# if all tasks have completed in the meantime).

# This method is used to parallelise requests to the SOLR server.

class window.DeferredHash
  constructor: (@that,@complete) ->
    @data = {}
    @outstanding = {}
    @num = 0
    @_go = 0

  add: (key) ->
    @outstanding[key] = 1
    @num++

  done: (key,data) ->
    @data[key] = data
    delete @outstanding[key]
    @num--
    if @num == 0 and @_go
      @complete.call(@that,@data)

  go: ->
    @_go = 1
    if @num == 0
      @complete.call(@that,@data)

