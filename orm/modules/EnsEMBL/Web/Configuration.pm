package EnsEMBL::Web::Configuration;

use strict;

use base qw(EnsEMBL::Web::Root);

sub add_dbfrontend_to_tree {
  my $self = shift;
  my $type = $self->type;

  ## Starting pages visible
  $self->create_node('Add', "Add $type",
    [qw(add   EnsEMBL::ORM::Component::DbFrontend::Add)],
    {'availability' => 1},
  );
  $self->create_node( 'SelectToEdit', "Edit $type",
    [qw(select   EnsEMBL::ORM::Component::DbFrontend::SelectToEdit)],
    {'availability' => 1},
  );
  $self->create_node( 'List', 'List all',
    [qw(list   EnsEMBL::ORM::Component::DbFrontend::List)],
    {'availability' => 1},
  );

  ## Invisible steps
  $self->create_node( 'Display', "$type",
    [qw(display   EnsEMBL::ORM::Component::DbFrontend::Display)],
    {'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Edit', "Editing $type",
    [qw(edit   EnsEMBL::ORM::Component::DbFrontend::Edit)],
    {'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Preview', 'Preview changes',
    [qw(previe   EnsEMBL::ORM::Component::DbFrontend::Preview)],
    {'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'ConfirmDelete', '',
    [qw(delete   EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete)],
    {'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Problem', 'Error',
    [qw(problem   EnsEMBL::ORM::Component::DbFrontend::Problem)],
    {'availability' => 1, 'no_menu_entry' => 1 }
  );

  $self->create_node( 'Save', '',
    [], {'command' => 'EnsEMBL::ORM::Command::DbFrontend::Save',
    'no_menu_entry' => 1 }
  );
}

1;
