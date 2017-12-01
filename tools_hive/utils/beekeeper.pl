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

### DO NOT RUN THIS SCRIPT INDEPENDENTLY
### THIS IS RUN VIA beekeeper_manager.pl

use strict;
use warnings;
no warnings qw(once);

# get passed config hash
my ($config) = @ARGV;
$config = eval($config);
die "Could not parse command line arguments:\n$@" if $@;

# save pid to pid file as provided
open(PID, ">$config->{'pid_file'}") or die "Couldn't open $config->{'pid_file'} file: $!";
print PID $$;
close PID;

# require SiteDefs and LoadPlugins
require $config->{'include_script'};

my %seen;
@INC = grep -d && !$seen{$_} && ($seen{$_} = 1), (map("$_/modules", grep /tools/, @{$SiteDefs::ENSEMBL_PLUGINS}), @SiteDefs::ENSEMBL_LIB_DIRS, @{$SiteDefs::ENSEMBL_EXTRA_INC}, @INC);
$ENV{'PERL5LIB'} = join ':', @INC;

# run the script with correct paths
@ARGV = @{$config->{'command_args'}};
do $config->{'script'};
