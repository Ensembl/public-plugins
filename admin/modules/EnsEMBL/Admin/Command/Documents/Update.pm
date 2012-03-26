package EnsEMBL::Admin::Command::Documents::Update;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self    = shift;
  my $object  = $self->object;

  $self->ajax_redirect($self->hub->url({'action' => 'View', 'function' => $object->function}));
}

1;