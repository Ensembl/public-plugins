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
use DBI;

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
  unshift @INC, "$code_path/sanger-plugins/tools/modules/"; # TEMP - while tools code in in sanger-plugins
#  unshift @INC, "$code_path/public-plugins/tools/modules/";
  unshift @INC, $_ for @SiteDefs::ENSEMBL_LIB_DIRS;
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'}, @INC;
  
  require EnsEMBL::Web::SpeciesDefs;
}

my $sd = EnsEMBL::Web::SpeciesDefs->new();
my $db = {
  '-host'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
  '-port'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PORT'}, 
  '-user'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'USER'} || $sd->DATABASE_WRITE_USER,
  '-pass'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
  '-dbname' =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'NAME'},
};

my $command     = "-url mysql://$db->{'-user'}:$db->{'-pass'}\@$db->{'-host'}:$db->{'-port'}/$db->{'-dbname'}";
my $script_name = 'beekeeper.pl';
my $dbh         = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $db->{'-dbname'}, $db->{'-host'}, $db->{'-port'}), $db->{'-user'}, $db->{'-pass'}, { 'PrintError' => 0 });

die "Database connection to hive db could not be created. Please make sure the pipiline is initialised.\nError: $DBI::errstr\n"   unless $dbh;
die "ENV variable EHIVE_ROOT_DIR is not set. Please set it to the location containg HIVE code.\n"                                 unless $ENV{'EHIVE_ROOT_DIR'};
die "Could not find location of the $script_name script.\n"                                                                       unless chdir "$ENV{'EHIVE_ROOT_DIR'}/scripts/";

system(join ' ', 'perl', $script_name, $command, @ARGV);

1;
