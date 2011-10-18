package EnsEMBL::Web::Configuration::HelpRecord;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

sub short_caption { 'Help Record'; }
sub caption       { 'Help Record'; }

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('tabs');
  $page->remove_body_element('tool_buttons');
  $page->remove_body_element('summary');
}

sub populate_tree {
  my $self  = shift;
  my @menus = qw(Movie Movies FAQ FAQs View Pages Glossary Glossary);
  while (my @m = splice @menus, 0, 2) {
    my $menu = $self->create_submenu($m[0], $m[1]);
    $menu->append($self->create_node( "List/$m[0]", "List",
      ["list$m[0]" => 'EnsEMBL::Admin::Component::HelpRecord::List'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
    $menu->append($self->create_node( "Display/$m[0]", "View",
      ["display$m[0]" => 'EnsEMBL::Admin::Component::HelpRecord::Display'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
    $menu->append($self->create_node( "Add/$m[0]", "Add",
      ["add$m[0]" => 'EnsEMBL::ORM::Component::DbFrontend::Input'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
  }

  $self->create_dbfrontend_node({$_ => {'filters' => ['WebAdmin']}}) for qw(Edit Duplicate Preview Problem Confirm Save Delete);
}

1;