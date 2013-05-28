package EnsEMBL::ORM::Command::DbFrontend::Delete;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Delete
### Module to delete/retire ORM::EnsEMBL::Rose::Object drived record(s)

### STATUS: Under Development

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $done      = $object->delete;
  my $errors    = $object->rose_errors;
  my $function  = $hub->function || '';

  $self->ajax_redirect($self->hub->url($done && @$done && !@$errors ? {'action' => 'Display', 'function' => $function} : {'action' => 'Problem', 'function' => $function, 'error' => join('. ', @$errors)}));
}

1;
