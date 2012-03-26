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

  $self->create_node('View', 'View',
    [ 'view' => 'EnsEMBL::Admin::Component::Documents::View' ],
    { 'availability' => 1, 'filters' => ['WebAdmin'] }
  );

  $self->create_node('Update', 'Update', [],
    { 'command' => 'EnsEMBL::Admin::Command::Documents::Update', 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
  );
}

1;