# Remedial class for IE8-
if typeof(String.prototype.trim) != 'function'
  String.prototype.trim = () ->
    return this.replace(/^\s+|\s+$/g, '')

if typeof(Array.prototype.indexOf) != 'function'
  Array.prototype.indexOf = (obj, start) ->
    for i in [(start ? 0)...this.length]
      if this[i] == obj then return i
    return -1
