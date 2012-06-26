//Extension to Ensembl.Panel.Masthead to add some dynamic behaviour to account links

Ensembl.Panel.Masthead = Ensembl.Panel.Masthead.extend({
  init: function () {
    var panel = this;
    this.base();

    this.elLk.accountLink     = $('._accounts_link', this.el).bind({
      'click': function(event) {
        event.preventDefault();
        panel.toggleAccountsDropdown(!$(this).hasClass('selected'));
      }
    });

    this.elLk.accountDropdown = $('._accounts_dropdown', this.el).find('a').bind({
      'click': function() {
        panel.toggleAccountsDropdown(false);
      }
    }).end();
  },

  toggleAccountsDropdown: function(flag) {
    this.elLk.accountLink.toggleClass('selected', flag);
    this.elLk.accountDropdown.toggle(flag);
    if (flag && !this.elLk.accountDropdown.data('initiated')) {
      this.elLk.accountDropdown.data('initiated', true).children('p').each(function() {
        if ($(this).height() < $(this).children().first().height()) {
          this.className = 'acc-bookmark-overflow';
        }
      });
    }
  }
});