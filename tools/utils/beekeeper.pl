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

# This accepts an extra arguments '--no_cache_config' to ignore the cached
# configurations saved in the beekeeper.config file.

use strict;

use Data::Dumper;
use DBI;
use FindBin qw($Bin);

my $config_file = "$Bin/beekeeper.config";
my $no_cache    = grep { $_ eq '--no_cache_config' } @ARGV;
my $config;

if (!$no_cache && -e $config_file && open CONF, "<$config_file") {
  $config = <CONF>;
  $config = eval "$config";
  $config = undef if $@ || ref $config ne 'HASH';
  close CONF;
}

if (!$config) {
  my $code_path = "$Bin/../../..";
  unshift @INC, "$code_path/ensembl-webcode/conf";
  eval {
    require SiteDefs;
  };
  if ($@) {
    print "Can't use SiteDefs - $@\n";
    exit;
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

  if (open CONF, ">$config_file") {
    print CONF Data::Dumper->new([$config])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(0)->Dump;
    close CONF;
  } else {
    print "Can't save db configs: $!";
    exit;
  }
} else {
  @INC = @{$config->{'inc'}};
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

my $command     = "-url mysql://$config->{'db'}{'user'}:$config->{'db'}{'pass'}\@$config->{'db'}{'host'}:$config->{'db'}{'port'}/$config->{'db'}{'name'}";
my $script_name = 'beekeeper.pl';

if (my $pid = `ps -eo pid,cmd | grep "perl $script_name $command" | grep -v grep | sed -r 's/^\\s+//' | cut -d ' ' -f 1`) {
  print "Beekeeper already running with PID $pid\n";
  exit;
}

my $dbh = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $config->{'db'}{'name'}, $config->{'db'}{'host'}, $config->{'db'}{'port'}), $config->{'db'}{'user'}, $config->{'db'}{'pass'}, { 'PrintError' => 0 });

die "Database connection to hive db could not be created. Please make sure the pipiline is initialised.\nError: $DBI::errstr\n"   unless $dbh;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                                 unless $config->{'EHIVE_ROOT_DIR'};
die "Could not find location of the $script_name script.\n"                                                                       unless chdir "$config->{'EHIVE_ROOT_DIR'}/scripts/";

system(join ' ', 'perl', $script_name, $command, grep { $_ ne '--no_cache_config' } @ARGV);

1;
