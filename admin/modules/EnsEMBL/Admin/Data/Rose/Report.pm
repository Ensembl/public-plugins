package EnsEMBL::Admin::Data::Rose::Report;

### NAME: EnsEMBL::Admin::Data::Rose::Report;
### Wrapper for one or more EnsEMBL::Admin::Rose::Object::Report objects

### STATUS: Stable

use strict;

use EnsEMBL::Admin::Rose::Manager::Report;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  ## @overrides
  ## sets primary key for the object as in the database table
  ## called by Rose->_init
  my $self = shift;
  $self->{'_primary_keys'} = [qw(report_id)];
}

sub set_classes {
  ## @overrides
  ## links the corresponding Rose Object and Rose Object Manager classes
  ## called by Rose->_init
  my $self = shift;
  $self->{'_object_class'}  = 'EnsEMBL::Admin::Rose::Object::Report';
  $self->{'_manager_class'} = 'EnsEMBL::Admin::Rose::Manager::Report';
}

### Following methods help for data mining for fetching data (each with different criteria) from the db table(s)

sub fetch_by_id {
  ## @overrides
  ## fetches a report from the db with give report id
  ## #params $report_id ArrayRef of id(s) of the requested report(s)
  ## @return ArrayRef to an EnsEMBL::Admin::Rose::Object::Report object
  my ($self, $report_id, $failed_only) = @_;
  return undef unless $report_id;
  
  $failed_only = $failed_only ? {'result' => 'PROBLEM'} : {};
  
  my $reports = $self->manager_class->get_reports(
    with_objects    => 'annotation',
    query => [
      'report_id'   => $report_id,
      %$failed_only
    ]
  );
  return $reports;
}

sub fetch_last_for_session {
  ## fetches last report from the db for given session
  ## @params $session_id - session id for which result is required
  ## @return EnsEMBL::Admin::Rose::Object::Report object
  my ($self, $session_id) = @_;
  return $self->_fetch_single($session_id, 'last');
}

sub fetch_first_for_session {
  ## fetches first report from the db for given session
  ## @params $session_id - session id for which result is required
  ## @return EnsEMBL::Admin::Rose::Object::Report object
  my ($self, $session_id) = @_;
  return $self->_fetch_single($session_id, 'first');
}

sub fetch_failed_for_session {
  ## fetches all failed reports from the db for single/or combination of given species, db or testcase) and given session
  ## @params $session_id id of the requested session
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Report objects if found any
  ## IMPORTANT - while calling this method, make sure (keys %$filter) is a subset of database column names
  my ($self, $session_id, $filter) = @_;

  $filter = {'result' => 'PROBLEM', %$filter };

  return $self->fetch_for_session($session_id, $filter);
}

sub fetch_for_session {
  ## fetches all reports from the db for single/or combination of given species, db or testcase) and given session
  ## @params $session_id id of the requested session
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Report objects if found any
  ## IMPORTANT - while calling this method, make sure (keys %$filter) is a subset of database column names
  my ($self, $session_id, $filter) = @_;
  return undef unless $session_id && scalar $filter;

  my $objects = $self->manager_class->get_reports(
    with_objects                => 'annotation',
    query => [
      'last_session_id'         => $session_id,
      %$filter
    ]
  );
  return $objects;
}

sub fetch_all_failed_for_session {
  ## fetches all reports from the db for the current species and given session
  ## @params $session_id id of the requested session
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Report objects if found any
  my ($self, $session_id) = @_;
  return undef unless $session_id;

  my $reports = $self->manager_class->get_reports(
    with_objects                => 'annotation',
    query                       =>
    [
      and                       =>
      [
        or                      =>
        [
          'annotation.action'   => undef,
          '!annotation.action'  => ['manual_ok', 'manual_ok_this_assembly', 'manual_ok_all_releases', 'healthcheck_bug'],
        ],
        'last_session_id'       => "$session_id",
        'result'                => 'PROBLEM'
      ],
    ],
  );
  return $reports;
}

sub fetch_for_distinct_databases {
  ## fetches one reports for each db for a given session/release - basically you get a list of database which were healthchecked in the given session/release
  ## @params $session_id id of the requested session
  ## @params $release requested release
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Report objects if found any
  my ($self, $session_id, $release) = @_;
  return undef unless $session_id || $release;

  my $query = defined $session_id ? [ 'last_session_id' => $session_id ] : [ 'database_name' => { 'like' => qq(%\_$release%) } ];

  my $objects = $self->manager_class->get_reports(
    query     => $query,
    group_by  => 'database_name'
  );
  return $objects;
}

sub _fetch_single {
  my ($self, $session_id, $first_or_last) = @_;
  my $reports = $self->manager_class->get_reports(
    query     => ['last_session_id' => "$session_id", '!timestamp' => undef],
    sort_by   => 'timestamp '.(defined $first_or_last && $first_or_last eq 'last' ? 'DESC' : 'ASC'),
    limit     => 1
  );
  return $reports->[0];
}

1;