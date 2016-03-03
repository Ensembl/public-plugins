/*
 * Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

/* overrides the default afterResponse method of DbFrontendRow to sort the rows in case of changelog */
// TODO - hide any heading and link if record moved to another team

Ensembl.DbFrontendRow.prototype.afterResponseORM = Ensembl.DbFrontendRow.prototype.afterResponse;
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
  } else {
    this.afterResponseORM(success);
  }
};