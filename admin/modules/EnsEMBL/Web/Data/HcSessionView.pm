package EnsEMBL::Web::Data::HcSessionView;

use strict;
use warnings;
use Data::Dumper;
use base qw(EnsEMBL::Web::Data);
use EnsEMBL::Web::DBSQL::HcDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('session_v');
__PACKAGE__->set_primary_key('session_id');

__PACKAGE__->add_queriable_fields(
  db_release  => 'int',
  host        => 'varchar(255)',
  config      => 'varchar(255)',
  start_time  => 'datetime',
  end_time    => 'datetime',
  duration    => 'time',
);

__PACKAGE__->set_sql(max_for_release => qq(
    SELECT MAX(n.session_id) FROM __TABLE(=n)__
    WHERE end_time IS NOT NULL
    AND %s
));

sub max_for_release {
  my ($self, $release) = @_;
  return undef unless $release;

  my $where = 'db_release = ?';

  return $self->sql_max_for_release($where)->select_val($release);
}


1;
