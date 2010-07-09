package EnsEMBL::ORM::Command::DbFrontend::Save;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Save
### Module to save EnsEMBL::ORM::Rose::Object contents back to the database

### STATUS: Under Development

### DESCRIPTION:
### This module saves a domain object that has been edited via form, and
### redirects to a relevant output page. Note that timestamps are set here, 
### rather than via MySQL now()

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $param = {};
  my $hub = $self->model->hub;

  my $data = $self->model->object;
  $data->populate_from_cgi;

  ## Set timestamps
  my ($sec, $min, $hour, $day, $mon, $year) = localtime();
  my $now = (1900+$year).'-'.sprintf('%02d', $mon+1).'-'.sprintf('%02d', $day)
              .' '.sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);
  if ($data->data_object->can(created_by) && $data->data_object->created_by) {
    $data->data_object->created_at($now);
  }
  elsif ($data->data_object->can(modified_by) && $data->data_object->modified_by) {
    $data->data_object->modified_at($now);
  }
 
  my $success = $data->save;

  my $url = '/'.$hub->type.'/';
  if ($success && @$success) {
    $url .= 'List';
    $param->{'id'} = $success;
  }
  else {
    $url .= 'Problem';
  }

  $self->ajax_redirect($url, $param);
}

1;
