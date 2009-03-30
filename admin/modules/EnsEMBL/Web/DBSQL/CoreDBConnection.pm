package EnsEMBL::Web::DBSQL::CoreDBConnection;

### Writeable connection to a species database, separate from normal API

use strict;
use warnings;

sub import {
  my ($class, $species_defs) = @_;
  my $caller = caller;
  my $dsn = join(':',
    'dbi',
    'mysql',
    $species_defs->databases->{'ENSEMBL_DB'}{'NAME'},
    $species_defs->ENSEMBL_HOST,
    $species_defs->ENSEMBL_HOST_PORT,
  );
  $caller->connection(
    $dsn,
    $species_defs->DATABASE_WRITE_USER,
    $species_defs->DATABASE_WRITE_PASS,
    {
      RaiseError => 1,
      PrintError => 1,
      AutoCommit => 1,
    }
  ) || die "Can not connect to $dsn";

}

1;
