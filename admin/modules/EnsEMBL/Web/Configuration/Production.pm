package EnsEMBL::Web::Configuration::Production;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'AnalysisWebData';
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

  $self->create_node( 'AnalysisWebData', "Analysis WebData",
    [qw(
      database_report EnsEMBL::Admin::Component::Production::AnalysisWebData
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );

  $self->create_node( 'LogicName', "Analysis Descriptions",
    [qw(
      database_report EnsEMBL::Admin::Component::Production::LogicName
    )],
    { 'no_menu_entry' => 1, 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );


  $self->create_node( 'Add', "Add Analysis Web Data",
    [qw(
      database_report EnsEMBL::ORM::Component::DbFrontend::Input
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'Edit', "Add Analysis Description",
    [qw(
      database_report EnsEMBL::ORM::Component::DbFrontend::Input
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)], 'no_menu_entry' => 1}
  );
  $self->create_node( 'Display', "View Analysis Description",
    [qw(
      database_report EnsEMBL::ORM::Component::DbFrontend::Display
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)], 'no_menu_entry' => 1}
  );
  $self->create_dbfrontend_node({$_ => {'filters' => ['WebAdmin']}}) for qw(Preview Problem Confirm Save Delete);
  
  my $menus = [
    'AnalysisDescription' => $self->dbfrontend_nodes({'filters' => [qw(WebAdmin)], 'raw' => 1}),
    'Species'             => $self->dbfrontend_nodes({'filters' => [qw(WebAdmin)], 'raw' => 1}),
    'Metakey'             => $self->dbfrontend_nodes({'filters' => [qw(WebAdmin)], 'raw' => 1}),
    'Biotype'             => $self->dbfrontend_nodes({'filters' => [qw(WebAdmin)], 'raw' => 1}),
    'Webdata'             => $self->dbfrontend_nodes({'filters' => [qw(WebAdmin)], 'raw' => 1}),
  ];

  while (my $menu_name = shift @$menus) {
    my $menu_nodes = shift @$menus;
    my $menu = $self->create_submenu($menu_name, $menu_name);
    
    while (my $node_name = shift @$menu_nodes) {
      my $node_params = shift @$menu_nodes;
      $node_params->{'url'} = "/$menu_name/$node_name";
    
      $menu->append($self->create_node("$menu_name$node_name", delete $node_params->{'caption'}, delete $node_params->{'components'}, $node_params));
    }
  }
}

1;
                  
