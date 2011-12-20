/* overrides the default afterResponse method of DbFrontendRow to sort the rows in case of changelog */
// TODO - hide any heading and link if record moved to another team

Ensembl.DbFrontendRow.prototype.afterResponse = function(success) {
  if (success && window.location.pathname.match('Changelog')) {

    var team = $('input._cl_team_name', this.target).val();

    if ($(this.el).prev('._cl_team_heading').first().attr('id') != 'team_' + team) {

      var form = this.target.next().hasClass('_cl_team_heading') ? false : this.target.next();
      $('#team_' + team).removeClass('hidden').after(this.target);
      if (form) {
        this.target.after(form);
      }
      $('#_cl_link_' + team).removeClass('hidden');
    }
    window.location.hash = 'team_' + team;
  }
  else {
    this.scrollIn({margin: 5});
  }
};