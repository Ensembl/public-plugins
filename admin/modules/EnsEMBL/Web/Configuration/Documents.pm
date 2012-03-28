package EnsEMBL::Web::Configuration::Documents;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'View';
}

sub populate_tree {
  my $self  = shift;
  my $hub   = $self->hub;
  my $docs  = $self->object ? $self->object->available_documents : [];

  $self->create_node("View", 'View',
      [ 'view' => 'EnsEMBL::Admin::Component::Documents::View' ],
      { 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
  );

  while (my ($func, $doc) = splice @$docs, 0, 2) {

    my $menu  = $self->create_submenu($doc->{'title'}, $doc->{'title'});

    $menu->append($self->create_node("View/$func", 'View',
      [ 'view' => 'EnsEMBL::Admin::Component::Documents::View' ],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));

    unless ($doc->{'readonly'}) {
      $menu->append($self->create_node("Edit/$func", 'Edit',
        [ 'view' => 'EnsEMBL::Admin::Component::Documents::Edit' ],
        { 'availability' => 1, 'filters' => ['WebAdmin'] }
      ));

      $menu->append($self->create_node("Preview/$func", 'Preview',
        [ 'view' => 'EnsEMBL::Admin::Component::Documents::Preview' ],
        { 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
      ));
    }

    $menu->append($self->create_node("Update/$func", 'CVS Update', [],
      { 'command' => 'EnsEMBL::Admin::Command::Documents::Update', 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));

    $self->create_node("Save/$func", 'Save', [],
      { 'command' => 'EnsEMBL::Admin::Command::Documents::Save',   'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
    );
  }
}

1;