# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

### This accepts four extra arguments:
### --no_cache_config: to ignore the cached configurations saved in
###   the beekeeper.config file.
### --redirect_output: flag provided if this script is being run by cron.
###   The output is then redirected to log files.
### --kill: flag if on will only kill any existing beekeeper process
### --path: Path that should be used to create config and log files

use strict;

use Data::Dumper;
use DBI;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Time::localtime;

my $path            = $Bin;
my $no_cache        = grep { $_ eq '--no_cache_config' }  @ARGV;
my $redirect_out    = grep { $_ eq '--redirect_output' }  @ARGV;
my $kill            = grep { $_ eq '--kill'            }  @ARGV;
my $sleep_time      = grep({ $_ =~ /^\-\-sleep/        }  @ARGV) ? undef : "0.5";
my $include_script  = abs_path("$Bin/../../../ensembl-webcode/conf/includeSiteDefs.pl");
my $command_args    = [];

for (@ARGV) {
  $path = $_ and last if !$path;
  if ($_ =~ /^\-\-path=?(.*)/) {
    $path = $1 ? $1 : undef;
    last if $path;
  }
}

$path ||= $Bin; # if --path is present without any value, fall back to $Bin

my $config_file   = "$path/beekeeper.config";
my $log_file      = "$path/beekeeper.log";
my $cron_log_file = "$path/beekeeper.cronlog";
my $pid_file      = "$path/beekeeper.pid";

# send output of this script to a cronlog file
if ($redirect_out) {
  open STDERR, ">>$cron_log_file";
  warn sprintf "\n%s\n%s\n", ctime(), '-' x 24;
}

# if pid file is found and process is running
# don't run another instance if command is run one
# kill the one if command is to kill
if (-e $pid_file) {
  open PID, "<$pid_file" or die "Could not open PID file $pid_file: $!\n";
  my $pid = join '', <PID>;
  close PID;
  chomp $pid;

  if ($pid =~ /\d+/ && kill('ZERO', $pid)) {
    if ($kill) {
      warn "Killing $pid\n";
      kill('TERM', $pid) or warn "Could not kill beekeeper: $!\n";
    } else {
      warn "Beekeeper already running: $pid\n";
    }
    exit;
  }
}

# command is to kill, but there's no running pid
if ($kill) {
  warn "No beekeeper process to kill\n";
  exit;
}

# get db config (cached or form SpeciesDefs)
my $config = _get_config($config_file, $no_cache, $include_script);

# check if the db details are valid
DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $config->{'db'}{'name'}, $config->{'db'}{'host'}, $config->{'db'}{'port'}), $config->{'db'}{'user'}, $config->{'db'}{'pass'}, { 'PrintError' => 0 })
  or die "Database connection to hive db could not be created. Please make sure the pipiline is initialised.\nError: $DBI::errstr\n";

# script present?
my $script_path = "$config->{'EHIVE_ROOT_DIR'}/scripts/beekeeper.pl";
die "Could not find beekeeper.pl\n" unless -e $script_path;

# --url param for beekeeper script
push @$command_args, '-url', "mysql://$config->{'db'}{'user'}:$config->{'db'}{'pass'}\@$config->{'db'}{'host'}:$config->{'db'}{'port'}/$config->{'db'}{'name'}";

# json config files for beekeeper
push @$command_args, '--config_file', $_ for @{$config->{'json_configs'}};

# --sleep arg
push @$command_args, '--sleep', $sleep_time if $sleep_time;

# any other args in the command line
push @$command_args, grep($_ !~ /^\-\-(redirect_output|no_cache_config|kill|path)$/, @ARGV);

# wrapper command
my $command = sprintf q(%s %s/beekeeper.pl '%s' %s), $config->{'perl'}, $Bin, Data::Dumper->new([{
  'script'          => $script_path,
  'include_script'  => $include_script,
  'pid_file'        => $pid_file,
  'command_args'    => $command_args
}])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(0)->Maxdepth(0)->Dump =~ s/\'/'"'"'/gr, $redirect_out ? ">& $log_file" : '';

warn "Running beekeeper\n";

system("$command &");

# DONE

sub _get_config {
  ## @private
  ## Generates config from SpeciesDefs and caches it in a file for next time
  ## Initialising SiteDefs and SpeciesDefs is an expensive task, so required configs are cached in a file for next cron iteration
  my ($config_file, $no_cache, $include_script) = @_;

  my $config;

  if (!$no_cache && -e $config_file) {
    if (open CONF, "<$config_file") {
      warn "Retrieving cached conf from $config_file\n";
      $config = join '', <CONF>;
      $config = eval "$config";
      $config = undef if $@ || ref $config ne 'HASH';
      close CONF;
    } else {
      warn "Couldn't open $config_file file to read configs: $!\n";
      warn "Continuing to read configs from SiteDefs.\n";
    }
  }

  if (!$config) {
    require $include_script;
    require EnsEMBL::Web::SpeciesDefs;

    my $sd    = EnsEMBL::Web::SpeciesDefs->new();
    my $perl  = $sd->ENSEMBL_BEEKEEPER_PERL;

    $config = {
      'EHIVE_ROOT_DIR'  => $ENV{'EHIVE_ROOT_DIR'},
      'perl'            => $perl,
      'json_configs'    => [grep -r, "$ENV{'EHIVE_ROOT_DIR'}/hive_config.json", "$SiteDefs::ENSEMBL_SERVERROOT/public-plugins/tools_hive/conf/hive_config.json"],
      'db'              => {
        'host'            => $sd->hive_db->{'host'},
        'port'            => $sd->hive_db->{'port'},
        'user'            => $sd->hive_db->{'username'},
        'pass'            => $sd->hive_db->{'password'},
        'name'            => $sd->hive_db->{'database'}
      }
    };

    open(CONF, ">$config_file") or die "Couldn't open $config_file file to write configs: $!";
    print CONF Data::Dumper->new([$config])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(1)->Maxdepth(0)->Dump;
    close CONF;
  }

  return $config;
}

1;
