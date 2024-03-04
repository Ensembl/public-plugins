/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Genoverse.Track.Controller = Genoverse.Track.Controller.extend({
  resize: function () {
    this.base.apply(this, arguments);

    var autoHeight = this.prop('autoHeight');
    var resizer    = this.prop('resizer');

    if (resizer) {
      resizer[autoHeight ? 'hide' : 'show']();
    }

    if (arguments[1] === true) {
      var config = { auto_height: autoHeight ? 1 : 'undef' };

      if (!autoHeight) {
        config.user_height = Math.max(this.prop('height') - this.prop('margin'), 1);
      }

      this.browser.saveConfig(config, this.track);
    }

    Ensembl.EventManager.trigger('resetImageOffset');
    this.browser.updateSelectorHeight();
  },

  addDomElements: function () {
    this.base.apply(this, arguments);

    this.label.add(this.container).not('.gv-unsortable').on('mouseenter mouseleave', {els: this.label.add(this.container)}, function (e) {
      e.data.els.filter(function() {
        return e.currentTarget !== this;
      }).toggleClass('hover', e.type === 'mouseenter');
    });
  },

  click: function () {
    if (this.browser.panel.elLk.container.hasClass('ui-resizable-resizing')) {
      return false;
    }

    this.base.apply(this, arguments);
  },

  populateMenu: function () {
    return false;
  },

  destroy: function () {
    this.prop('menus').each(function () { Ensembl.EventManager.trigger('destroyPanel', this.id); });
    this.base();
  }
});
