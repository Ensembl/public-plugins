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

//Extension to Ensembl.Panel.Masthead to add some dynamic behaviour to account links

Ensembl.Panel.Masthead = Ensembl.Panel.Masthead.extend({
  constructor: function (id) {
    this.base(id);
    
    Ensembl.EventManager.register('refreshAccountsDropdown', this, this.refreshAccountsDropdown);
  },
  
  init: function () {
    this.base();
    
    this.elLk.accountHolder = this.el.find('div._account_holder');

    this.accountsRefreshURL        = '';
    this.accountsBookmarkData      = '';
    this.accountsDropdownLoaded    = false;
    this.accountsDropdownLoading   = false;
    this.accountsDropdownCallbacks = [];
    
    this.bindAccountsDropdown();
  },
  
  cacheAccountsForm: function() {
    var form = this.elLk.accountHolder.find('form');

    if (form.length) {
      this.accountsRefreshURL   = form.attr('action');
      this.accountsBookmarkData = form.serialize();
    }
  },

  bindAccountsDropdown: function() {
    var panel = this;

    if (!this.elLk.accountHolder.length) {
      return;
    }

    this.cacheAccountsForm();

    this.elLk.accountLink = this.elLk.accountHolder.find('._accounts_link').off('.accountsDropdown').on({
      'click.accountsDropdown': function(event) {
        event.preventDefault();

        if (!$(this).hasClass('selected')) {
          event.stopPropagation();
          panel.showAccountsDropdown();
        }
      },
      'focus.accountsDropdown': function() {
        panel.loadAccountsDropdown();
      }
    });

    this.elLk.accountDropdown = this.elLk.accountHolder.find('._accounts_dropdown').off('.accountsDropdown').on({
      'click.accountsDropdown': function(event) {
        if (event.target.nodeName !== 'A' && event.target.parentNode.nodeName !== 'A') {
          event.stopPropagation();
        }
      }
    }).find('a').off('.accountsDropdown').on('click.accountsDropdown', function(e) {
      panel.hideAccountsDropdown(e);
    }).end();

    this.accountsDropdownLoaded = this.elLk.accountDropdown.length && $.trim(this.elLk.accountDropdown.html()).length ? true : false;

    this.elLk.accountHolder.find('._accounts_no_userdb').helptip().off('.accountsDropdown').on({
      'click.accountsDropdown': function(event) {
        event.preventDefault();
      }
    });
  },

  loadAccountsDropdown: function(callback, force) {
    if ($.isFunction(callback)) {
      this.accountsDropdownCallbacks.push(callback);
    }

    if (!this.elLk.accountHolder.length || (!force && this.elLk.accountHolder.find('._accounts_no_user').length)) {
      this.accountsDropdownCallbacks = [];
      return;
    }

    if (this.accountsDropdownLoaded && !force) {
      this.runAccountsDropdownCallbacks();
      return;
    }

    if (this.accountsDropdownLoading) {
      return;
    }

    // Keep /Ajax/accounts_dropdown off the initial page load. Normal use fetches
    // it on first open; force is reserved for account modal updates.
    this.cacheAccountsForm();

    if (!this.accountsRefreshURL) {
      this.accountsRefreshURL = '/Ajax/accounts_dropdown';
    }

    this.accountsDropdownLoading = true;

    $.ajax({
      'url': this.accountsRefreshURL,
      'context': this,
      'data': this.accountsBookmarkData,
      'type': 'POST',
      'success': function(html) {
        var response = $('<div>').html(html);
        var accountDropdown = response.find('._accounts_dropdown');

        if (!force && accountDropdown.length && this.elLk.accountHolder.find('._accounts_link').length) {
          this.elLk.accountHolder.find('._accounts_dropdown').replaceWith(accountDropdown);
        } else {
          this.elLk.accountHolder.html(html);
          this.elLk.accountHolder.toggleClass('_logged_in', this.elLk.accountHolder.find('._accounts_link').length ? true : false);
        }

        this.bindAccountsDropdown();
        this.runAccountsDropdownCallbacks();
      },
      'error': function() {
        this.accountsDropdownCallbacks = [];
      },
      'complete': function() {
        this.accountsDropdownLoading = false;
      },
      'dataType': 'html'
    });
  },

  refreshAccountsDropdown: function(callback) {
    this.loadAccountsDropdown($.isFunction(callback) ? callback : null, true);
  },

  runAccountsDropdownCallbacks: function() {
    var callback;

    while (this.accountsDropdownCallbacks.length) {
      callback = this.accountsDropdownCallbacks.shift();
      callback.call(this);
    }
  },

  showAccountsDropdown: function() {
    var panel = this;

    if (!this.accountsDropdownLoaded) {
      this.loadAccountsDropdown(function() {
        panel.showAccountsDropdown();
      });
      return;
    }

    this.toggleAccountsDropdown(true);

    $(document).off('click.accountsDropdown').on('click.accountsDropdown', function(e) {
      panel.hideAccountsDropdown(e);
    });
  },

  hideAccountsDropdown: function(e) {
    if (!e || !e.which || e.which === 1) {
      this.toggleAccountsDropdown(false);
      $(document).off('click.accountsDropdown');
    }
  },

  toggleAccountsDropdown: function(flag) {
    if (!this.elLk.accountLink.length || !this.elLk.accountDropdown.length) {
      return;
    }

    this.elLk.accountLink.toggleClass('selected', flag);
    this.elLk.accountDropdown.toggle(flag);
    if (flag && !this.elLk.accountDropdown.data('initiated')) {
      this.elLk.accountDropdown.data('initiated', true).find('p').each(function() {
        var p = $(this);
        var checkHeight = p.children('a').hide().end().append('<a>abc</a>').height();
        p.children('a').last().remove().end().show();
        if (p.height() > checkHeight) {
          p.addClass('acc-bookmark-overflow');
        }
      });
    }
  }
});
