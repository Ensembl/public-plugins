package EnsEMBL::ORM::Rose::Manager::Report;

### NAME: EnsEMBL::ORM::Rose::Manager::Report
### Static Module to handle multiple Report entries and run some data mining queries

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Report objects
### Containes some extra methods on top of those given by Rose::DB::Object::Manager and EnsEMBL::ORM::Rose::Manager

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

__PACKAGE__->make_manager_methods('reports'); ## Auto-generate query methods: get_reports, count_reports, etc

sub object_class { 'EnsEMBL::ORM::Rose::Object::Report' }

sub fetch_last_for_session {
  ## Fetches last report from the db for given session
  ## @param  $session_id - session id for which result is required
  ## @return EnsEMBL::ORM::Rose::Object::Report object
  my ($self, $session_id) = @_;
  return $self->_fetch_single($session_id, 'last');
}

sub fetch_first_for_session {
  ## Fetches first report from the db for given session
  ## @param  $session_id - session id for which result is required
  ## @return EnsEMBL::ORM::Rose::Object::Report object
  my ($self, $session_id) = @_;
  return $self->_fetch_single($session_id, 'first');
}

sub fetch_for_distinct_databases {
  ## Fetches one report for each db for a given session/release - basically you get a list of database which were healthchecked in the given session/release
  ## @param HashRef with keys:
  ##  - session_id  Session id of the requested session
  ## @return ArrayRef of EnsEMBL::ORM::Rose::Object::Report objects if found any
  return shift->_fetch_for_distinct(shift, 'database_name');
}

sub fetch_for_distinct_testcases {
  ## Fetches one report for each testcase - basically you get a list of all testcases
  ## @param HashRef with keys:
  ##  - session_id  Session id of the requested session
  ## @return ArrayRef of EnsEMBL::ORM::Rose::Object::Report objects if found any
  return shift->_fetch_for_distinct(shift, 'testcase');
}

sub _fetch_single {
  my ($self, $session_id, $first_or_last) = @_;
  my $reports = $self->get_reports(
    query     => ['last_session_id' => "$session_id", '!timestamp' => undef],
    sort_by   => 'timestamp '.(defined $first_or_last && $first_or_last eq 'last' ? 'DESC' : 'ASC'),
    limit     => 1
  );
  return $reports->[0];
}

sub _fetch_for_distinct {
  my ($self, $params, $group_by) = @_;
  return [] unless $params->{'session_id'};
  
  my $query = $params->{'include_all'} ? ['last_session_id' => {'ge' => $params->{'session_id'}}] : ['last_session_id' => $params->{'session_id'}];
  
  my $objects = $self->get_reports(
    group_by  => $group_by,
    query     => $query,
  );
  return $objects;
}

1;