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
  $.fn.selbox = (options,arg1,arg2,arg3) ->
    if $.type(options) == 'string'
      if options == 'activate'
        @each(() -> $(@).trigger('selboxactivate',[true,arg1,arg2,arg3]))
      else if options == 'deactivate'
        @each(() -> $(@).trigger('selboxactivate',[false]))
      else if options == 'maintext'
        @each(() -> $(@).trigger('selboxtext',[arg1]))
      else if options == 'select'
        @each(() -> $(@).trigger('selboxselect',[arg1]))
    else
      opts = $.extend({},$.fn.selbox.defaults,options)
      @each () ->
        $(@).on 'selboxtext', (e,text) ->
          settext($(@),text,opts)
        $(@).on 'selboxselect', (e,id) ->
          ul = $(@).data('selboxul')
          if ul.length
            selected($(@),$("a[href=\"##{id}\"]",ul),opts)
        $(@).on 'selboxactivate', (e,act,maintext,texts,ids) ->
          if act
            activate($(@),maintext,texts,ids,opts)
          else
            deactivate($(@),opts)

  settext = (el,text,opts) ->
    box = el.closest('.selboxouter').find('.selboxtext')
    box.html(text)
    opts.selchange.call(box)

  activate = (el,maintext,texts,ids,opts) ->
    if el.closest('.selboxouter').length then return
    # Build HTML
    w = el.width()
    go_button = el.siblings('.fbutton');
    outer = $(opts.template)
    selbox = $('.selbox',outer)
    newbox = $('.selboxnew',outer)
    outer.insertBefore(el)
    newbox.append(el)
    newbox.append(go_button)
    replacement_filter = $('.replacement_filter', newbox).width('auto');
    go_button.css('margin-top', '2px');
    selbox.height(el.height());
    $('.selboxtext',selbox).height(selbox.height())
    if opts.field?
      $('<input/>').attr({
        type: 'hidden'
        name: opts.field
      }).addClass('selboxfield').appendTo(selbox)
    # misc size tweaks to account for padding etc.
    el.selbox('maintext',maintext)
    ul = $('ul',outer).css({ display: 'none', width: selbox.width() })
    boxpos = newbox.offset()
    ul.appendTo('body').css {
      top: boxpos.top+newbox.height()+"px",
      left: boxpos.left+"px"
    }
    el.data("selboxul",ul)
    ga = new Ensembl.GA.EventConfig({ category: 'SearchInputFeatureType', nonInteraction: true });
    selbox.click (e) ->
      ul.toggle()
      $('.selboxselected',ul).removeClass('selboxselected')
    ulover = ul.outerWidth() - ul.width()
    ul.width(ul.width()-ulover)
    extrapad = (newbox.outerWidth() - newbox.width()) -
      (ul.outerWidth() - ul.width())
    # setup list and add callbacks
    for t,i in texts
      li = $('<a/>').attr('href','#'+ids[i]).html(t).wrap('<li/>').parent()
      li.css('padding-left',parseInt(li.css('padding-left'))+extrapad+"px")
        .appendTo(ul)
      li.click (e) -> 
        if !window.location.pathname.match(/Search\/Results/)?
          Ensembl.GA.sendEvent(ga, {action: $('a', this).text(), label: Ensembl.species})
        selected(el,$('a',@),opts)
      $('a',li).on('click',(e) -> selected(el,$(@),opts))
      li.mouseleave () ->
        $(@).removeClass('selboxselected')
      li.mouseenter () ->
        ul = $(@).closest('ul')
        ul.find('li').removeClass('selboxselected')
        lel = ul.find('.selboxforce').removeClass('selboxforce')
        if not lel.length then lel = $(@)
        lel.addClass('selboxselected')
    $('html').on 'focusin', (e) ->
      tg = $(e.target)
      if tg.parents('.selboxlist').length
        return true
      el.data("selboxul").hide()
      true
    # keyboard handling
    $('html').keydown (e) ->
      switch e.keyCode
        when 27 then ul.hide() # Escape
        when 40 # Down
          sel = $('.selboxselected',ul)
            .removeClass('selboxselected')
            .next()
          if not sel.length then sel = $('li',ul).first()
          sel.addClass('selboxselected')
          into_view(sel)
        when 38 # Up
          sel = $('.selboxselected',ul)
            .removeClass('selboxselected')
            .prev()
          if not sel.length then sel = $('li',ul).last()
          sel.addClass('selboxselected')
          into_view(sel)
        when 13 # Enter
          sela = $('.selboxselected a',outer)
          if sela.length
            selected(el,sela,opts)
          ul.hide()

  selected = (el,a,opts) ->
    href = a.attr('href')
    href = href.substring(href.indexOf('#')) # IE7
    opts.action.call(el,href.substring(1),a.html(),opts)
    a.closest('ul').hide()
    $('.selboxfield',el.closest('.selboxnew')).val(href.substring(1))
    false

  into_view = (el) ->
    el_top = el.position().top
    el_bot = el_top + el.outerHeight()
    ul = el.closest('ul')
    sc_height = ul.height()
    ul.find('.selboxforce').removeClass('selboxforce')
    el.addClass('selboxforce')
    if el_top < 0
      ul.scrollTop(ul.scrollTop() + el_top - 10)
    else if el_bot > sc_height
      ul.scrollTop(ul.scrollTop() + (el_bot - sc_height) + 10)
    else
      return
 
  deactivate = (el,opts) ->
    outer = el.closest('.selboxouter')
    if not outer.length then return
    el.width(outer.width()-(el.outerWidth()-el.width()))
    el.insertAfter(outer)
    el.data("selboxul").hide()
    outer.remove()

  $.fn.selbox.defaults = {
    action: () ->
    selchange: () ->
    field: null
    template: """
      <div class="selboxouter">
        <div class="selboxnew">
          <div class="selbox">
            <div class="selboxarrow">
              <div class="selboxtext">
                Hello
              </div>
            </div>
          </div>
        </div>
        <ul class="selboxlist">
        </ul>
      </div>
    """
  }
)(jQuery)
