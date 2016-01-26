/*
 * Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

/* Keys for Ensembl.GA.eventConfigs
  id              - Unique string to enable Ensembl.GA.getConfig method get hold of any config later in the stage to modify an existing event
  url             - String or regexp to match the page URL
  selector        - jQuery Selector string or function returning the elements
  wrapper         - jQuery Selector string (in case the actually element is dynamically added to the page, provide this wrapper as the closest parent that is present when page's loaded)
  event           - Actual page event that needs to be recorded (eg. click or mousemove etc) or 'ajax' if recording an ajax request event
  ajaxUrl         - String or regexp matching ajax url in case event is 'ajax'
  data            - Object that can be used in other function calls (eg. category, action etc) to avoid code duplication in those functions (values in this object can be functions that get resolved before other config keys)
  category        - Category as reqiuried by ga (Can be a string or a function returning a string called in context of the actual dom element or ajax options in case of ajax event)
  action          - Action as reqiuried by ga (Can be a string or a function returning a string called in context of the actual dom element or ajax options in case of ajax event)
  label           - Label as reqiuried by ga (Can be a string or a function returning a string called in context of the actual dom element or ajax options in case of ajax event) (defaults to referer string)
  value           - Value as required by ga (Can be a number or a function returning a number called in context of the actual dom element or ajax options in case of ajax event) (defaults to 1)
  nonInteraction  - non-interaction as reqiuried by ga (Can be a boolean or a function returning a boolean called in context of the actual dom element or ajax options in case of ajax event) (defaults to false)
*/

Ensembl.GA.eventConfigs.push(

  // Species icons in the homepage
  {
    id              : 'SpeciesIcon',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : '.species_list_container a',
    event           : 'click',
    category        : 'SpeciesIcon',
    action          : function () { return this.getURL(); }
  },

  // Species dropdown on the home page
  {
    id              : 'SpeciesDropdown',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'select.dropdown_redirect',
    event           : 'change',
    category        : 'SpeciesDropdown',
    action          : function () { return this.getText($(this.currentTarget).find('option:selected')); }
  },

  // Save favourite link on homepage
  {
    id              : 'HomepageLink-SaveFavourites',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'div.static_favourite_species p.customise-species-list',
    event           : 'click',
    category        : 'HomepageLink',
    action          : 'SaveFavourites',
    label           : function () { return this.getText(); }
  },

  // Likns below species icon on homepage
  {
    id              : 'HomepageLink-FullListSpeciesLink',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'div.static_all_species > p > a, div.trackhub-ad a, p.othersites a',
    event           : 'click',
    category        : 'HomepageLink',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText(); }
  },

  // Species dropdown tab (the left most tab) on all pages
  {
    id              : 'SpeciesTab',
    url             : /.+/,
    selector        : '#masthead div.dropdown.species a',
    event           : 'click',
    category        : 'SpeciesTab',
    action          : function () { return this.getURL(); }
  },

  // Links on the masthead
  {
    id              : 'MastheadLink',
    url             : /.+/,
    selector        : '#masthead div.logo_holder a, #masthead div.tools_holder ul.tools a',
    event           : 'click',
    category        : 'MastheadLink',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText() || 'LogoClick'; }
  },

  // Accounts link in the masthead
  {
    id              : 'AccountsLink',
    url             : /.+/,
    selector        : '._accounts_dropdown a, a._accounts_no_user',
    wrapper         : '#masthead ._account_holder',
    event           : 'click',
    category        : 'AccountsLink',
    action          : function () { return this.getURL(); }
  },

  // Local context links and the left hand side tools buttons
  {
    id              : 'LocalContext-LeftButton',
    url             : /.+/,
    selector        : '.local_context a, .tool_buttons a',
    event           : 'click',
    data            : { url : function () { return this.getURL(); } },
    category        : function () { return this.currentTarget.parentNode.nodeName === 'LI' ? 'LocalContext' : 'LeftButton' },
    action          : function () { return this.data.url.match('/Config/') ? this.data.url.replace(/\/[^\/]+$/, '') : this.data.url; },
    label           : function () { return this.currentTarget.parentNode.nodeName === 'LI' ? this.getText() : '' }
  },

  // Clickable header for a component that opens a help popup
  {
    id              : 'HelpHeader',
    url             : /.+/,
    selector        : 'h1 a.help-header',
    event           : 'click',
    category        : 'HelpHeader',
    action          : function () { return $(this.currentTarget).attr('href'); },
    label           : function () { return this.getText(); }
  },

  // Icons on the homepage and example icons on species homepage
  {
    id              : 'ThumbnailIcon',
    url             : /^http:\/\/[^\/]+\/index.html|\/Info\/Index/,
    selector        : '#static .tool-box a, .homepage-icon a:has(img)',
    event           : 'click',
    category        : 'ThumbnailIcon',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText(); }
  },

  // Carrousel control icons
  {
    id              : 'CarrouselIcon',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'a.bx-prev, a.bx-next, a.bx-stop, a.bx-start, a.bx-pager-link',
    event           : 'click',
    category        : 'CarrouselIcon',
    action          : function () { return this.getText().replace(/\d/, '') || 'Pager'; } // the pager icon has only numbers in it
  },

  // Links inside the carrousel
  {
    id              : 'CarrouselLink',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'ul.bxslider a',
    event           : 'click',
    category        : 'CarrouselLink',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText(); }
  },

  // News links on the right hand side of the home page
  {
    id              : 'HomepageLink-WhatsNew',
    url             : /^http:\/\/[^\/]+\/index.html/,
    selector        : 'div.whats-new a',
    event           : 'click',
    category        : 'HomepageLink',
    action          : function () { return this.currentTarget.hostname === window.location.hostname ? 'NewsLink' : 'BlogLink'; },
    label           : function () { return this.getText(); }
  },

  // Links on the project info above the footer on homepage
  {
    id              : 'HomepageLink-ProjectLinks',
    url             : /.+/,
    selector        : 'div.footer-ack a',
    event           : 'click',
    category        : 'HomepageLink',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText() || ($(this.currentTarget).find('img').attr('alt') + ' (logo)'); }
  },

  // Links in the footer on all pages
  {
    id              : 'FooterLink',
    url             : /.+/,
    selector        : 'div#footer a, div#wide-footer a',
    event           : 'click',
    category        : 'FooterLink',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText(); }
  },

  // Icons above the dynamic image
  {
    id              : 'ImageToolbar-Button',
    url             : /.+/,
    selector        : '.image_toolbar a:not(.popup)',
    wrapper         : '.ajax.initial_panel',
    event           : 'click',
    data            : { panelId: function () { return $(this.currentTarget).closest('.js_panel').prop('id'); } },
    category        : 'ImageToolbar',
    action          : function () { return this.currentTarget.className.match(/mr-reset/) ? 'MarkingOnOff' : this.getURL().replace(this.data.panelId, '').replace(/\/$/, ''); },
    label           : function () { return this.data.panelId; }
  }, {
    id              : 'ImageToolbar-ResizeMenu',
    url             : /.+/,
    selector        : '>div.image_resize_menu a',
    wrapper         : 'body',
    event           : 'mousedown', // before it triggers this click event handler, the image destroys itself to resize it, so using mousedown event
    category        : 'ImageToolbar',
    action          : function () { return '/Resize/' + this.getURL().split('/')[1] + '/' + this.getText().replace(' ', ''); },
    label           : function () { return $(this.currentTarget).closest('.image_resize_menu').attr('rel'); }
  }, {
    id              : 'ImageToolbar-SwitchGenoverse',
    url             : 'Location/View',
    event           : 'ajax',
    ajaxUrl         : '/Genoverse/switch_image',
    category        : 'ImageToolbar',
    action          : '/Genoverse/switch_image',
    label           : 'ViewTop'
  }, {
    id              : 'ImageToolbar-ShareButton',
    url             : /.+/,
    event           : 'ajax',
    ajaxUrl         : /\/Share\/.+share_type\=image/,
    category        : 'ImageToolbar',
    data            : { url: function () { return this.getURL(); } },
    action          : function () { return this.data.url.replace(/\/[^\/]+$/, ''); },
    label           : function () { return this.data.url.split('/').pop(); }
  },

  // Component tools bottons
  {
    id              : 'LocalButton',
    url             : /\/(Sequence|Exon)/,
    selector        : 'div.component-tools > a',
    wrapper         : '.ajax.initial_panel',
    event           : 'click',
    category        : 'LocalButton',
    action          : function () { return this.getURL(); }
  },

  // Tab links
  {
    id              : 'TabLink',
    url             : /.+/,
    selector        : '#masthead ul.tabs li a:not(.toggle)',
    event           : 'click',
    category        : 'TabLink',
    action          : function () { return this.getURL(); }
  },

  // Tab links
  {
    id              : 'TabHistory',
    url             : /.+/,
    selector        : '#masthead div.dropdown:not(.species) ul li a',
    event           : 'click',
    category        : 'TabHistory',
    action          : function () { return this.getURL(); },
    label           : function () { return this.getText($(this.currentTarget).closest('div.dropdown').find('>h4')); }
  },

  // Location navigation and gene autocomplete panel above region image
  {
    id              : 'NavBar-Inputs',
    url             : 'Location/View',
    selector        : '.navbar form._nav_loc, .navbar form._nav_gene',
    wrapper         : '.ajax.initial_panel',
    event           : 'submit',
    category        : 'NavBar',
    action          : function () { return this.currentTarget.className.match(/_nav_loc/) ? 'LocationSubmit' : 'GeneSubmit'; }
  },

  // Location navigation buttons
  {
    id              : 'NavBar-Slider',
    url             : 'Location/View',
    selector        : '.navbar .image_nav a',
    wrapper         : '.ajax.initial_panel',
    event           : 'mousedown', // bxslider doesn't let any click event trigger on slider ui element, so using mousedown
    category        : 'NavBar',
    action          : function () { return this.currentTarget.className.match('slider') ? 'slider' : this.currentTarget.className.replace(/constant|disabled/g, '').trim(); }
  },

  // Explore icons
  {
    id              : 'ExploreIcon',
    url             : /(Variation\/Explore|Gene\/Compara[^_]+|Location\/Compara[^_]+|Regulation)/,
    selector        : '.portal a',
    event           : 'click',
    category        : 'ExploreIcon',
    action          : function () { return this.getURL(); },
    label           : function (e) { return e.target.nodeName === 'SPAN' ? 'count' : 'image'; }
  },

  // Opening a ZMenus by clicking on a feature on dynamic image or text sequence
  {
    id              : 'ZMenuOpen',
    url             : /.+/,
    event           : 'ajax',
    ajaxUrl         : /\/[^\/]+\/ZMenu\//,
    category        : 'ZMenuOpen',
    action          : function () { return this.getURL(); },
    label           : function () {
                        if (this.action.match('TextSequence')) { // most popular, stays on top to save some machine cycles for most of the events
                          return 'text_sequence';
                        }
                        var imageconfig = this.currentOptions.url.match(/(\?|;)config=([^;]+)/);
                        if (imageconfig) { // second most popular
                          return imageconfig.pop();
                        }
                        if (this.action.match('/Label')) {
                          return (decodeURIComponent(this.currentOptions.url).match(/\"image_config\"\s*\:\s*\"([^\"]+)\"/) || ['']).pop();
                        }
                        if (window.location.href.match('Tools/VEP/Results') && this.action.match(/\/ZMenu\/(Gene|Transcript)/)) {
                          return 'vep_results_table';
                        }
                        return '';
                      }
  },

  // Clicking on a link inside ZMenu
  {
    id              : 'ZMenuLink',
    url             : /.+/,
    event           : 'click',
    selector        : '>div.zmenu_holder a',
    wrapper         : 'body',
    category        : 'ZMenuLink',
    action          : function () { return this.currentTarget.className.match(/_location_mark|_action_mark/) ? 'MarkingOnOff' : this.getURL(); },
    label           : function () { return this.getURL(Ensembl.PanelManager.panels[$(this.currentTarget).closest('.zmenu_holder').prop('id')].href); }
  },

  // Search boxes - including the ones on homepage, species homepage, search page and top right corner
  {
    id              : 'SearchInput-Inputs',
    url             : /.+/,
    selector        : '.search_holder form, .search-form',
    event           : 'submit',
    category        : 'SearchInput',
    action          : function () { return this.currentTarget.className.match('search-form') ? window.location.href.match('index.html') ? 'HomepageSearch' : 'SpeciesPageSearch' : 'TopRightSearch'; }
  }, {
    id              : 'SearchInput-SearchPageSearch',
    url             : '/Search/Results',
    event           : 'ajax',
    ajaxUrl         : '/Ajax/psychic',
    category        : 'SearchInput',
    action          : 'SearchPageSearch'
  }, {
    id              : 'SearchInput-ExampleLink',
    url             : /^http:\/\/[^\/]+\/index.html|\/Info\/Index/,
    event           : 'click',
    selector        : '#SpeciesSearch .search-example a',
    category        : 'SearchInput',
    action          : 'ExampleLink',
    label           : function () { return window.location.pathname.match(/Info/) ? 'SpeciesPage' : 'HomePage'; }
  }
);
