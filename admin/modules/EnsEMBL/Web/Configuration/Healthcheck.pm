=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Configuration::Healthcheck;

use strict;
use warnings;
use parent qw(EnsEMBL::Web::Configuration);

sub caption       { 'Healthcheck'; }
sub short_caption { 'Healthcheck'; }

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Summary';
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('tabs');
  $page->remove_body_element('summary');
}

sub populate_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  my $release_id   = $hub->param('release') || $species_defs->ENSEMBL_VERSION;

  $self->create_node( 'Summary', "Summary (Release $release_id)",
    [qw(
      failure_summary EnsEMBL::Admin::Component::Healthcheck::FailureSummary
      session_info    EnsEMBL::Admin::Component::Healthcheck::SessionInfo
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details/DBType', "Details (by DB Type)",
    [qw(
      database_report EnsEMBL::Admin::Component::Healthcheck::Details
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details/Species', "Details (by Species)",
    [qw(
      species_report EnsEMBL::Admin::Component::Healthcheck::Details
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details/Team', "Details (by Team)",
    [qw(
      testcase_report EnsEMBL::Admin::Component::Healthcheck::Details
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details/Testcase', "Details (by Testcase)",
    [qw(
      testcase_report EnsEMBL::Admin::Component::Healthcheck::Details
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
 $self->create_node( 'Details/Database', "Details (by Database)",
    [qw(
      database_report EnsEMBL::Admin::Component::Healthcheck::Details
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'Database', "Database List",
    [qw(
      directory EnsEMBL::Admin::Component::Healthcheck::DatabaseList
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'HealthcheckBugs', "Healthcheck Bugs",
    [qw(
      healthcheck_bugs EnsEMBL::Admin::Component::Healthcheck::HealthcheckBugs
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'Annotation', '',
    [qw(
      annotation EnsEMBL::Admin::Component::Healthcheck::Annotation
    )],
    { 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );  

  $self->create_node( 'AnnotationSave', '', [],
      { 'command' => 'EnsEMBL::Admin::Command::Healthcheck::Annotation',
         'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );
}

1;
                  
