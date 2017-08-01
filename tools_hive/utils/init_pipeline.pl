#!/usr/local/bin/perl
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


use strict;
use warnings;

use FindBin qw($Bin);

BEGIN { require "$Bin/../../../ensembl-webcode/conf/includeSiteDefs.pl" }

(my $HIVE_SCRIPT, @ARGV) = (sub {

  my $conf_package = $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE;

  die "Pipeline configuration package is missing. Please specify ENSEMBL_TOOLS_PIPELINE_PACKAGE in your SiteDefs.\n"  unless $conf_package;
  die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                   unless $ENV{'EHIVE_ROOT_DIR'};

  my $script_name = sprintf '%s/scripts/init_pipeline.pl', $ENV{'EHIVE_ROOT_DIR'};

  die "Can't require script: $script_name\n" unless -r $script_name;

  my %allowed_args  = map {( "-$_", 1 )} qw(hive_force_init hive_no_init);
  my @args          = map { $allowed_args{$_} ? ($_, 1) : () } @ARGV;

  if (grep { /^[\-]{1,2}(n|dry)$/ } @ARGV) { # dry run
    print join ' ', $script_name, $conf_package, @args, "\n";
    return;
  }

  return ($script_name, $conf_package, @args);
})->();

do $HIVE_SCRIPT if $HIVE_SCRIPT;

1;
