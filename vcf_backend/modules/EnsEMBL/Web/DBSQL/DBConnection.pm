package EnsEMBL::Web::DBSQL::DBConnection;

use strict;
use warnings;

register_cleaner('Bio::EnsEMBL::Variation::DBSQL::DBAdaptor',sub {
  my ($vdb,$sd) = @_;

  my $c = $sd->ENSEMBL_VCF_COLLECTIONS;
  if($c && $vdb->can('use_vcf')) {
    $vdb->vcf_config_file($c->{'CONFIG'});
    $vdb->vcf_root_dir($sd->DATAFILE_BASE_PATH);
    $vdb->use_vcf($c->{'ENABLED'});
  }
});

1;
