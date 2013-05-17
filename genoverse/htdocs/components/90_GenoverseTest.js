// $Revision$

Ensembl.Panel.GenoverseTest = Ensembl.Panel.Content.extend({
  init: function () {
    var id  = this.id.replace('Test', '');
    var url = this.params.updateURL.split('?');
        url = url[0] + '/main?' + url[1] + (!!parseInt($('.static_image', this.el).val(), 10) || !this.supported() ? ';static=1' : '');
    
    $('#' + this.id).html('<div class="ajax js_panel" id="' + id + '"><input type="hidden" class="ajax_load" value="' + url + '" /></div>');
    
    this.base();
    
    Ensembl.EventManager.register('ajaxComplete', this, function () {
      if (typeof Ensembl.PanelManager.panels[id].panelType === 'undefined') {
        Ensembl.EventManager.trigger('destroyPanel', id);
      }
      
      Ensembl.EventManager.remove(this.id);
    });
  },
  
  getContent: function (url, el, params, newContent) {
    params = $.extend(params || this.params, { genoverseSwitch: this.supported() });
    this.base(url, el, params, newContent);
  },
  
  supported: function () {
    var elem = document.createElement('canvas');
    return !!(elem.getContext && elem.getContext('2d') && Ensembl.locationURL === 'search');
  }
});
