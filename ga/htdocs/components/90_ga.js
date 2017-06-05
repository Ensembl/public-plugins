/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

Ensembl.GA = {

  eventConfigs: [],
    /*
     * List of configs registered by default (added later in ga_configs.js)
     */

  domainCodes: {},
    /*
     * key pair value for domain name and it's corresponding code (specified later in plugins)
     */

  verbose: false,
    /*
     * Setting it to true will console.log the event being sent
     */

  logAjaxLoadTimes: true,
    /*
     * Setting it to false will disable logging AJAX load times
     */

  reportErrors: true,
    /*
     * Setting it to false will disable logging ServerError/Error pages
     */

  code: function () {
    /*
     * Returns the ga code for the current domain
     */
    return this.domainCodes[window.location.hostname];
  },

  init: function () {
    /*
     * Initialises google analytics
     */
    if (this.code() && !this.initialised) {
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ensGA');

      // get the species regexp before calling filterURL
      this.urlSpeciesRegex = new RegExp('/(' + Ensembl.allSpeciesList.join('|') + ')/');

      ensGA('create', this.code(), 'auto');
      ensGA('set', 'page', this.filterURL(window.location));
      ensGA('set', 'dimension1', Ensembl.species);
      ensGA('set', 'dimension2', Ensembl.isLoggedInUser ? 'yes' : 'no');
      ensGA('set', 'dimension3', window.location.pathname + window.location.search);
      ensGA('send', 'pageview');
      ensGA('require', 'linkid', 'linkid.js');

      this.initialised = true;
      this.registerConfigs(this.eventConfigs);
    }
  },

  filterURL: function (a) {
    /*
     * Gets url from an a tag after filtering out the species and GET parameters
     */
    if (typeof a === 'string') {
      a = $('<a>').attr('href', a)[0];
    }

    return a.hostname === window.location.hostname ? '/' + (a.pathname.replace(this.urlSpeciesRegex, '/').replace(/^\/+/, '') || 'index.html') : a.hostname;
  },

  sendEvent: function (config, extra, e) {
    /*
     * Sends the given event to GA
     */
    if (!this.initialised) {
      return;
    }

    var myConfig  = config.instantiate(extra, {label: '', value : 1}, e);
    var args      = [myConfig.category, myConfig.action, myConfig.label, myConfig.value, { nonInteraction : !!myConfig.nonInteraction }];

    if (myConfig.category && myConfig.action) {
      if (this.verbose) {
        console.log(args);
      }
      ensGA.apply(window, ['send', 'event'].concat(args));
    }

    Ensembl.GA.EventConfig.destroy(myConfig);
  },

  getConfig: function (configId) {
    /*
     * Grabs a config from the eventConfigs array with the given id
     */
    if (this.initialised === true) {
      throw "Can not get hold of a config after Ensembl.GA has been initialised";
    }

    for (var i = 0; i < this.eventConfigs.length; i++) {
      if (this.eventConfigs[i].id && this.eventConfigs[i].id === configId) {
        return this.eventConfigs[i];
      }
    }
  },

  deleteConfig: function (configId) {
    /*
     * Grabs a config from the eventConfigs array with the given id and prevents it from being loaded
     */
    var config = this.getConfig(configId);

    if (config) {
      config.deleted = true;
    }
  },

  registerConfigs: function (eventConfigs) {
    /*
     * Registers given events to be logged for google analytics
     */
    if (!this.initialised) {
      return;
    }

    eventConfigs = $.makeArray($.map(eventConfigs, function(config) {
      return config.deleted || config.url && !window.location.href.match(config.url) ? null : new Ensembl.GA.EventConfig(config);
    }));

    // mouse events - need to be added for all events individually
    this.addMouseEvents(eventConfigs);

    // save all events configs in a private variable
    if (!this._eventConfigs) {
      this._eventConfigs = [];
    }
    $.merge(this._eventConfigs, eventConfigs);

    // ajax events - just need to be added once since _eventConfigs keeps growing everytime we registerConfigs
    if (!this.ajaxEventsInitiated) {
      this.ajaxEventsInitiated = true;

      $.ajaxPrefilter(function(options, originalOptions, jqXHR) {
        $.each(Ensembl.GA._eventConfigs, function() {

          if (this.event === 'ajax' && originalOptions.url.match(this.ajaxUrl)) {

            Ensembl.GA.sendEvent(this, {currentOptions: originalOptions});
          }
        });
      });
    }
  },

  addMouseEvents: function (eventConfigs) {
  /*
   * Activates mouse events for given configs
   */
    $.each(eventConfigs, function() {

      if (this.event !== 'ajax') {

        // resolve target element if it's a function
        if (typeof this.selector === 'function') {
          this.selector = this.selector();
        }

        // resolve wrapper if it exists and is a function
        if (this.wrapper && typeof this.wrapper === 'function') {
          this.wrapper = this.wrapper();
        }

        // if wrapper is provided, selector has to be a string
        if (this.wrapper && typeof this.selector !== 'string') {
          console.log("If 'wrapper' key is provided, 'selector' can only be a string.");
          return;
        }

        var args = [ (this.event || 'click') + '.ga' ];
        if (this.wrapper) {
          args.push(this.selector);
        }
        args.push({config: this}, function(e) {

          Ensembl.GA.sendEvent(e.data.config, {currentTarget: this}, e);
        });

        $.fn.on.apply($(this.wrapper || this.selector), args);
      }
    });
  }
};

/**
 * Prototype for eventConfigs
 */
Ensembl.GA.EventConfig = function (config) {
  $.extend(this, config);
};

Ensembl.GA.EventConfig.prototype.getURL = function (url) {
  return Ensembl.GA.filterURL(url || this.currentTarget || this.currentOptions.url);
};

Ensembl.GA.EventConfig.prototype.getText = function (el) {
  return $(el || this.currentTarget).text().trim();
};

Ensembl.GA.EventConfig.prototype.instantiate = function (extra, defaults, e) {
  var config  = $.extend({}, defaults, this, extra);
  config.data = $.extend({}, this.data);

  $.each(config.data, function (key, val) { // resolve data first to allow it's use when resolving other keys
    Ensembl.GA.EventConfig.resolve(config, e, config.data, key);
  });

  $.each(['category', 'action', 'label', 'value', 'nonInteraction'], function(i, key) { // order is kept like this intentionally to allow use of category, action in other keys
    Ensembl.GA.EventConfig.resolve(config, e, config, key);
  });

  return config;
};

Ensembl.GA.EventConfig.resolve = function(config, e, obj, key) {
  if (typeof obj[key] === 'function') {
    obj[key] = obj[key].call(config, e);
  }
};

Ensembl.GA.EventConfig.destroy = function(obj) {
  if (obj.data) {
    this.destroy(obj.data);
  }

  for (var i in obj) {
    obj[i] = null;
  }

  obj = null;
};

// initialise ga when Ensembl initializes
Ensembl.extend({
  initialize: function () {
    Ensembl.setSpecies();
    if (Ensembl.setUserFlag) {
      Ensembl.setUserFlag();
    }
    var speciesListVal  = $('#hidden_species_list').val() || '';
    this.allSpeciesList = $.merge(['Multi'], speciesListVal.split('|'));
    Ensembl.GA.init();
    this.base.apply(this, arguments);
  }
});
