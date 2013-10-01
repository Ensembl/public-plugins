#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

BEGIN {
  my $code_path = "$Bin/../../..";
  unshift @INC, "$code_path/conf";
  eval {
    require SiteDefs;
  };
  if ($@) {
    print "Can't use SiteDefs - $@\n";
    exit;
  }
  unshift @INC, $_ for @SiteDefs::ENSEMBL_LIB_DIRS;
  unshift @INC, "$code_path/sanger-plugins/tools/modules/"; # TEMP - while tools code in in sanger-plugins
#  unshift @INC, "$code_path/public-plugins/tools/modules/";
  $ENV{'PERL5LIB'} .= join ':', @INC;
}

my $conf_package  = $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE;
my $script_name   = 'init_pipeline.pl';

die "Pipeline configuration package is missing. Please specify ENSEMBL_TOOLS_PIPELINE_PACKAGE in your SiteDefs.\n"  unless $conf_package;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                   unless $ENV{'EHIVE_ROOT_DIR'};
die "Could not find location of the $script_name script.\n"                                                         unless chdir "$ENV{'EHIVE_ROOT_DIR'}/scripts/";

system('perl', $script_name, $conf_package, '-hive_force_init', 1);
#system('perl', $script_name, $conf_package);

1;