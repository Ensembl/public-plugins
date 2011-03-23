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
sub available_views   { return {'DBType' => 'database_type', 'Database' => 'database_name', 'Testcase' => 'testcase', 'Species' => 'species'}; }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  
  $self->{'_view_type'}     = $self->available_views->{$self->function};
  $self->{'_view_param'}    = $self->function eq 'Species' ? ($self->hub->species eq 'common' ? '' : $self->hub->species) : $self->hub->param('q');
  $self->{'_first_release'} = $SiteDefs::ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE;
  $self->{'_curr_release'}  = $self->hub->species_defs->ENSEMBL_VERSION;
  $self->{'_req_release'}   = $self->hub->param('release') || $self->current_release;
  $self->{'_req_release'}   = 0 if $self->{'_req_release'} < $self->{'_first_release'} || $self->{'_req_release'} > $self->{'_curr_release'};
  $self->{'_cmp_release'}   = $self->hub->param('release2') || 0;
  $self->{'_cmp_release'}   = 0 if $self->{'_cmp_release'} < $self->{'_first_release'} || $self->{'_cmp_release'} > $self->{'_curr_release'};

  return $self unless $self->{'_req_release'};
  
  my $method = lc 'fetch_for_'.$self->action;
  
  $self->$method if $self->can($method);

  return $self;
}

sub fetch_for_summary {
  ## Healthcheck summary page
  my $self = shift;

  my $session = $self->rose_manager('Session')->fetch_last_with_failed_reports({'release' => $self->requested_release});
  if ($session) {
    $self->rose_objects($session);
    $self->rose_objects('compare_session', $self->rose_manager('Session')->fetch_last_with_failed_reports({'release' => $self->compared_release})) if $self->compared_release;
    $self->rose_objects('reports', [
      $self->rose_manager('Report')->fetch_first_for_session($session->session_id),
      $self->rose_manager('Report')->fetch_last_for_session ($session->session_id)
    ]);
  }
}

sub fetch_for_details {
  ## Healthcheck details page
  my $self = shift;

  my $query = {
    'release'           => $self->requested_release,
    'with_users'        => $self->view_type && $self->view_param ? 1 : 0,
    'include_manual_ok' => $self->view_type && $self->view_param ? 1 : 0
  };
  $query->{'query'} = ['report.'.$self->view_type, $self->view_param] if $self->view_type && $self->view_param;

  $self->rose_objects($self->rose_manager('Session')->fetch_last_with_failed_reports($query));
}

sub fetch_for_annotation {
  ## Annotation display page and saving command
  my $self = shift;

  my $report_ids = $self->hub->param('rid');
  $report_ids    = [ split ',', $report_ids ] if $report_ids;
  
  if ($report_ids && @$report_ids) {
    $self->rose_objects($self->rose_manager('Report')->fetch_by_primary_keys($report_ids, {
      'with_objects' => 'annotation',
      'with_users'   => ['annotation.created_by', 'annotation.modified_by'],
      'query'        => ['result' => 'PROBLEM']
    }));
  }
}

sub fetch_for_database {
  ## Database list page
  my $self = shift;

  my $session_manager = $self->rose_manager('Session');
  my $last_session    = $session_manager->fetch_last($self->current_release);
  my $last_session_id = $last_session ? $last_session->session_id || 0 : 0;

  if ($last_session_id) {

    my $first_session    = $session_manager->fetch_first($self->current_release);
    my $first_session_id = $first_session ? $first_session->session_id || 0 : 0;
    my $reports_manager  = $self->rose_manager('Report');
    $self->rose_objects('session_reports', $reports_manager->fetch_for_distinct_databases({'session_id' => $last_session_id}));
    $self->rose_objects('release_reports', $reports_manager->fetch_for_distinct_databases({'session_id' => $first_session_id, 'include_all' => 1}));
  }
}

sub fetch_for_userdirectory {
  ## User directory
  my $self = shift;
  $self->rose_objects($self->rose_manager('Group')->fetch_with_members($self->hub->species_defs->ENSEMBL_WEBADMIN_ID, 1));
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
    $database_list->{$server->{'host'}} = {};
    my @db_list = $self->{'_hc_mysql_driver'}->func($server->{'host'}, $server->{'port'}, $server->{'user'}, $server->{'pass'}, '_ListDBs');
    for (@db_list) {
      my $species = '2others'; #'2' prefixed for sorting - '2' keeps 'others' at the end instead of considering it alphabetically
      if ($_ =~ /_core|_otherfeatures|_cdna|_variation|_funcgen|_compara|_vega/) {
        $_ =~ /^([a-z]+_[a-z]+)/; #get species
        $species = '1'.$1 if $self->validate_species(ucfirst $1); #'1' prefixed for sorting -  keeps it always above 'others'
      }
      $database_list->{$server->{'host'}}{$species} ||= [];
      push @{$database_list->{$server->{'host'}}{$species}}, $_;
    }
  }
  return $database_list;
}

sub get_default_list {
  ## Returns an arrayref of default list of testcases, species or databases required to display in the page
  ## @param View type (optional - defaults to current view type)
  ## @param View function (optional - defaults to current hub->function)
  my ($self, $type, $function) = @_;

  $type      ||= $self->view_type;
  $function  ||= $self->function;
  
  if ($function =~ /^Database|Testcase$/) {

    $self->{'__first_session'} ||= $self->rose_manager('Session')->fetch_first($self->requested_release);#saves for next query if any
    return [] unless $self->{'__first_session'};

    my $method = lc "fetch_for_distinct_${function}s";
    return [ keys %{{ map {$_->$type => 1} @{$self->rose_manager('Report')->$method({'session_id' => $self->{'__first_session'}->session_id, 'include_all' => 1}) || []} }} ];
  }
  elsif ($function eq 'Species') {
    return $self->hub->species_defs->ENSEMBL_DATASETS || [];
  }
  elsif ($function eq 'DBType') {
    return [qw(cdna core funcgen otherfeatures production variation vega)];
  }
  warn "No type or function found.";
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

1;