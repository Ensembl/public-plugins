=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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
use Date::Parse; # for str2time
use List::Util qw(sum);

use previous qw(process);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $hub->species_defs;

  if ($hub->action =~ /tools_stats/) {

    if (!$hub->user->is_member_of($sd->ENSEMBL_WEBADMIN_ID)) {
      print to_json({error => 'You are not authorised to view this data.'});
      return;
    }

    my $db_confs = $sd->multidb->{'DATABASE_WEB_HIVE'};

    # if DB is not configured
    if (!$db_confs) {
      print to_json({error => 'No database found for DATABASE_WEB_HIVE'});
      return;
    }

    $self->{'hive_dbh'} = DBI->connect(
      "dbi:$db_confs->{'DRIVER'}:database=$db_confs->{'NAME'};host=$db_confs->{'HOST'};port=$db_confs->{'PORT'}",
      $db_confs->{'USER'},
      $db_confs->{'PASS'} || $sd->DATABASE_WRITE_PASS
    );

    # if could not connect to DB
    if (!$self->{'hive_dbh'}) {
      print to_json({error => 'Could not connect to database DATABASE_WEB_HIVE'});
      return;
    }
  }

  $self->PREV::process(@_);
}

sub ajax_waittime_tools_stats {
  my $self  = shift;
  my $hub   = $self->hub;

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
  my $type_row = $self->{'hive_dbh'}->selectall_arrayref("select `analysis_id` from `analysis_base` where `logic_name` = '$type' limit 1");
  if (!@$type_row) {
    print to_json({error => "Type not found: $type"});
    return;
  }
  $type_row = $type_row->[0][0];

  # Get from and to time stamps
  my $from_time = $to_time - 3600 * 24;
  ($to_time, $from_time) = map strftime("%Y-%m-%d %H:%M:%S", localtime($_)), $to_time, $from_time;

  # get all data
  my $all_rows = $self->{'hive_dbh'}->selectall_arrayref("select `time`, `ready_job_count` from `analysis_stats_monitor` where `time` > '$from_time' and `time` < '$to_time' and `analysis_id` = $type_row order by `time` asc");
  if (!@$all_rows) {
    print to_json({error => "$type: No data found for the given time"});
    return;
  }

  $from_time = str2time($from_time);

  @$all_rows = grep { ($_->[1] = $_->[1] + 0) && ($_->[0] = str2time($_->[0]) - $from_time) } @$all_rows;

  my %data = map { $_->[0] => $_->[1] } @$all_rows;

  print to_json({data => \%data, offset => $from_time});
}

sub ajax_processingtime_tools_stats {
  my $self  = shift;
  my $hub   = $self->hub;

  # Tools type
  my $type = $hub->param('type') || 'BLASTN';
  if ($type !~ /^\w+$/) {
    print to_json({error => "Invalid type: $type"});
    return;
  }

  # Get from and to time stamps
  my $from_time = $hub->param('from');
  my $to_time   = $hub->param('to');
  if ($from_time !~ /^\d+$/) {
    print to_json({error => "Invalid time format: $from_time"});
    return;
  }
  if ($to_time !~ /^\d+$/) {
    print to_json({error => "Invalid time format: $to_time"});
    return;
  }

  ($to_time, $from_time) = map strftime("%Y-%m-%d %H:%M:%S", localtime($_)), $to_time, $from_time;

  # Get type from DB
  my $type_row = $self->{'hive_dbh'}->selectall_arrayref(sprintf "select `analysis_id` from `analysis_base` where `logic_name` = '%s' limit 1", $type =~ /BLAST/ ? 'Blast' : $type);
  if (!@$type_row || ($type =~ /BLAST/ && !{ map { $_ => 1 } qw(BLASTN BLASTP BLASTX TBLASTN TBLASTX) }->{$type})) {
    print to_json({error => "Type not found: $type"});
    return;
  }
  $type_row = $type_row->[0][0];

  my $sql;
  if ($type =~ /BLAST/) {
    $sql = sprintf q{
            SELECT
              `job`.`runtime_msec` AS `runtime`,
              SUBSTRING_INDEX(SUBSTRING_INDEX(`analysis_data`.`data`, '"program" => "', -1), '"', 1) AS `tool_type`
            FROM
              `job`,
              `analysis_data`
            WHERE
              `job`.`analysis_id` = %d AND
              `job`.`status` = 'DONE' AND
              `job`.`job_id` = `analysis_data`.`analysis_data_id` AND
              `job`.`completed` > '%s' and `job`.`completed` < '%s'
            HAVING
              `tool_type` = '%s'
            ORDER BY
              `runtime` DESC
          }, $type_row, $from_time, $to_time, lc $type;
  } else {
    $sql = sprintf q{
            SELECT
              `job`.`runtime_msec` AS `runtime`,
              `analysis_base`.`logic_name` AS `tool_type`
            FROM
              `job`, `analysis_base`
            WHERE
              `job`.`analysis_id` = %d AND
              `job`.`analysis_id` = `analysis_base`.`analysis_id` AND
              `job`.`status` = 'DONE' AND
              `job`.`completed` > '%s' and `job`.`completed` < '%s'
            ORDER BY
              `runtime` DESC
          }, $type_row, $from_time, $to_time;
  }

  my $all_rows = $self->{'hive_dbh'}->selectall_arrayref($sql);

  if (!@$all_rows) {
    print to_json({error => "$type: No data found for the given time"});
    return;
  }

  # filter out some values so we only send a maximum of 1000 values per graph
  my @data      = map { $_->[0] } @$all_rows;
  my $set_size  = 1 + sprintf '%d', @data / 1000;
  my @sampled_data;
  while (@data >= $set_size) {
    my @set = splice @data, 0, $set_size;
    unshift @sampled_data, sprintf '%d', sum(@set) / $set_size / 1000; # 1000 is for msec to sec
  }

  # group the same values
  my @grouped_data;
  while (@sampled_data) {
    my $last_val = int shift @sampled_data;
    my $counter  = 1;
    while (@sampled_data && $last_val == $sampled_data[0]) {
      shift @sampled_data;
      $counter++;
    }
    push @grouped_data, $counter == 1 ? $last_val : [ $last_val, $counter ];
  }

  print to_json({data => \@grouped_data, from => str2time($from_time), to => str2time($to_time), setsize => $set_size});
}

1;
