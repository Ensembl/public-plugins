#!/usr/local/bin/perl
# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

# This script wraps the actual hive beekeeper script to get the url
# param from SiteDefs instead of having to provide it in command line.

# This accepts two extra arguments:
# --no_cache_config: to ignore the cached configurations saved in
#   the beekeeper.config file.
# --redirect_output: flag provided if this script is being run by cron.
#   The output is then redirected to log files.

use strict;

use Data::Dumper;
use DBI;
use FindBin qw($Bin);
use Time::localtime;

my $config_file   = "$Bin/beekeeper.config";
my $log_file      = "$Bin/beekeeper.log";
my $cron_log_file = "$Bin/beekeeper.cronlog";
my $script_name   = 'beekeeper.pl';
my $no_cache      = grep { $_ eq '--no_cache_config' } @ARGV;
my $redirect_out  = grep { $_ eq '--redirect_output' } @ARGV;
my $sleep_time    = grep({ $_ =~ /^\-\-sleep/ } @ARGV) ? undef : "0.5";
my $config;

if ($redirect_out) {
  open STDERR, ">>$cron_log_file";
  warn sprintf "\n%s\n%s\n", ctime(), '-' x 24;
}

if (!$no_cache && -e $config_file) {
  if (open CONF, "<$config_file") {
    warn "Retrieving cached conf from $config_file\n";
    $config = <CONF>;
    $config = eval "$config";
    $config = undef if $@ || ref $config ne 'HASH';
    close CONF;
  } else {
    warn "Couldn't open $config_file file to read configs: $!\n";
    warn "Continuing to read configs from SiteDefs.\n";
  }
}

if (!$config) {
  my $code_path = "$Bin/../../..";
  unshift @INC, "$code_path/ensembl-webcode/conf";
  eval {
    require SiteDefs;
  };
  if ($@) {
    die "Can't use SiteDefs - $@\n";
  }
  unshift @INC, reverse ("$code_path/sanger-plugins/tools/modules/", @{SiteDefs::ENSEMBL_LIB_DIRS});
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;

  require EnsEMBL::Web::SpeciesDefs;

  my $sd  = EnsEMBL::Web::SpeciesDefs->new();
  $config = {
    'EHIVE_ROOT_DIR'  => $ENV{'EHIVE_ROOT_DIR'},
    'inc'             => \@INC,
    'db'              => {
      'host'            =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
      'port'            =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PORT'},
      'user'            =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'USER'} || $sd->DATABASE_WRITE_USER,
      'pass'            =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
      'name'            =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'NAME'}
    }
  };

  open(CONF, ">$config_file") or die "Couldn't open $config_file file to write configs: $!";
  print CONF Data::Dumper->new([$config])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(0)->Dump;
  close CONF;

} else {
  @INC = @{$config->{'inc'}};
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

my $command = "perl $script_name -url mysql://$config->{'db'}{'user'}:$config->{'db'}{'pass'}\@$config->{'db'}{'host'}:$config->{'db'}{'port'}/$config->{'db'}{'name'}";

if (my $pid = `ps -eo pid,cmd | sed -r 's/^\\s+//' | grep "$command" | grep -v grep | cut -d ' ' -f 1 | head -1`) {
  warn "Beekeeper already running with PID $pid\n";
  exit;
}

my $dbh = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $config->{'db'}{'name'}, $config->{'db'}{'host'}, $config->{'db'}{'port'}), $config->{'db'}{'user'}, $config->{'db'}{'pass'}, { 'PrintError' => 0 });

die "Database connection to hive db could not be created. Please make sure the pipiline is initialised.\nError: $DBI::errstr\n"   unless $dbh;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                                 unless $config->{'EHIVE_ROOT_DIR'};
die "Could not find location of the hive $script_name script.\n"                                                                  unless chdir "$config->{'EHIVE_ROOT_DIR'}/scripts/";

warn "Running beekeeper\n";
system(join ' ', $command, $sleep_time ? ("--sleep=$sleep_time") : (), grep($_ !~ /^\-\-(redirect_output|no_cache_config)$/, @ARGV), $redirect_out ? ('>&', $log_file) : ());

1;
