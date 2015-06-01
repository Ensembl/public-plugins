=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Controller::Ajax;

use strict;
use warnings;

use DBI;
use JSON qw(to_json);
use POSIX qw(strftime);
use Date::Parse;

sub ajax_tools_stats {
  my ($self, $hub) = @_;

  my $species_defs  = $hub->species_defs;
  my $db_confs      = $species_defs->multidb->{'DATABASE_WEB_HIVE'};

  # user authorisation
  if (!$hub->user->is_member_of($species_defs->ENSEMBL_WEBADMIN_ID)) {
    print to_json({error => 'You are not authorised to view this data.'});
    return;
  }

  # if DB is not configured
  if (!$db_confs) {
    print to_json({error => 'No database found for DATABASE_WEB_HIVE'});
    return;
  }

  my $dbh = DBI->connect(
    "dbi:$db_confs->{'DRIVER'}:database=$db_confs->{'NAME'};host=$db_confs->{'HOST'};port=$db_confs->{'PORT'}",
    $db_confs->{'USER'},
    $db_confs->{'PASS'} || $species_defs->DATABASE_WRITE_PASS
  );

  # if could not connect to DB
  if (!$dbh) {
    print to_json({error => 'Could not connect to database DATABASE_WEB_HIVE'});
    return;
  }

  # Tools type
  my $type = $hub->param('type') || 'Blast';
  if ($type !~ /^\w+$/) {
    print to_json({error => "Invalid type: $type"});
    return;
  }

  # Time to which graph is to be displayed
  my $to_time = $hub->param('at') || time;
  if ($to_time !~ /^\d+$/) {
    print to_json({error => "Invalid time format: $to_time"});
    return;
  }

  # Get type from DB
  my $type_row = $dbh->selectall_arrayref("select `analysis_id` from `analysis_base` where `logic_name` = '$type' limit 1");
  if (!@$type_row) {
    print to_json({error => "Type not found: $type"});
    return;
  }
  $type_row = $type_row->[0][0];

  # Get from and to time stamps
  my $from_time = $to_time - 3600 * 24;
  ($to_time, $from_time) = map strftime("%Y-%m-%d %H:%M:%S", localtime($_)), $to_time, $from_time;

  # get all data
  my $all_rows = $dbh->selectall_arrayref("select `time`, `ready_job_count` from `analysis_stats_monitor` where `time` > '$from_time' and `time` < '$to_time' and `analysis_id` = $type_row order by `time` asc");
  if (!@$all_rows) {
    print to_json({error => "No data found for the given time"});
    return;
  }

  $from_time = str2time($from_time);

  @$all_rows = grep { ($_->[1] = $_->[1] + 0) && ($_->[0] = str2time($_->[0]) - $from_time) } @$all_rows;

  my %data = map { $_->[0] => $_->[1] } @$all_rows;

  print to_json({data => \%data, offset => $from_time});
}

1;
