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
  my $done    = $object->delete;
  my $errors  = $object->rose_errors;

  $self->ajax_redirect($self->hub->url($done && @$done && !@$errors ? {'action' => 'Display'} : {'action' => 'Problem', 'error' => join('. ', @$errors)}));
}

1;