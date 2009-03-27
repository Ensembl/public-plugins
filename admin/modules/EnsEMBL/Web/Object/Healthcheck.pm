package EnsEMBL::Web::Object::Healthcheck;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Object);
use EnsEMBL::Web::Data::HcSessionView;
use EnsEMBL::Web::Data::HcReport;

sub caption       { return undef; }
sub short_caption { return ''; }
sub counts        { return undef; }
sub can_export    { return 0; }


sub release                   :lvalue { $_[0]->Obj->{'release'};                  }
sub max_session_for_release   :lvalue { $_[0]->Obj->{'max_session_for_release'};  }

#-----------------------------------------------------------------------------

sub session_info { 

  ### Munges the information returned from the session_v view 
  ### for use in webpages

  my ($self, $session) = @_;
  $session ||= $self->max_session_for_release;
  my $session_view = EnsEMBL::Web::Data::HcSessionView->new($session);
  my $session_info;

  $session_info->{'db_release'} = $session_view->db_release;
  $session_info->{'start_time'} = $session_view->start_time;
  $session_info->{'end_time'}   = $session_view->end_time;
  $session_info->{'duration'}   = $session_view->duration;

  ## parse config to produce required data
  my @configs = split(',', $session_view->config);
  $session_info->{'db_names'} = [];
  my %groups;
  foreach my $config (@configs) {
    my ($db_regex, $group) = split(':', $config);
    push @{$session_info->{'db_names'}}, $db_regex;
    $groups{$group}++;
  }
  my @groups = keys %groups;
  $session_info->{'groups'} = \@groups;

  return $session_info;
}

sub number_failed_by_species { 
  my ($self, $species, $session_type, $release) = @_;
  my $session_id = EnsEMBL::Web::Data::HcSessionView->max_for_release($release);
  return unless $session_id;
  return EnsEMBL::Web::Data::HcReport->failed_by_species($session_type, $species, $session_id);
}

sub database_names {
  my $self = shift;
  return EnsEMBL::Web::Data::HcReport->database_names($self->species, $self->max_session_for_release);
}

sub count_tests {
  my ($self, $database, $type) = @_;
  my @args = ($database, $self->max_session_for_release);
  push @args, $type if $type;
  return EnsEMBL::Web::Data::HcReport->count_tests(@args);
}

sub failed_tests {
  my ($self, $database) = @_;
  my $types = $self->result_types;
  my ($tc_action, $unannotated) = $self->_get_vc_params;
  return EnsEMBL::Web::Data::HcReport->failed_tests($database, $self->max_session_for_release, $types, $tc_action, $unannotated);
}

sub reports {
  my ($self, $database) = @_;
  my $types = $self->result_types;
  my ($tc_action, $unannotated) = $self->_get_vc_params;
  return EnsEMBL::Web::Data::HcReport->reports($database, $self->max_session_for_release, $types, $tc_action, $unannotated);
}

sub result_types {
  my $self = shift;
  my $vc = $self->get_viewconfig;
  my @types = ('INFO', 'WARNING', 'PROBLEM');
  my $result_types = [];
  foreach my $type (@types) {
    my $T = $vc->get('result_'.$type);
    push @$result_types, $type if $T =~ /on|yes/;
  }
  return $result_types;
}

sub _get_vc_params {
  my $self = shift;
  my $vc = $self->get_viewconfig;
  my @actions = ('note', 'under_review', 'healthcheck_bug', 'manual_ok', 'manual_ok_this_assembly', 'manual_ok_all_releases');
  my $tc_action = [];
  foreach my $action (@actions) {
    my $T = $vc->get('tc_'.$action);
    push @$tc_action, $action if $T =~ /on|yes/;
  }
  my $unannotated = $vc->get('unannotated') eq 'no' ? 0 : 1;
  return ($tc_action, $unannotated);
}

1;
