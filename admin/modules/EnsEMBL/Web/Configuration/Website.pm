package EnsEMBL::Web::Configuration::Website;

use strict;
use base qw( EnsEMBL::Web::Configuration );

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Declaration/List';
}

sub global_context { return undef; }
sub ajax_content   { return undef; }
sub local_context  { return $_[0]->_local_context; }
sub local_tools    { return undef; }
sub context_panel  { return undef; }
sub content_panel  { return $_[0]->_content_panel;  }

sub populate_tree {
  my $self = shift;

  $self->create_node( 'CurrentSpecies', 'Current Species',
    [qw(add_species EnsEMBL::Web::Component::Website::CurrentSpecies)], 
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'AddSpecies', '',
    [qw(add_species EnsEMBL::Web::Component::Website::AddSpecies)], 
    { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)]}
  );
  $self->create_node( 'UpdateRelease', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::UpdateRelease'}
  );
  $self->create_node( 'UpdateSpecies', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::UpdateSpecies'}
  );
  $self->create_node( 'SaveSpecies', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::SaveSpecies'}
  );
  my $dec_menu = $self->create_submenu( 'DecMenu', 'Declarations' );
  $dec_menu->append($self->create_node( 'Declaration/Add', 'Add a Declaration',
    [], 
    { 'availability' => 1, 'command' => 'EnsEMBL::Web::Command::Website::Interface::Declaration'}
  ));
  $dec_menu->append($self->create_node( 'Declaration/SelectToEdit', 'Edit a Declaration',
    [qw(edit_declaration EnsEMBL::Web::Component::Website::Interface::DeclarationSelectToEdit)], 
    { 'availability' => 1}
  ));
  $dec_menu->append($self->create_node( 'Declaration/List', 'Quick Lookup Table',
    [], 
    { 'availability' => 1, 'command' => 'EnsEMBL::Web::Command::Website::Interface::Declaration'}
  ));
  $dec_menu->append($self->create_node( 'Declarations', 'Summary of Declarations',
    [qw(declarations EnsEMBL::Web::Component::Website::Declarations)], 
    { 'availability' => 1}
  ));

  my $news_menu = $self->create_submenu( 'NewsMenu', 'News Stories' );
  $news_menu->append($self->create_node( 'News/SelectToEdit', 'Add/Edit Current News',
    [qw(edit_news EnsEMBL::Web::Component::Website::Interface::NewsSelectToEdit)],
    { 'availability' => 1}
  ));
  $news_menu->append($self->create_node( 'SelectRelease', 'Select a Release',
    [qw(select_release EnsEMBL::Web::Component::Website::SelectRelease)], 
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  ));

  $self->create_node( 'Declaration', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::Interface::Declaration'}
  );
  $self->create_node( 'News', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::Interface::News'}
  );
}

1;
