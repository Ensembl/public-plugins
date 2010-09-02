package EnsEMBL::Web::Configuration::Healthcheck;

use strict;
use base qw( EnsEMBL::Web::Configuration );
use EnsEMBL::Web::RegObj;

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Summary';
}

sub global_context { return undef; }
sub ajax_content   { return undef; }
sub local_context  { return $_[0]->_local_context; }
sub local_tools    { return $_[0]->_local_tools; }
sub context_panel  { return undef; }
sub content_panel  { return $_[0]->_content_panel;  }

sub populate_tree {
  my $self = shift;
  #my $hub = $self->model->hub;
  my $species_defs = $self->object->species_defs;
  my $release_id = $species_defs->ENSEMBL_VERSION;

  $self->create_node( 'Summary', "Healthcheck Summary - Release $release_id",
    [qw(
      session_info    EnsEMBL::Admin::Component::Healthcheck::SessionInfo
      failure_summary EnsEMBL::Admin::Component::Healthcheck::FailureSummary
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details', "Healthcheck Details",
    [qw(
      results         EnsEMBL::Admin::Component::Healthcheck::DetailsSummary
      species_failure EnsEMBL::Admin::Component::Healthcheck::FailureReports
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'Databases', "Databases",
    [qw(
      databases EnsEMBL::Web::Component::Healthcheck::Databases
    )], 
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'UserDirectory', "User Directory",
    [qw(
      directory EnsEMBL::Admin::Component::Healthcheck::UserDirectory
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );

  $self->create_node( 'Annotation', '', [],
      { 'command' => 'EnsEMBL::Admin::Command::Healthcheck::Interface::Annotation',
         'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'MultiAnnotate', '',
    [qw(multi_annotate  EnsEMBL::Admin::Component::Healthcheck::MultiAnnotate)],
      {'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'MultiSave', '', [],
      { 'command' => 'EnsEMBL::Admin::Command::Healthcheck::MultiSave',
         'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );

}

1;
                  
