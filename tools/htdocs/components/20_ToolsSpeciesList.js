Ensembl.Panel.ToolsSpeciesList = Ensembl.Panel.extend({

  init: function () {  
    this.base();
    this.elLk.checkboxes  = $('.checkboxes', this.el);
    this.elLk.speciesList = $('.checkboxes input[name="species"]', this.el);
    this.elLk.multiselect = parseInt($('input[name="multiselect"]', this.el).val() || 1);
    this.elLk.list        = $('.list', this.el);
    this.elLk.modalLink   = $('.modal_link', this.el);
    Ensembl.species && Ensembl.species !== 'Multi' && this.updateTaxonSelection([{key: Ensembl.species, title: Ensembl.species}]);
    Ensembl.EventManager.register('updateTaxonSelection', this, this.updateTaxonSelection);
  },
  
  updateTaxonSelection: function(items) {
    var panel = this;
    var key;
    var new_list = [];

    // empty and re-populate the species list
    panel.elLk.list.empty();
    panel.elLk.checkboxes.empty();
    $.each(items, function(index, item){
      key = item.key.charAt(0).toUpperCase() + item.key.substr(1); // ucfirst
      var _delete = $('<span/>', {
        text: 'x',
        'class': 'ss-selection-delete',
        click: function() {
          // Update taxon selection
          var clicked_item_title = $(this).parent('li').find('span.ss-selected').html();
          var updated_items = [];

          //removing human and hence hide grch37 message
          if(clicked_item_title === "Homo_sapiens" || clicked_item_title === "Human") { panel.el.find('div.assembly_msg').hide(); }

          $.each(items, function(i, item) {
            if(clicked_item_title !== item.title) {
              updated_items.push(item);
            }
          });
          Ensembl.EventManager.trigger('updateTaxonSelection', updated_items);
          // Remove item from the Tools form list
          $(this).parent('li').remove();
        }
      });

      //adding human and hence show grch37 message
      if(item.title === "Homo_sapiens" || item.title === "Human") { panel.el.find('div.assembly_msg').show(); }


      var _selected_img = $('<img/>', {
        src: item.img_url || Ensembl.speciesImage,
        'class': 'nosprite'
      });

      var _selected_item = $('<span/>', {
        text: item.title,
        'data-title': item.title,
        'data-key': item.key,
        'class': 'ss-selected',
        title: item.title
      });
      
      var li = $('<li/>', {
      }).append(_selected_img, _selected_item, _delete).appendTo(panel.elLk.list);
      $(panel.elLk.checkboxes).append('<input type="checkbox" name="species" value="' + key + '" checked>' + item.title + '<br />');
      new_list.push(key);
    }); 

    // Check blat availability and reset
    Ensembl.EventManager.trigger('resetSearchTools', null, new_list);
    // Update sourceType on species selection change
    Ensembl.EventManager.trigger('resetSourceTypes', new_list);

    // update the modal link href in the form
    if (panel.elLk.modalLink.length) {
      var modalBaseUrl = panel.elLk.modalLink.attr('href').split('?')[0];
      var keys = $.map(items, function(item){ return item.key; });
      var queryString = $.param({s: keys, multiselect: this.elLk.multiselect, referer_type: 'Tools'}, true);
      panel.elLk.modalLink.attr('href', modalBaseUrl + '?' + queryString);
    }
  }
});
