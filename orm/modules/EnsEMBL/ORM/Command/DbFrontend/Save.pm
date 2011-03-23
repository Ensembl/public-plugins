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
  my $result = $done && @$done;
  
  my $url_params = {'action' => $result ? 'Display' : 'Problem'};
  $url_params->{'id'} = $object->rose_object->get_primary_key_value if $result;
  
  $self->ajax_redirect($self->hub->url($url_params));
}

1;