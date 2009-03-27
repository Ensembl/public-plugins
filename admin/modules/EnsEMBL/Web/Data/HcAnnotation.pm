package EnsEMBL::Web::Data::HcAnnotation;

use strict;
use warnings;
use base qw(EnsEMBL::Web::Data::Trackable);
use EnsEMBL::Web::DBSQL::HcDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('annotation');
__PACKAGE__->set_primary_key('annotation_id');

__PACKAGE__->add_queriable_fields(
  person      => 'varchar(255)',
  action      => "enum('manual_ok','under_review','note','healthcheck_bug','manual_ok_all_releases','manual_ok_this_assembly')",
  comment     => 'varchar(255)',
);

__PACKAGE__->has_a(report       => 'EnsEMBL::Web::Data::HcReport');




1;
