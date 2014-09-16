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


use strict;
use warnings;

use FindBin qw($Bin);

BEGIN {
  my $code_path = "$Bin/../../..";
  unshift @INC, "$code_path/ensembl-webcode/conf";
  eval {
    require SiteDefs;
  };
  if ($@) {
    print "Can't use SiteDefs - $@\n";
    exit;
  }
  unshift @INC, "$code_path/public-plugins/$_/modules/" for qw(tools tools_hive);
  unshift @INC, $_ for @SiteDefs::ENSEMBL_LIB_DIRS;
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

my $conf_package  = $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE;
my $script_name   = 'init_pipeline.pl';

die "Pipeline configuration package is missing. Please specify ENSEMBL_TOOLS_PIPELINE_PACKAGE in your SiteDefs.\n"  unless $conf_package;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                   unless $ENV{'EHIVE_ROOT_DIR'};
die "Could not find location of the $script_name script.\n"                                                         unless chdir "$ENV{'EHIVE_ROOT_DIR'}/scripts/";

#system('perl', $script_name, $conf_package, '-hive_force_init', 1);
system('perl', $script_name, $conf_package);

1;
