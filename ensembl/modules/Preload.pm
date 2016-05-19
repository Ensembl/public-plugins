package Preload;

use strict;
use warnings;

use EnsEMBL::Web::DBSQL::DBConnection;

sub load_axa {
  my $dbc = EnsEMBL::Web::DBSQL::DBConnection->new('Homo_sapiens');
  my $ad  = $dbc->get_DBAdaptor('core', 'Homo_sapiens');
  return unless $ad;
  my $x = $ad->get_AssemblyExceptionFeatureAdaptor->fetch_all;
}

load_axa();

1;
