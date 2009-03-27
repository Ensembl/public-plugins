package EnsEMBL::Admin::Configuration::Help;

use strict;
use base qw( EnsEMBL::Web::Configuration );

sub populate_tree {
  my $self = shift;

  $self->delete_submenu('Topics');
  $self->delete_node('ArchiveList');
  $self->delete_node('Permalink');
  $self->delete_node('View');

  $self->create_node( 'View', '', [],
    { 'no_menu_entry' => 1, 'availability' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Help::Interface::View',
  });
  $self->create_node( 'Faq', '', [],
    { 'no_menu_entry' => 1, 'availability' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Help::Interface::Faq',
  });
  $self->create_node( 'Glossary', '', [],
    { 'no_menu_entry' => 1, 'availability' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Help::Interface::Glossary',
  });
  $self->create_node( 'Movie', '', [],
    { 'no_menu_entry' => 1, 'availability' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Help::Interface::Movie',
  });

#'filters' => [qw(WebAdmin)]
}

1;
