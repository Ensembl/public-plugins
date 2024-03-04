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

/*
 * Plugin to Content panel to make Ajax requests and handle generic JSON responses (as returned by JSON Controller by the Perl backend)
 */

Ensembl.Panel.ContentTools = Ensembl.Panel.Content.extend({

  init: function() {

    var panel = this;

    this.base();

    // activate the JSON link
    this.el.find('a._json_link').on('click', function(e) {
      e.preventDefault();
      var message = $(this).find('._confirm').html();
      if (!message || window.confirm(message)) {
        panel.ajax({ 'url': this.href, 'spinner': true });
      }
    });

    // disguised AJAX links
    this.el.find('a._change_location').on('click', function(e) {
      panel.updateLocation(this.href);
    });
  },

  ajax: function(settings) {
  /*
   * Wrapper arounf jQuery's ajax method
   * Forces the generic response handling for any resposne recieved
   */
    var panel   = this;

    $.ajax($.extend({
      'type'        : 'get'
    }, settings, {
      'dataType'    : 'json',
      'context'     : panel,
      'beforeSend'  : function(jqXHR, modifiedSettings) {
        panel.ajaxBeforeSend(jqXHR, settings);
        if (settings.beforeSend && typeof(settings.beforeSend) === 'function') {
          settings.beforeSend.call(this, jqXHR, modifiedSettings);
        }
      },
      'success'     : function(json) {
        var result = this.ajaxSuccess(json, settings);
        if (settings.success && typeof(settings.success) === 'function') {
          settings.success.call(this, json, result);
        }
      },
      'error'       : function(jqXHR, textStatus, errorThrown) {
        this.ajaxError(jqXHR, textStatus, errorThrown, settings);
        if (settings.error && typeof(settings.error) === 'function') {
          settings.error.call(this, jqXHR, textStatus, errorThrown);
        }
      },
      'complete'    : function(jqXHR, textStatus) {
        this.ajaxComplete(jqXHR, textStatus, settings);
        if (settings.complete && typeof(settings.complete) === 'function') {
          settings.complete.call(this, jqXHR, textStatus);
        }
      }
    }));
  },

  ajaxBeforeSend: function(jqXHR, settings) {
  /*
   * Gets called before making the ajax request
   */
    if (settings.spinner) {
      settings.spinner = Math.random().toString().replace(/0\./, '');
      this.toggleSpinner(true, '', settings.spinner);
    }
  },

  ajaxSuccess: function(json, settings) {
  /*
   * Reads and reacts according to the JSON response sent by the Perl backend
   * To override this method, check it's return type in the child class.
   */
    if (!this.parseJSONResponseHeader(json)) {
      return 'header_status';
    }

    if (json.panelMethod) {
      var methodName = json.panelMethod.shift();

      if (methodName in this) {
        this[methodName].apply(this, json.panelMethod);
        json.panelMethod.unshift(methodName);
        return 'method_applied';
      }

      this.showError("Requested method '" + methodName + "' could not be found.", 'Javascript Error');
      return 'method_missing';
    }

    return true;
  },

  ajaxError: function(jqXHR, textStatus, errorThrown, settings) {
  /*
   * Reacts according to the error recieved from the Perl backend
   */
    var heading = errorThrown ? 'Server error' : 'Error';
    if (!errorThrown) {
      switch (textStatus) {
        case 'timeout':
          errorThrown = 'The request took longer than expected. The may happen due to an issue with your Internet connection.';
          break;
        case 'abort':
          errorThrown = 'The request was aborted, or the connection was closed unexpectedly.';
          break;
        case 'parsererror':
          errorThrown = 'An error occured while parsing the server response.';
        default:
          errorThrown = 'An unknown error occurred';
      }
    }
    this.showError(errorThrown, heading);
  },

  ajaxComplete: function(jqXHR, textStatus, settings) {
  /*
   * Gets called when the ajax request is complete
   */
    if (settings.spinner) {
      this.toggleSpinner(false, '', settings.spinner);
    }
  },

  parseJSONResponseHeader: function(json) {
  /*
   * This parses the header for status as packed inside the JSON object
   * Not to be confused with the actual HTTP header
   */
    var header = json.header || {};
    switch (parseInt(header.status)) {
      case 200:
        // continue with response handling
        return true;
      case 302:
        // handle redirection
        if (header.location) {
          this.ajax({'url' : header.location, 'async': false});
        } else {
          this.showError('Redirect URL is missing', 'Redirection Error');
        }
        return false;
      case 404:
        // not found
        this.showError('The requested page could not be found.', 'Not found');
        return false;
      case 500:
        // server error
        var exception = json.exception || {};
        this.showError(exception.message, 'Server Error: ' + exception.type);
        return false;
      default:
        // not likely to come here, but anyway...
        this.showError();
        return false;
    }
  },

  showError: function(message, heading) {
  /*
   * Displays error in the specified errorDiv
   * To display error in a custom div, create panel.errorDiv before calling this method
   */
    heading = heading || (message ? 'Error' : 'Unknown Error');
    message = message || 'An unknown error has occurred.';
    if (!this.elLk.errorDiv) {
      var panel     = this;
      this.elLk.errorDiv = $('<div>')
        .append('<div class="error-overlay"></div><div class="error-popup error"><h3 class="_error_heading"></h3><div class="error-pad"><p class="_error_message"></p><p class="center"><a href="#" class="_error_hide button">Close</a></p></div></div>')
        .appendTo(document.body)
        .find('a._error_hide').on('click', function(event) {
          event.preventDefault();
          panel.hideError();
        }).end();
    }
    this.elLk.errorDiv.find('._error_heading').html(heading).end().find('._error_message').html(message).end().show();
  },

  toggleSpinner: function(flag, message, id) {
  /*
   * Shows/hides the ensembl spinner on top of the panel according to the flag
   */
    if (!this.elLk.spinnerDivs) {
      this.elLk.spinnerDivs = $('<div class="tools-overlay"></div><div class="overlay-spinner spinner"></div>').appendTo(this.el.css('position', 'relative'));
    }
    if (flag) {
      if (id) {
        this.elLk.spinnerDivs.addClass('_active_' + id);
      }
      this.elLk.spinnerDivs.show().last().empty().html(message ? '<div>' + message + '</div>' : '');
    } else {
      if (id) {
        this.elLk.spinnerDivs.removeClass('_active_' + id);
      }
      this.elLk.spinnerDivs.filter(function() { return !this.className.match(/_active_/); }).hide();
    }
  },

  hideError: function() {
  /*
   * Hides the errorDiv
   */
    if (this.elLk.errorDiv) {
      this.elLk.errorDiv.hide();
    }
  },

  scrollIn: function(options) {
  /*
   * Gets the panel into visible area
   */
    options = $.extend({margin: 16, speed: 400}, options);

    var position = this.el.offset().top - options.margin;
    $('html,body').animate({ scrollTop: position }, options.speed);
  },

  updateLocation: function(url) {
  /*
   * Updates the current URL in the browser to the one given
   */
    if (url && url !== window.location.href && window.history && window.history.pushState) {
      window.history.pushState({}, '', url);
    }
  }
});
