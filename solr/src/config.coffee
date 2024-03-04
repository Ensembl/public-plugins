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
