// Extension to the core ModalContainer.js to refresh the accounts dropdown everytime modal window is closed

Ensembl.Panel.ModalContainer = Ensembl.Panel.ModalContainer.extend({
  hide: function () {
    this.base();

    Ensembl.EventManager.trigger('refreshAccountsDropdown');
  }
});