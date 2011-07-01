/* overrides the default afterResponse method of DbFrontendRow to sort the rows in case of changelog */
// TODO - hide any heading and link if record moved to another team

Ensembl.Panel.DbFrontendRow.prototype.afterResponse = function(success) {
  if (success && window.location.pathname.match('Changelog')) {

    var team = $('input._cl_team_name', this.target).val();
    if ($(this.el).prev('._cl_team_heading').attr('id') != 'team_' + team) {
      $('#team_' + team).removeClass('hidden').after(this.target, this.target.next());
      $('#_cl_link_' + team).removeClass('hidden');
    }
  }
  this.scrollIn({margin: 5});
};