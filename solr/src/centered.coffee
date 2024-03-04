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
  $.fn.centered = (options) ->
    if $.type(options) == 'string'
      if options == 'redo'
        @each(() -> $(@).trigger('redo'))
    else
      opts = $.extend({},$.fn.centered.defaults,options)
      @each () ->
        center($(@),opts)
        $(@).on('redo',(e) -> center($(@),opts))

  center = (el,opts) ->
    if el.find('.centeredinner').length
      el.html(el.find('.centeredinner').html()) # Remove old markup
    inner = $("<div/>").html(el.html()).css('word-wrap','break-word')
    el.empty().append(inner).css('line-height','normal')
    inner.addClass('centeredinner')
    # As large as it can be without overflowing
    size = null
    for fs in [opts.min..opts.max] by opts.inc
      inner.css('font-size',fs+'px')
      if overflowed(inner)
        break
      size = fs
    if size then inner.css('font-size',size+'px')
    # Vertically center with padding
    space = el.height() - inner.outerHeight()
    if space % 2 then space -= 1
    space /= 2
    inner.css {
      'margin-top': space,
      'margin-bottom': space,
      'text-align': 'center'
    }
 
  overflowed = (el) ->
    if el.height() > el.parent().height() or
        el.width() > el.parent().width()
      true
    else
      false  

  $.fn.centered.defaults = {
    min: 5 
    max: 100
    inc: 5 
  }
)(jQuery)
