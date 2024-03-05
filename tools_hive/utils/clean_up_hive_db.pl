#!/usr/local/bin/perl
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
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


use strict;

use DBI;
use File::Basename qw(dirname);
use FindBin qw($Bin);
use vars qw($SERVERROOT);

BEGIN {
  my $serverroot = "$Bin/../../..";
  unshift @INC, "$serverroot/conf", $serverroot;
  eval{ require SiteDefs; SiteDefs->import; };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use EnsEMBL::Web::SpeciesDefs;
my $sd = new EnsEMBL::Web::SpeciesDefs;

my $serverroot = "$Bin/../../../";

my $hive_db = $sd->multidb->{'DATABASE_WEB_HIVE'};
my $db   = $hive_db->{'NAME'};
my $host = $hive_db->{'HOST'};
my $port = $hive_db->{'PORT'};
my $user = $hive_db->{'USER'} || $sd->DATABASE_WRITE_USER;
my $pass = $hive_db->{'PASS'} || $sd->DATABASE_WRITE_PASS;

my $url = "mysql://$user:$pass".'@'."$host:$port/$db"; 
my $days = 8; # delete jobs older than 8 days

my $command = $serverroot ."ensembl-hive/scripts/hoover_pipeline.pl -url " . $url . " -days_ago " . $days;
my $lib = join ':', @INC;
$ENV{PERL5LIB} = $lib;
system ($command);

