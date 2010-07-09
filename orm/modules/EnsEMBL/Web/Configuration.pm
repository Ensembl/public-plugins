package EnsEMBL::Web::Configuration;

### NAME: EnsEMBL::Web::Configuration
### Extension to the core Configuration module, enabling easy addition
### of all the standard nodes required by the CRUD interface  

### STATUS: Under development

### Do not edit this module - subclass it and use the modify_tree method

use strict;

use base qw(EnsEMBL::Web::Root);

sub add_dbfrontend_to_tree {
  my ($self, $filters) = @_;
  my $type = $self->type;

  ## Starting pages visible
  $self->create_node('Add', "Add $type",
    [qw(add   EnsEMBL::ORM::Component::DbFrontend::Input)],
    {'availability' => 1, 'filters' => $filters},
  );
  $self->create_node( 'SelectToEdit', "Edit $type",
    [qw(select   EnsEMBL::ORM::Component::DbFrontend::Select)],
    {'availability' => 1, 'filters' => $filters},
  );
  ## Note that we don't use 'availability' to control Delete nodes, as
  ## we most likely want to hide deletion from the user if it not allowed 
  my $config = $self->get_frontend_config;
  if ($config->{'permit_delete'}) {
    $self->create_node( 'SelectToDelete', "Delete $type",
      [qw(select   EnsEMBL::ORM::Component::DbFrontend::Select)],
      {'availability' => 1, 'filters' => $filters},
    );
  }
  $self->create_node( 'List', 'List all',
    [qw(list   EnsEMBL::ORM::Component::DbFrontend::List)],
    {'availability' => 1, 'filters' => $filters},
  );

  ## Invisible steps
  $self->create_node( 'Display', "$type",
    [qw(display   EnsEMBL::ORM::Component::DbFrontend::Display)],
    {'availability' => 1, 'no_menu_entry' => 1, 'filters' => $filters }
  );
  $self->create_node( 'Edit', "Editing $type",
    [qw(edit   EnsEMBL::ORM::Component::DbFrontend::Input)],
    {'availability' => 1, 'no_menu_entry' => 1, 'filters' => $filters }
  );
  $self->create_node( 'Preview', 'Preview changes',
    [qw(previe   EnsEMBL::ORM::Component::DbFrontend::Preview)],
    {'availability' => 1, 'no_menu_entry' => 1, 'filters' => $filters }
  );
  $self->create_node( 'Problem', 'Error',
    [qw(problem   EnsEMBL::ORM::Component::DbFrontend::Problem)],
    {'availability' => 1, 'no_menu_entry' => 1, 'filters' => $filters }
  );

  $self->create_node( 'Save', '',
    [], {'command' => 'EnsEMBL::ORM::Command::DbFrontend::Save',
    'no_menu_entry' => 1, 'filters' => $filters }
  );
  if ($config->{'permit_delete'}) {
    $self->create_node( 'Delete', '',
      [], {'command' => 'EnsEMBL::ORM::Command::DbFrontend::Delete',
      'no_menu_entry' => 1, 'filters' => $filters }
    );
  }
}

1;
