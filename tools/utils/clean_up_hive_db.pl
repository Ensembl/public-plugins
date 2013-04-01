#!/usr/local/bin/perl

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
my $lib = join ':', @INC;
$ENV{PERL5LIB} = $lib;
system ($command);

