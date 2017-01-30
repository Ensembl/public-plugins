=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Production;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Configuration::MultiDbFrontend);

use constant DEFAULT_ACTION => 'Search';

sub caption       { 'Production Database'; }
sub short_caption { 'Production Database'; }

sub modify_page_elements {
  my $page = shift->page;
  $page->remove_body_element($_) for qw(tabs summary);
}

sub populate_tree {
  my $self = shift;
  my $hub  = $self->hub;

  $self->create_multidbfrontend_menu('Production', 'Analysis Web Data', {'filters' => [qw(WebAdmin)]}, [
    'Search'          => {'caption' => 'Search',    'components' => [qw(s_analysis_webdata     EnsEMBL::Admin::Component::Production::Search)],          'availability' => 1},
    'AnalysisWebData' => {'caption' => 'List All',  'components' => [qw(analysis_webdata       EnsEMBL::Admin::Component::Production::AnalysisWebData)], 'availability' => 1},
    'LogicName'       => {'caption' => 'List',      'components' => [qw(view_analysis_webdata  EnsEMBL::Admin::Component::Production::LogicName)],       'availability' => 1, 'no_menu_entry' => 1},
    'Add'             => {},
    'Edit'            => {},
    'Duplicate'       => {},
    'Select/Edit'     => {},
    'Select/Delete'   => {},
    'Preview'         => {},
    'Problem'         => {},
    'Confirm'         => {},
    'Save'            => {},
    'Delete'          => {},
  ]);
  $self->create_multidbfrontend_menu('AnalysisDesc', 'Analysis Description', {'filters' => [qw(WebAdmin)]});
  $self->create_multidbfrontend_menu($_, $_, {'filters' => [qw(WebAdmin)]}) for qw(Species SpeciesAlias Metakey Biotype Webdata AttribType Attrib AttribSet ExternalDb);
  $self->delete_node('Webdata/List');

}

1;
