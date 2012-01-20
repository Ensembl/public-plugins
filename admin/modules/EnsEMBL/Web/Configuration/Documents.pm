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
}

1;