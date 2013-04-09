// $Revision$

Ensembl.LayoutManager.extend({
  makeZMenu: function (id, params) {
    if (!$('#' + id).length) {
      $([
        '<div class="info_popup floating_popup" id="', id, '">',
        ' <span class="close"></span>',
        '  <table class="zmenu" cellspacing="0">',
        '    <thead>', 
        '      <tr class="header"><th class="caption" colspan="2"><span class="title"></span></th></tr>',
        '    </thead>', 
        '    <tbody class="loading">',
        '      <tr><td><p class="spinner"></p></td></tr>',
        '    </tbody>',
        '    <tbody></tbody>',
        '  </table>',
        '  <div class="zmenu_bottom zmenu_paginate_info"></div>',
        '  <div class="zmenu_bottom zmenu_paginate" style="display: none">',
        '    <span class="first">&gt;&gt;</span>',
        '    <span class="previous">&gt;</span>',
        '    <span class="p1"></span>',
        '    <span class="p2"></span>',
        '    <span class="p3"></span>',
        '    <span class="next">&lt;</span>',
        '    <span class="last">&lt;&lt;</span>',  
        '  </div>',
        '</div>'
      ].join('')).draggable({ handle: 'thead' }).appendTo('body');
    }
    
    Ensembl.EventManager.trigger('addPanel', id, 'ZMenu', undefined, undefined, params, 'showExistingZMenu');
  }
});
