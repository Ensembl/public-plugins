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

### This script wraps the actual hive beekeeper script to get the url
### param from SiteDefs instead of having to provide it in command line.

### This script can be run as a cron job but will not start a new beekeeper
### instance if there's one already running

### This accepts three extra arguments:
### --no_cache_config: to ignore the cached configurations saved in
###   the beekeeper.config file.
### --redirect_output: flag provided if this script is being run by cron.
###   The output is then redirected to log files.
### --kill: flag if on will only kill any existing beekeeper process

use strict;

use Data::Dumper;
use DBI;
use FindBin qw($Bin);
use Time::localtime;

my $config_file   = "$Bin/beekeeper.config";
my $log_file      = "$Bin/beekeeper.log";
my $cron_log_file = "$Bin/beekeeper.cronlog";
my $script_name   = 'beekeeper.pl';
my $no_cache      = grep { $_ eq '--no_cache_config' }  @ARGV;
my $redirect_out  = grep { $_ eq '--redirect_output' }  @ARGV;
my $kill          = grep { $_ eq '--kill'            }  @ARGV;
my $sleep_time    = grep({ $_ =~ /^\-\-sleep/        }  @ARGV) ? undef : "0.5";
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
  unshift @INC, reverse(map("$code_path/sanger-plugins/$_/modules/", qw(tools_hive tools)), @{SiteDefs::ENSEMBL_LIB_DIRS});
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;

  require EnsEMBL::Web::SpeciesDefs;

  my $sd  = EnsEMBL::Web::SpeciesDefs->new();
  $config = {
    'EHIVE_ROOT_DIR'  => $ENV{'EHIVE_ROOT_DIR'},
    'json_configs'    => ["$ENV{'EHIVE_ROOT_DIR'}/hive_config.json", "$code_path/sanger-plugins/tools_hive/conf/hive_config.json"],
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

if (my $pids = `pgrep -d ',' -f "$command"`) {
  if ($kill) {
    my $tries = 10;
    my $wait  = 4;
    while ($tries--) {
      if (system(qq(pkill -f "$command"))) {
        warn "Beekeeper killed.\n";
        exit;
      }
      warn "Killing beekeeper processes: $pids";
      warn "Waiting for ${wait}s...\n";
      sleep $wait;
    }
    die "Could not kill processes: $pids";
  }
  warn "Beekeeper already running with PID $pids";
  exit;
}

exit if $kill;

my $dbh = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $config->{'db'}{'name'}, $config->{'db'}{'host'}, $config->{'db'}{'port'}), $config->{'db'}{'user'}, $config->{'db'}{'pass'}, { 'PrintError' => 0 });

die "Database connection to hive db could not be created. Please make sure the pipiline is initialised.\nError: $DBI::errstr\n"   unless $dbh;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containing HIVE code.\n"                               unless $config->{'EHIVE_ROOT_DIR'};
die "Could not find location of the hive $script_name script.\n"                                                                  unless chdir "$config->{'EHIVE_ROOT_DIR'}/scripts/";

warn "Running beekeeper\n";

system(join ' ',
  $command,
  map({ -r $_ ? qq(--config_file="$_") : () } @{$config->{'json_configs'} }),
  $sleep_time ? qq(--sleep=$sleep_time) : (),
  grep($_ !~ /^\-\-(redirect_output|no_cache_config|kill)$/, @ARGV),
  $redirect_out ? ('>&', $log_file) : ()
);

1;
