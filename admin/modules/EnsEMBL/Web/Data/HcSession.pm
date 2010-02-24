package EnsEMBL::Web::Data::HcSession;

use strict;
use warnings;
use Data::Dumper;
use base qw(EnsEMBL::Web::Data);
use EnsEMBL::Web::DBSQL::HcDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('session');
__PACKAGE__->set_primary_key('session_id');

__PACKAGE__->add_queriable_fields(
  db_release  => 'int',
  content     => 'varchar(255)',
  declaration => 'varchar(255)',
);

1;
