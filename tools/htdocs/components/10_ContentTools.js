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

/*
 * Plugin to Content panel to make Ajax requests and handle generic JSON responses (as returned by JSON Controller by the Perl backend)
 */

Ensembl.Panel.ContentTools = Ensembl.Panel.Content.extend({

  ajax: function(configs) {
  /*
   * Wrapper arounf jQuery's ajax method
   * Forces the generic response handling for any resposne recieved
   */
    var panel   = this;

    $.ajax($.extend({
      'type'        : 'get'
    }, configs, {
      'dataType'    : 'json',
      'context'     : panel,
      'success'     : function(json) {
        var result = this.ajaxSuccess(json);
        if (configs.success && typeof(configs.success) == 'function') {
          configs.success.call(this, json, result);
        }
      },
      'error'       : function(jqXHR, textStatus, errorThrown) {
        this.ajaxError(jqXHR, textStatus, errorThrown);
        if (configs.error && typeof(configs.error) == 'function') {
          configs.error.call(this, jqXHR, textStatus, errorThrown);
        }
      }
    }));
  },

  ajaxSuccess: function(json) {
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

  ajaxError: function(jqXHR, textStatus, errorThrown) {
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
          errorThrown = 'Some unknown error occurred';
      }
    }
    this.showError(errorThrown, heading);
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
    message = message || 'Some unknown error has occoured.';
    if (!this.errorDiv) {
      var panel     = this;
      this.errorDiv = $('<div>')
        .append('<div class="error-overlay"></div><div class="error-popup error"><h3 class="_error_heading"></h3><div class="error-pad"><p class="_error_message"></p><p class="center"><a href="#" class="_error_hide button">Close</a></p></div></div>')
        .appendTo(document.body)
        .find('a._error_hide').on('click', function(event) {
          event.preventDefault();
          panel.hideError();
        }).end();
    }
    this.errorDiv.find('._error_heading').html(heading).end().find('._error_message').html(message).end().show();
  },

  hideError: function() {
  /*
   * Hides the errorDiv
   */
    if (this.errorDiv) {
      this.errorDiv.hide();
    }
  }
});