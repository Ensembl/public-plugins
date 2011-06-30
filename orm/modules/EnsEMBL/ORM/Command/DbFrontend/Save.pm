package EnsEMBL::ORM::Command::DbFrontend::Save;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Save
### Module to save EnsEMBL::ORM::Rose::Object contents back to the database

### STATUS: Under Development

### DESCRIPTION:
### This module saves an object for the dbfrontend object that has been edited via form

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;

  my $object = $self->object;
  my $done   = $object->save;
  
  $self->ajax_redirect($self->hub->url($done && @$done
    ? $object->is_ajax_request ? {'action' => 'Display', 'id' => $object->rose_object->get_primary_key_value} : {'action' => $object->default_action}
    : {'action' => 'Problem'}
  ));
}

1;