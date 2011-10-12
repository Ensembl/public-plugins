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

  for ([qw(Movie movies)], [qw(FAQ FAQs)], [qw(View pages)], [qw(Glossary glossary)]) {
    my $menu = $self->create_submenu($_[0], ucfirst $_->[1]);
    $menu->append($self->create_node( "List/$_->[0]", "List",
      ["display$_->[0]" => 'EnsEMBL::ORM::Component::DbFrontend::List'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
    $menu->append($self->create_node( "Display/$_->[0]", "View",
      ["display$_->[0]" => 'EnsEMBL::Admin::Component::HelpRecord::Display'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
    $menu->append($self->create_node( "Add/$_->[0]", "Add",
      ["display$_->[0]" => 'EnsEMBL::ORM::Component::DbFrontend::Input'],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));
  }

  $self->create_dbfrontend_node({$_ => {'filters' => ['WebAdmin']}}) for qw(Edit Duplicate Preview Problem Confirm Save Delete);
}

1;