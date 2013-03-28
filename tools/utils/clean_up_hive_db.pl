#!/usr/local/bin/perl

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

my $serverroot = "$Bin/../../../";

my $hive_db = $sd->multidb->{'DATABASE_WEB_HIVE'};
my $db = $hive_db->{'NAME'};
my $host = $hive_db->{'HOST'};
my $port = $hive_db->{'PORT'};
my $user = $sd->DATABASE_WRITE_USER;
my $pass = $sd->DATABASE_WRITE_PASS;

my $url = "mysql://$user:$pass".'@'."$host:$port/$db"; 
my $days = 8; # delete jobs older than 8 days

my $command = $serverroot ."ensembl-hive/scripts/hoover_pipeline.pl -url " . $url . " -days_ago " . $days;
system ($command);

