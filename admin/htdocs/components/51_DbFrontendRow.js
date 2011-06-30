/* overrides the default afterResponse method of DbFrontendRow to sort the rows in case of changelog */

Ensembl.Panel.DbFrontendRow.prototype.afterResponse = function(success) {
  if (success && window.location.href.match('Changelog')) {

    var team = $('input._cl_team_name', this.target).val();
    if ($(this.el).prev('._cl_team_heading').attr('id') != 'team_' + team) {
      $('#team_' + team).after(this.target, this.target.next());
    }
  }
  this.scrollIn({margin: 5});
};