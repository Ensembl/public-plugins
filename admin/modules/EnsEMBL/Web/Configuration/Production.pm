package EnsEMBL::Web::Configuration::Production;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Configuration::MultiDbFrontend);

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
  $self->create_multidbfrontend_menu($_, $_, {'filters' => [qw(WebAdmin)]}) for qw(Species SpeciesAlias Metakey Biotype Webdata AttribType ExternalDb);
  $self->delete_node('Webdata/List');

}

1;