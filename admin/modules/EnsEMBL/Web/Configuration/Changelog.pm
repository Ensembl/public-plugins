package EnsEMBL::Web::Configuration::Changelog;

use strict;
use base qw( EnsEMBL::Web::Configuration );

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Summary';
}

sub short_caption {}
sub caption {}

sub global_context { return undef; }
sub ajax_content   { return undef; }
sub local_context  { return $_[0]->_local_context; }
sub local_tools    { return undef; }
sub context_panel  { return undef; }
sub content_panel  { return $_[0]->_content_panel;  }

sub populate_tree {
  my $self = shift;

  ## Add defaults
  $self->add_dbfrontend_to_tree;

  $self->create_node( 'Summary', 'Full Declarations',
    [qw(summary EnsEMBL::Web::Component::Changelog::Summary)], 
    { 'availability' => 1}
  );
  $self->delete_node('Add');
  $self->create_node( 'Add', 'Add a Declaration',
    [qw(add EnsEMBL::Web::Component::DbFrontend::Add)], 
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
=pod
  $dec_menu->append($self->create_node( 'Declaration/SelectToEdit', 'Edit a Declaration',
    [qw(edit_declaration EnsEMBL::Web::Component::Website::Interface::DeclarationSelectToEdit)], 
    { 'availability' => 1}
  ));
  $dec_menu->append($self->create_node( 'Declaration/List', 'Quick Lookup Table',
    [], 
    { 'availability' => 1, 'command' => 'EnsEMBL::Web::Command::Website::Interface::Declaration'}
  ));

  $self->create_node( 'Declaration', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1, 'filters' => [qw(WebAdmin)],
    'command' => 'EnsEMBL::Web::Command::Website::Interface::Declaration'}
  );
=cut
}

1;
