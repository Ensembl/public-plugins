//Extension to Ensembl.Panel.Masthead to add some dynamic behaviour to account links

Ensembl.Panel.Masthead = Ensembl.Panel.Masthead.extend({
  constructor: function (id) {
    this.base(id);

    Ensembl.EventManager.register('refreshAccountsDropdown', this, this.refreshAccountsDropdown);
  },

  init: function () {
    this.base();

    this.elLk.accountHolder = this.el.find('div._account_holder');
    
    this.refreshAccountsDropdown();
  },
  
  refreshAccountsDropdown: function() {
    var panel = this;

    if (!this.elLk.accountHolder.find('._accounts_no_user').length) {

      this.elLk.accountHolder.empty();

      var hideDropdown = function(e) {
        if (!e.which || e.which === 1) {
          panel.toggleAccountsDropdown(false);
          $(document).off('click', hideDropdown);
        }
      }

      $.ajax('/Ajax/accounts_dropdown', {
        'context': this,
        'success': function(html) {
          this.elLk.accountHolder.html(html);
          this.elLk.accountLink = this.el.find('._accounts_link').on({
            'click': function(event) {
              event.preventDefault();
              if (!$(this).hasClass('selected')) {
                event.stopPropagation();
                panel.toggleAccountsDropdown(true);
                $(document).on('click', hideDropdown);
              }
            }
          });
    
          this.elLk.accountDropdown = this.el.find('._accounts_dropdown').on({
            'click': function(event) {
              if (event.target.nodeName !== 'A') {
                event.stopPropagation();
              }
            }
          }).find('a').on('click', hideDropdown).end();
        },
        'dataType': 'html'
      });
    }
  },

  toggleAccountsDropdown: function(flag) {
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
