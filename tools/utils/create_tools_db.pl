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

use strict;
use warnings;

use DBI;
use FindBin qw($Bin);
use FileHandle;

BEGIN { require "$Bin/../../../ensembl-webcode/conf/includeSiteDefs.pl" }

require EnsEMBL::Web::SpeciesDefs;

my $sd          = EnsEMBL::Web::SpeciesDefs->new();
my $db          = $sd->tools_db;
my $schema_file = "$Bin/schema_tools_db.sql";

die "ERROR: Schema file does not exist in $Bin.\n" unless -e $schema_file;

my $fh  = FileHandle->new("$schema_file", 'r') or die "ERROR: Can't open file ($schema_file) for reading\n";
my @sql = map { s/^\s+|\s+$//gr || () } split ';', join ' ', map { !m/^#/ && $_ || () } $fh->getlines;

$fh->close;

my $input = '';

while ($input !~ m/^(y|n)$/i) {
  print "Database to be created: $db->{'database'} at $db->{'host'}:$db->{'port'}. Confirm (y/n):";
  $input = <STDIN>;
}

close STDIN;

chomp $input;

die "Not creating $db->{'database'} at $db->{'host'}:$db->{'port'}\n" if $input =~ /n/i;

print "Connecting to $db->{'host'}:$db->{'port'} ...\n";

my $dbh = DBI->connect("dbi:mysql:host=$db->{'host'};port=$db->{'port'}", $db->{'username'}, $db->{'password'}, { 'PrintError' => 0 })
 or die "ERROR: Can't connect tools db host.\nMYSQL ERROR: $DBI::errstr\n";

print "DONE\nCreating database $db->{'database'} ...\n";

if (grep { $_ eq'-f' } @ARGV) {
  $dbh->do("DROP DATABASE IF EXISTS `$db->{'database'}`");
}

if (!$dbh->do("CREATE DATABASE $db->{'database'}")) {
  if ($DBI::errstr =~ /database exists/) {
    die "WARNING: Database $db->{'database'} already exists on $db->{'host'}:$db->{'port'}\nTo force overwrite the database, please provide argument '-f'\n";
  }
  die "ERROR: Can't create database $db->{'database'} on $db->{'host'}:$db->{'port'}\nMYSQL ERROR: $DBI::errstr\n";
}

print "DONE\nCreating tables from latest available schema file ($schema_file) ...\n";

$dbh->do("USE $db->{'database'}")
  or die "ERROR: Can't switch to database $db->{'database'}.\nMYSQL ERROR: $DBI::errstr\n";

for (@sql) {
  $dbh->do($_) or die sprintf "ERROR: Can't execute SQL statement from schema file [%s .. ]\nMYSQL ERROR: $DBI::errstr\n", substr $_, 0, 100;
}

print "DONE\nAdding ticket types\n";

if (my @ticket_types = @{$sd->ENSEMBL_TOOLS_LIST}) {
  my $sth = $dbh->prepare('INSERT INTO `ticket_type` (`ticket_type_name`,`ticket_type_caption`) VALUES (?,?)');
  while (my ($key, $caption) = splice @ticket_types, 0, 2) {
    $sth->execute($key, $caption)
      or die "ERROR: Can't add ticket type names to table 'ticket_type_name'.\nMYSQL ERROR: $DBI::errstr\n";
    print "Added ticket type - $key: $caption\n";
  }
} else {
  print "WARNING: No ticket type names added to table 'ticket_type_name'. Perhaps \$SiteDefs::ENSEMBL_TOOLS_LIST is empty?\n";
}

print "ALL DONE!\n";

1;
