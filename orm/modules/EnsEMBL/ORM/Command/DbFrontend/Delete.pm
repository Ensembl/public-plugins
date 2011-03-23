package EnsEMBL::ORM::Command::DbFrontend::Delete;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Delete
### Module to delete/retire EnsEMBL::ORM::Rose::Object drived record(s)

### STATUS: Under Development

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  
  my $record  = $self->object->rose_object;

  my $done   = $object->delete;
  $self->ajax_redirect($self->hub->url({'action' => $done && @$done ? 'Display' : 'Problem'}));
}

1;