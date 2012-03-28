package EnsEMBL::Admin::Command::Documents::Save;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self    = shift;
  my $object  = $self->object;

  $self->ajax_redirect($self->hub->url({'action' => ($object->saved_successfully ? 'View' : 'Edit'), 'function' => $object->function}));
}

1;