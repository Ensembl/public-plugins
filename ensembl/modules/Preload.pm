package Preload;

use strict;
use warnings;

use EnsEMBL::Web::DBSQL::DBConnection;

sub load_axa {
  my $ad = EnsEMBL::Web::DBSQL::DBConnection->new('Homo_sapiens');
  my $x = $ad->get_DBAdaptor('core', 'Homo_sapiens')->get_AssemblyExceptionFeatureAdaptor->fetch_all;
}

load_axa();
