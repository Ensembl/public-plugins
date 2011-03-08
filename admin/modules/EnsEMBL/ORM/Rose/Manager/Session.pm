package EnsEMBL::ORM::Rose::Manager::Session;

### NAME: EnsEMBL::ORM::Rose::Manager::Session
### Module to handle multiple Session entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Session objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

__PACKAGE__->make_manager_methods('sessions'); ## Auto-generate query methods: get_sessions, count_sessions, etc

sub object_class { 'EnsEMBL::ORM::Rose::Object::Session' }

sub fetch_last_with_failed_reports {
  ## Fetches last session from the db with all the linked reports and their annotation
  ## @param HashRef with the following keys:
  ##  - query : To be added to the query part of get_objects method
  ##  - with_users: Flag if on, will fetch annotations with their corresponding users
  ##  - include_manual_ok : Flag if on, will include the manual ok annotations - off by default
  my ($self, $params) = @_;

  return unless $params->{'release'};

  my $last_session = $self->fetch_last($params->{'release'});
  return unless $last_session;

  my $query = $params->{'query'} || [];
  push @$query, (
    'db_release',     $params->{'release'},
    'session_id',     $last_session->session_id,
    'report.result',  'PROBLEM',
  );
  unless($params->{'include_manual_ok'}) {
    push @$query, ('or', [
      'report.annotation.action'  => undef,
      '!report.annotation.action' => ['manual_ok', 'manual_ok_this_assembly', 'manual_ok_all_releases', 'manual_ok_this_genebuild', 'healthcheck_bug'],
    ]);
  }

  my $args = {
    with_users    => ['report.annotation.created_by', 'report.annotation.modified_by'],
    with_objects  => ['report', 'report.annotation'],
    query         => $query,
  };

  my $session = $self->get_objects(%$args);

  return $session ? $session->[0] : undef;
}

sub fetch_all_for_release {
  ## fetches all sessions from the db for the given release
  ## @return ArrayRef of EnsEMBL::ORM::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return [] unless $release;
  
  my $objects = $self->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id',
  );
  return $objects;
}

sub fetch_first {
  ## fetches first session from the db for the given release
  ## @return EnsEMBL::ORM::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return undef unless $release;

  my $session = $self->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id ASC',
    limit   => 1
  );
  return @$session ? $session->[0] : undef;
}

sub fetch_last {
  ## fetches last session from the db for the given release
  ## @return EnsEMBL::ORM::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return undef unless $release;

  my $session = $self->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id DESC',
    limit   => 1
  );
  return @$session ? $session->[0] : undef;
}

1;
