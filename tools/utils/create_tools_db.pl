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

use DBI;
use FindBin qw($Bin);
use List::Util qw(first);
use FileHandle;

my $code_path = "$Bin/../../..";
unshift @INC, "$code_path/ensembl-webcode/conf";
eval {
  require SiteDefs;
};
if ($@) {
  die "ERROR: Can't use SiteDefs - $@\n";
}

unshift @INC, reverse ("$code_path/public-plugins/tools/modules/", @{SiteDefs::ENSEMBL_LIB_DIRS});
$ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;

require EnsEMBL::Web::SpeciesDefs;

my $sd  = EnsEMBL::Web::SpeciesDefs->new();
my $db  = {
  'host'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
  'port'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
  'user'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'} || $sd->DATABASE_WRITE_USER,
  'password'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
  'name'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'}
};

my $schema_file = first { -e } map { sprintf "$Bin/schema_tools_db_$_.sql" } reverse 0 .. $sd->ENSEMBL_VERSION
  or die "ERROR: Schema file does not exist in $Bin.\n";

my $fh  = FileHandle->new("$schema_file", 'r') or die "ERROR: Can't open file ($schema_file) for reading\n";
my @sql = split ';', join ' ', map { !m/^#/ && $_ || () } $fh->getlines;

$fh->close;

my $input = '';

while ($input !~ m/^(y|n)$/i) {
  print "Database to be created: $db->{name} at $db->{'host'}:$db->{'port'}. Confirm (y/n):";
  $input = <STDIN>;
}

close STDIN;

chomp $input;

die "Not creating $db->{name} at $db->{'host'}:$db->{'port'}\n" if $input =~ /n/i;

if (!grep({ $_ eq'-f' } @ARGV) && grep({ $db->{'name'} eq $_ =~ s/^.+:([^:]+)$/$1/r } DBI->data_sources("mysql", $db))) {
  die "WARNING: Database $db->{'name'} already exists on $db->{'host'}:$db->{'port'}\nTo force overwrite the database, please provide argument '-f'\n";
}

print "Connecting to $db->{'host'}:$db->{'port'} ...\n";

my $dbh = DBI->connect("dbi:mysql:host=$db->{'host'};port=$db->{'port'}", $db->{'user'}, $db->{'password'}, { 'PrintError' => 0 })
 or die "ERROR: Can't connect tools db host.\nMYSQL ERROR: $DBI::errstr\n";

print "DONE\nCreating database $db->{name} ...\n";

$dbh->do("DROP DATABASE IF EXISTS `$db->{'name'}`");
$dbh->do("CREATE DATABASE $db->{'name'}")
  or die "ERROR: Can't create database $db->{name} on $db->{'host'}:$db->{'port'}\nMYSQL ERROR: $DBI::errstr\n";

print "DONE\nCreating tables from latest available schema file ($schema_file) ...\n";

$dbh->do("USE $db->{'name'}")
  or die "ERROR: Can't switch to database $db->{name}.\nMYSQL ERROR: $DBI::errstr\n";

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
