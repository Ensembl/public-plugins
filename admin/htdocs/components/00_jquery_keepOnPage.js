/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

/**
 * keepOnPage
 * A very small jQuery plugin to keep an element always on the page when page scrolled vertically
 * Not yet tested in all scenarios, but works for Ensembl Admin Healthcheck pages where required
 */

(function($) {
  
  $.keepOnPage = function (el, options) {

    el = $(el);
    
    if (!navigator.userAgent.match(/msie\s6/i)) {
    
      var defaults = {
        coords: el.offset(),
        position: el.css('position'),
        top: el.css('top')
      };
      
      el.css('width', el.css('width'));
  
      var rePosition = function () {
        el.css(defaults.coords.top - options.marginTop <= $(window).scrollTop() ? {position: 'fixed', top: options.marginTop} : {position: defaults.position, top: defaults.top});
      };
  
      $(window).bind({
        load:   rePosition,
        scroll: rePosition
      });
    }
  };
  
  $.fn.keepOnPage = function (options) {

    options = options || {};
    options.marginTop = options.marginTop || 0;
    
    this.each(function() {

      new $.keepOnPage(this, options);
    });
    
    return this;

  };
})(jQuery);



