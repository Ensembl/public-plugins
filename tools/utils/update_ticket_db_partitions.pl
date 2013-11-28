#!/usr/local/bin/perl
# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Script that is run by cron to create and remove paritions from the tools database tables
# this works by calling a stored procedure on the mysql server hosting the database
# procedure should be called with the following options:
# database_name (db_name), table_name (t_name), number of previous days to keep partions for (days_past), number of days 
# into the future to create partions for (days_future).
# Command called should look like:
# 
# "CALL db_name.UpdatePartitions('db_name', 't_name', days_past, days_future);"

use strict;

use DBI;
use File::Basename qw(dirname);
use FindBin qw($Bin);
use vars qw($SERVERROOT);

BEGIN {
  my $serverroot = "$Bin/../../..";
  unshift @INC, "$serverroot/conf", $serverroot;
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use EnsEMBL::Web::SpeciesDefs;
my $sd = new EnsEMBL::Web::SpeciesDefs;

my $tools_db = $sd->multidb->{'DATABASE_WEB_TOOLS'};
my $db = $tools_db->{'NAME'};

my $dbh = DBI->connect(
  sprintf('DBI:mysql:database=%s;host=%s;port=%s', $db, $tools_db->{'HOST'}, $tools_db->{'PORT'}),
  $sd->ENSEMBL_USERDB_USER, $sd->ENSEMBL_USERDB_PASS
);

for ('result', 'ticket', 'sub_job', 'analysis_object'){
  my $command = sprintf ("CALL %s.UpdatePartitions('%s', '%s', %s, %s);", $db, $db, $_, 8, 7 );
  $dbh->do($command);

}

$dbh->disconnect;

