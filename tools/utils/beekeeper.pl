#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
use DBI;

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
  unshift @INC, "$code_path/sanger-plugins/tools/modules/"; # TEMP
#  unshift @INC, "$code_path/public-plugins/tools/modules/";
  $ENV{'PERL5LIB'} .= join ':', @INC;
  
  require EnsEMBL::Web::SpeciesDefs;
}

my $sd = EnsEMBL::Web::SpeciesDefs->new();
my $db = {
  '-host'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
  '-port'   =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PORT'}, 
  '-user'   =>  $sd->DATABASE_WRITE_USER,
  '-pass'   =>  $sd->DATABASE_WRITE_PASS,
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