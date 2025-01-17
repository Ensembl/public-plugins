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

### DO NOT RUN THIS SCRIPT INDEPENDENTLY
### THIS IS RUN VIA beekeeper_manager.pl

use strict;
use warnings;
no warnings qw(once);

use URI::Escape qw(uri_unescape);

# get passed config hash
my ($config) = @ARGV;
$config = eval(uri_unescape($config));
die "Could not parse command line arguments:\n$@" if $@;

# require SiteDefs and LoadPlugins
require $config->{'include_script'};

# Ideally, we shouldn't need to modify INC and set PERL5LIB here, because we already have all paths and
# plugins loaded properly via the includeSiteDefs script and we are running real beekeeper (ensembl-hive)
# below by 'do', not 'system', so it maintains everything in place.
# But the beekeeper then fires off workers via system calls, which loses the current INC. Thus setting
# PERL5LIB here so the workers can find all the runnables and other package in ensembl code base
# Due to this, the plugin system for the webcode doesn't work here - this means you can not have plugins
# for your runnables, or rely on any other packages in webcode that have plugins
# To cope with this, keep your runnables as independent of webcode as possible and NEVER use SiteDefs in
# any runnables. Pass any required params via dispatcher_data in ensembl_web_tools.job table
my %seen;
@INC = grep -d && !$seen{$_} && ($seen{$_} = 1), (reverse(@SiteDefs::ENSEMBL_LIB_DIRS), map("$_/modules", grep /tools/, @{$SiteDefs::ENSEMBL_PLUGINS}), @{$SiteDefs::ENSEMBL_EXTRA_INC}, @INC);
$ENV{'PERL5LIB'} = join ':', @INC;

# Fork the process
my $pid = fork();

if (defined $pid) {
  if ($pid == 0) {
    # Child process
    exec($config->{'script'}, @{$config->{'command_args'}}) or die "Couldn't exec: $!";
  } else {
    # Parent process
    # Save the child's PID to pid file using the provided name
    open(PID, ">$config->{'pid_file'}") or die "Couldn't open $config->{'pid_file'} file: $!";
    print PID $pid;
    close PID;
   }
} else {
  die "Fork failed: $!";
}

# DONE
