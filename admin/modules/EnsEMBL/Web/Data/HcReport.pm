package EnsEMBL::Web::Data::HcReport;

use strict;
use warnings;
use base qw(EnsEMBL::Web::Data);
use EnsEMBL::Web::DBSQL::HcDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('report');
__PACKAGE__->set_primary_key('report_id');

__PACKAGE__->add_queriable_fields(
  database_name     => 'varchar(255)',
  species           => 'varchar(255)',
  database_type     => 'varchar(255)',
  database_name     => 'varchar(255)',
  testcase          => 'varchar(255)',
  text              => 'varchar(255)',
  team_responsible  => 'varchar(255)',
  result            => "enum('PROBLEM','CORRECT','WARNING','INFO')",
  timestamp         => 'datetime',
  created           => 'datetime',
);

__PACKAGE__->might_have(annotation     => 'EnsEMBL::Web::Data::HcAnnotation' => qw/action comment person created_by modified_by/);
__PACKAGE__->has_a(first_session       => 'EnsEMBL::Web::Data::HcSession');
__PACKAGE__->has_a(last_session        => 'EnsEMBL::Web::Data::HcSession');

__PACKAGE__->set_sql(failed_by_species => qq(
  SELECT COUNT(*)
  FROM
      __TABLE(=r)__
      LEFT JOIN
      __TABLE(EnsEMBL::Web::Data::HcAnnotation=a)__ ON r.report_id = a.report_id
  WHERE
      r.result='PROBLEM' AND 
      (a.action !='manual_ok_all_releases' AND a.action !='healthcheck_bug' 
        AND a.action !='manual_ok' AND a.action !='manual_ok_this_assembly'
        OR isnull(a.action) )
      %s                   -- where
));

__PACKAGE__->set_sql('database_names' => 
        qq/SELECT DISTINCT(database_name) FROM __TABLE__ 
            WHERE %s ORDER BY database_name /
);

__PACKAGE__->set_sql('count_tests' =>
        qq/SELECT COUNT(DISTINCT(testcase)) FROM report WHERE text NOT LIKE '#%' AND %s /
);

__PACKAGE__->set_sql('failed_tests' => qq/
      SELECT DISTINCT(testcase), r.result 
      FROM 
        __TABLE(=r)__
        LEFT JOIN
        __TABLE(EnsEMBL::Web::Data::HcAnnotation=a)__ ON r.report_id = a.report_id
      WHERE r.text NOT LIKE '#%' AND %s
      ORDER BY r.testcase
  /
);

__PACKAGE__->set_sql('reports' => qq/
      SELECT r.* 
      FROM 
        __TABLE(=r)__
        LEFT JOIN
        __TABLE(EnsEMBL::Web::Data::HcAnnotation=a)__ ON r.report_id = a.report_id
      WHERE r.text NOT LIKE '#%' AND %s
      ORDER BY r.testcase, r.result
  /
);

sub failed_by_species {
  my ($self, $session_type, @args) = @_;

  $session_type .= '_session_id';

  my $where = " AND species = ? AND $session_type = ?";

  return $self->sql_failed_by_species($where)->select_val(@args);
}

sub database_names {
  my ($self, @args) = @_;
  my $dbs = [];

  my $where = ' species = ? AND last_session_id = ?';
  my $sth = $self->sql_database_names($where);
  $sth->execute(@args);
  while (my $row = $sth->fetchrow_arrayref) {
    push @$dbs, $row->[0];
  }
  return $dbs;
}

sub count_tests {
  my ($self, @args) = @_;
  my $where = ' database_name = ? AND last_session_id = ?';
  if ($args[2]) {
    $where .= ' AND result IN (?)';
  }
  return $self->sql_count_tests($where)->select_val(@args);
}

sub failed_tests {
  my ($self, $database, $session_id, $type, $tc_action, $unannotated) = @_;
  my $result = join "', '", @$type if $type;
  my $action = join "', '", @$tc_action if $tc_action;

  my $where = " database_name = ? AND last_session_id = ? AND r.result IN ('$result')";
  my $isnull = $unannotated  ? "or isnull(a.action)" : '';
  if ($tc_action) {
    $where .= qq(AND (a.action IN ('$action') $isnull ));
  }

  my $results = [];
  my $sth = $self->sql_failed_tests($where);
  $sth->execute($database, $session_id);
  while (my $row = $sth->fetchrow_arrayref) {
    push @$results, $row;
  }
  return $results;
}

sub reports {
  my ($self, $database, $session_id, $type, $tc_action, $unannotated) = @_;
  my $result = join "', '", @$type if $type;
  my $action = join "', '", @$tc_action if $tc_action;

  my $where = ' database_name = ? AND last_session_id = ? ';
  if ($result) {
    $where .= " AND r.result IN ('$result')";
  }
  my $isnull = $unannotated  ? 'or isnull(a.action)' : '';
  if ($tc_action) {
    $where .= qq(AND (a.action IN ('$action') $isnull ));
  }
  my $sth = $self->sql_reports($where);
  $sth->execute($database, $session_id);

  my @results = $self->sth_to_objects($sth);
  return @results;
}

1;
