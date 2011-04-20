package EnsEMBL::Web::Configuration::Production;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'LogicName';
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

  $self->create_node( 'LogicName', "Analysis Logic Name",
    [qw(
      database_report EnsEMBL::Admin::Component::Production::LogicName
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'Add', "Add Analysis Description",
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
  
}

1;
                  
