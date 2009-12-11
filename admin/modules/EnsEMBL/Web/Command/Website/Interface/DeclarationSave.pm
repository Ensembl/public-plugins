package EnsEMBL::Web::Command::Website::Interface::DeclarationSave;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::RegObj;

use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $interface = $object->interface;
  my $url = '/Website/Declaration/List';

  my $param = {
    '_referer'  => $object->param('_referer'),
    'x_requested_with'  => $object->param('x_requested_with'),
  };

  $interface->cgi_populate($object);
  my @species = $object->param('species');
  my $success = $interface->data->save($object->param('id'), \@species);

  if ($success) {
    $param->{'id'} = $success;
    $param->{'release_id'} = $object->param('release_id');
  }
  else {
    $url .= 'Problem';
  }

  if ($object->param('x_requested_with')) {
    $self->ajax_redirect($url, $param);
  }
  else {
    $object->redirect($object->url($url, $param));
  }
}

}

1;
