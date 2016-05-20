package Preload;

use strict;
use warnings;

### Preloads human assembly exceptions
### If your setup doesn't have current human db, but you need to use 'ensembl' plugin, declare an empty load_axa in your plugin's Preload module

use EnsEMBL::Web::DBSQL::DBConnection;

use previous qw(import);

sub import {
  PREV::import();
  load_axa();
}

sub load_axa {
  eval {
    EnsEMBL::Web::DBSQL::DBConnection->new('Homo_sapiens')->get_DBAdaptor('core', 'Homo_sapiens')->get_AssemblyExceptionFeatureAdaptor->fetch_all;
  };

  if ($@) {
    warn "Preload warning: Could not preload Homo_sapiens AssemblyExceptions\n";
  }
}

1;
