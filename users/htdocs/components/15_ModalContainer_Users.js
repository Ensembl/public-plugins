// Extension to the core ModalContainer.js to refresh the accounts dropdown everytime modal window is closed

Ensembl.Panel.ModalContainer = Ensembl.Panel.ModalContainer.extend({
  hide: function () {
    this.base();

    if (this.el.find('._needs_refresh_on_hide').removeClass('_needs_refresh_on_hide').length) {
      Ensembl.EventManager.trigger('refreshAccountsDropdown');
    }
  }
});