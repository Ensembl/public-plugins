package EnsEMBL::Web::Object::Healthcheck;

use strict;

use DBI;

use base qw(EnsEMBL::Web::Object);

sub view_type         { return shift->{'_view_type'}; }
sub view_param        { return shift->{'_view_param'}; }
sub view_title        { (my $title = ucfirst ($_[1] || $_[0]->{'_view_type'})) =~ s/_/ /g; return $title; }
sub first_release     { return shift->{'_first_release'}; }
sub current_release   { return shift->{'_curr_release'}; }
sub requested_release { return shift->{'_req_release'}; }
sub compared_release  { return shift->{'_cmp_release'}; }
sub available_views   { return {qw(DBType database_type Database database_name Testcase testcase Species species Team team_responsible)}; }
sub last_session_id   { return shift->_get_session_id('last'); }
sub first_session_id  { return shift->_get_session_id('first'); }
sub requested_reports { return shift->{'_report_ids'}; }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  my $hub   = $self->hub;
  my $sd    = $hub->species_defs;
  
  $self->{'_view_type'}     = $self->available_views->{$self->function};
  $self->{'_view_param'}    = $self->function eq 'Species' && $hub->species ne 'common' ? $hub->species : $hub->param('q');
  $self->{'_first_release'} = $sd->ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE;
  $self->{'_curr_release'}  = $sd->ENSEMBL_VERSION;
  $self->{'_req_release'}   = $hub->param('release') || $self->current_release;
  $self->{'_req_release'}   = 0 if $self->{'_req_release'} < $self->{'_first_release'} || $self->{'_req_release'} > $self->{'_curr_release'};
  $self->{'_cmp_release'}   = $hub->param('release2') || 0;
  $self->{'_cmp_release'}   = 0 if $self->{'_cmp_release'} < $self->{'_first_release'} || $self->{'_cmp_release'} > $self->{'_curr_release'};
  $self->{'_report_ids'}    = $hub->param('rid') ? [ split ',', $hub->param('rid') ] : [];

  return $self unless $self->{'_req_release'};    # for any invalid release
  return $self unless $self->last_session_id;     # if release is valid, but no healthcheck has been performed for the release
  
  my $method = lc 'fetch_for_'.($self->action || $self->default_action);
  
  $self->$method if $self->can($method);

  return $self;
}

sub fetch_for_summary {
  ## Healthcheck summary page
  my $self = shift;

  my $session = $self->rose_manager('Session')->fetch_single($self->requested_release);
  my $groupby = [qw(database_type database_name species testcase team_responsible)];

  if ($session) {
    $self->rose_objects($session);
    $self->rose_objects('reports', $self->rose_manager('Report')->count_failed_for_session({
      'session_id' => $session->session_id,
      'group_by'   => $groupby
    }));

    if (my $compared = $self->compared_release) {
      if ($compared = $self->rose_manager('Session')->fetch_single($compared)) {
        $self->rose_objects('compare_reports', $self->rose_manager('Report')->count_failed_for_session({
          'session_id' => $compared->session_id,
          'group_by'   => $groupby
        }));
      }
    }
  }
}

sub fetch_for_details {
  ## Healthcheck details page
  my $self    = shift;
  
  my $rids    = $self->requested_reports;
  my $type    = $self->view_type;
  my $param   = $self->view_param;
  my $manager = $self->rose_manager('Report');

  if (@$rids) {
    $self->rose_objects('reports', $manager->fetch_by_primary_keys($rids, {
      'with_annotations'  => 1
    }));
  }
  elsif ($type && $param) {
    my $reports = $self->rose_objects('reports', $manager->fetch_for_session({
      'session_id'        => $self->last_session_id,
      'with_annotations'  => 1,
      'query'             => [$type, $param]
    }));
  
    unless (@$reports) {
      $self->rose_objects('control_reports', $manager->fetch_for_session({
        'session_id'      => $self->last_session_id,
        'control_only'    => 1,
        'query'           => [$type, $param]
      }));
    }
  }
  else {
    $self->rose_objects('reports', $manager->count_failed_for_session({
      'session_id' => $self->last_session_id,
      'group_by'   => [ $type ]
    }));
  }
}

sub fetch_for_annotation {
  ## Annotation display page and saving command
  my $self = shift;

  my $report_ids = $self->hub->param('rid');
  $report_ids    = [ split ',', $report_ids ] if $report_ids;
  
  if ($report_ids && @$report_ids) {
    $self->rose_objects($self->rose_manager('Report')->fetch_by_primary_keys($report_ids, {
      'with_objects'          => 'annotation',
      'with_external_objects' => ['annotation.created_by_user', 'annotation.modified_by_user']
    }));
  }
}

sub fetch_for_database {
  ## Database list page
  my $self = shift;

  if (my $last_session_id = $self->last_session_id) {
    my $first_session_id = $self->first_session_id || 0;
    $self->rose_objects('session_reports', $self->rose_manager('Report')->fetch_for_distinct_databases({'last_session_id' => $last_session_id}));
    $self->rose_objects('release_reports', $self->rose_manager('Report')->fetch_for_distinct_databases({'last_session_id' => $last_session_id, 'first_session_id' => $first_session_id}));
  }
}

sub fetch_for_annotationsave {
  ## Saving annotations after editing/adding new
  my $self = shift;
  
  $self->fetch_for_annotation;
}

sub get_database_list {
  ## Gives list of all the current servers and their databases
  ## @return HashRef of 'server name' => {'species name' => [list of database names]}
  my $self = shift;

  $self->{'_hc_mysql_driver'} ||= DBI->install_driver('mysql');
  my $database_list = {};

  for my $server (@$SiteDefs::ENSEMBL_WEBADMIN_DB_SERVERS) {
    my @db_list = $self->{'_hc_mysql_driver'}->func($server->{'host'}, $server->{'port'}, $server->{'user'}, $server->{'pass'}, '_ListDBs');
    for (@db_list) {
      my @db_name = split /_((core|otherfeatures|cdna|variation|funcgen|compara|vega|rnaseq)[a-z]*)_/, $_;
      my $species = $db_name[3] && $self->validate_species(ucfirst $db_name[0]) ? ucfirst $db_name[0] : '';
      my $type    = $species ? $db_name[1] : '';
      $database_list->{$_} = {'species' => $species, 'type' => $type, 'server' => $server->{'host'}};
    }
  }
  return $database_list;
}

sub get_default_list {
  ## Returns an arrayref of default list of testcases, species or databases required to display in the page
  ## @param View type (optional - defaults to current view type)
  ## @param View function (optional - defaults to current hub->function)
  ## @return ArrayRef of strings
  my ($self, $type, $function) = @_;

  $type      ||= $self->view_type;
  $function  ||= $self->function;
  
  if ($function =~ /^Database|Testcase$/) {
    return [] unless $self->first_session_id;
    my $method = lc "fetch_for_distinct_${function}s";
    return [ keys %{{ map {$_->$type => 1} @{$self->rose_manager('Report')->$method({'last_session_id' => $self->last_session_id, 'first_session_id' => $self->first_session_id}) || []} }} ];
  }
  elsif ($function eq 'Species') {
    return [ map {ucfirst $_} @{$self->hub->species_defs->ENSEMBL_DATASETS || []} ];
  }
  elsif ($function eq 'DBType') {
    return [qw(cdna core funcgen otherfeatures production rnaseq variation vega)];
  }
  elsif ($function eq 'Team') {
    return [qw(COMPARA CORE GENEBUILD FUNCGEN RELEASE_COORDINATOR)];
  }
  return [];
}

sub validate_release {
  ## Private helper method
  ## Validates whether or not the given release can have healthchecks
  my ($self, $release) = @_;

  return $release >= $self->first_release && $release <= $self->current_release;
}

sub validate_species {
  ## Validates whether the given string is species or not
  my ($self, $species) = @_;
  
  $self->{'_valid_species'} ||= { map {$_ => 1} @{ $self->hub->species_defs->ENSEMBL_DATASETS || [] } };
  return $self->{'_valid_species'}->{$species} || 0;
}

sub _get_session_id {
  ## gets first or last session id for requested release
  my ($self, $which) = @_;
  exists $self->{"_${which}_session"} and return $self->{"_${which}_session"};
  my $s = $self->rose_manager('Session')->fetch_single($self->requested_release, $which);
  return $s ? ($self->{"_${which}_session"} = $s->session_id) : undef;
}

1;