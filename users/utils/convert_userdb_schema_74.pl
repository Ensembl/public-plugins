#!/usr/local/bin/perl
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
use Getopt::Long qw(GetOptions);


# Help
sub usage {
  print("This script copies the data from old user db schema to the newer schema to make it compatible with this plugin.\n");
  print("\t-host=<database host>    \tServer address where database is hosted.\n");
  print("\t-dbname=<database name>  \tName of the existing user database\n");
  print("\t-user=<User name>        \tUser name for connecting to the db\n");
  print("\t-pass=<password>         \tPassword (default to null)\n");
  print("\t-port=<port>             \tDatbaase port (defaults to 3306)\n");
  print("\t--help                   \tDisplays this info and exits (optional)\n" );
  exit;
}

# Get arguments
my ($host, $dbname, $username, $pass);
my $port = 3306;
GetOptions(
  'host=s'    => \$host,
  'dbname=s'  => \$dbname,
  'user=s'    => \$username,
  'pass=s'    => \$pass,
  'port=i'    => \$port,
  'help'      => \&usage
);

# Validate arguments
print "Argument(s) missing.\n" and usage if (!$host || !$dbname || !$username);

# Connect to db
my $dbh = DBI->connect(sprintf('DBI:mysql:database=%s;host=%s;port=%s', $dbname, $host, $port), $username, $pass || '') or die 'Could not connect to the database';

$dbh->do("alter table configuration_details modify column record_type enum('session','user','group') NOT NULL DEFAULT 'session'");
$dbh->do("alter table webgroup modify column type enum('open','restricted','private','hidden') DEFAULT 'restricted'");

$dbh->disconnect;

print "\nDONE\n";