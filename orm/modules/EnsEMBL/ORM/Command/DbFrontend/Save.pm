package EnsEMBL::ORM::Command::DbFrontend::Save;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Save
### Module to save ORM::EnsEMBL::Rose::Object contents back to the database

### STATUS: Under Development

### DESCRIPTION:
### This module saves an object for the dbfrontend object that has been edited via form

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $done      = $object->save;
  my $function  = $hub->function || '';
  
  $self->ajax_redirect($hub->url($done && @$done
    ? $object->is_ajax_request ? {'action' => 'Display', 'function' => $function, 'id' => $object->rose_object->get_primary_key_value} : {'action' => $object->default_action, 'function' => $function}
    : {'action' => 'Problem', 'function' => $function, 'error' => $object->rose_error}
  ));
}

1;
