package EnsEMBL::Web::Configuration::HelpRecord;

use strict;

use base qw(EnsEMBL::Web::Configuration::MultiDbFrontend);

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
  my $hub   = $self->hub;
  my @menus = qw(Movie Movies FAQ FAQs View Pages Glossary Glossary);
  my @comps = qw(
    List      EnsEMBL::Admin::Component::HelpRecord::List         0
    Display   EnsEMBL::Admin::Component::HelpRecord::Display      0
    Add       EnsEMBL::ORM::Component::DbFrontend::Input          0
    Edit      EnsEMBL::ORM::Component::DbFrontend::Input          1
    Duplicate EnsEMBL::ORM::Component::DbFrontend::Input          1
    Preview   EnsEMBL::ORM::Component::DbFrontend::Input          1
    Problem   EnsEMBL::ORM::Component::DbFrontend::Problem        1
    Confirm   EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete  1
  );
  my @comds = qw(
    Save      EnsEMBL::ORM::Command::DbFrontend::Save             1
    Delete    EnsEMBL::ORM::Command::DbFrontend::Delete           1
  );

  while (my ($function, $caption) = splice @menus, 0, 2) {

    my $menu        = $self->create_submenu($function, $caption);
    my @components  = @comps;
    my @commands    = @comds;

    while (my ($action, $component, $no_menu_entry) = splice @components, 0, 3) {
      $menu->append($self->create_node( "HelpRecord/$action/$function", $action,
        ["$action$function" => $component],
        { 'availability' => 1, 'filters' => ['WebAdmin'], 'raw' => 1, 'url' => $hub->url({'type' => 'HelpRecord', 'action' => $action, 'function' => $function}), 'no_menu_entry' => $no_menu_entry }
      ));
    }

    while (my ($action, $command, $no_menu_entry) = splice @commands, 0, 3) {
      $menu->append($self->create_node( "HelpRecord/$action/$function", $action,
        [],
        { 'availability' => 1, 'command' => $command, 'filters' => ['WebAdmin'], 'raw' => 1, 'url' => $hub->url({'type' => 'HelpRecord', 'action' => $action, 'function' => $function}), 'no_menu_entry' => $no_menu_entry }
      ));
    }
  }

  $self->create_multidbfrontend_menu('HelpLink', 'Help Links');
}

1;