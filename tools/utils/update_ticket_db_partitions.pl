#!/usr/local/bin/perl

use strict;

use DBI;
use File::Basename qw(dirname);
use FindBin qw($Bin);
use vars qw($SERVERROOT);

BEGIN {
  my $serverroot = "$Bin/../../..";
  unshift @INC, "$serverroot/conf", $serverroot;
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use EnsEMBL::Web::SpeciesDefs;
my $sd = new EnsEMBL::Web::SpeciesDefs;

my $tools_db = $sd->multidb->{'DATABASE_WEB_TOOLS'};
my $db = $tools_db->{'NAME'};

my $dbh = DBI->connect(
  sprintf('DBI:mysql:database=%s;host=%s;port=%s', $db, $tools_db->{'HOST'}, $tools_db->{'PORT'}),
  $sd->ENSEMBL_USERDB_USER, $sd->ENSEMBL_USERDB_PASS
);

for ('result', 'ticket'){
  my $command = sprintf ("CALL %s.UpdatePartitions('%s', '%s', %s, %s);", $db, $db, $_, 8, 7 );
  $dbh->do($command);

}

$dbh->disconnect;

