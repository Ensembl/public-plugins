package EnsEMBL::Web::Command::Help::Interface::Movie;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::Movie;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface->new();

  $data = EnsEMBL::Web::Data::Movie->new($object->param('id'));
  
  $interface->data($data);
  $interface->discover;

  $interface->element('caveat', {'type' => 'Information', 'value' => "Please note that Flash movie files need to be uploaded to the server manually at the moment, as the XML provided by Camtasia needs tweaking to work with our code. Please contact the webteam for help.<br /><br /><strong>N.B.</strong> The filename should be the 'common' part of all the files produced by the Camtasia export, e.g. '5_min_overview_24nov08', not '5_min_overview_24nov08.swf'."});
  $interface->modify_element('width', {'label' => 'Width (px)'});
  $interface->modify_element('height', {'label' => 'Width (px)'});
  $interface->modify_element('filesize', {'label' => 'File size (MB) (to one decimal place)'});
  $interface->modify_element('length', {'type'=>'String','label'=>'Length (mm:ss)'});

  $interface->element_order(['caveat', 'title', 'filename', 'width', 'height', 'filesize', 'length', 'status']);
  $interface->dropdown(1);
  $interface->option_columns(['title']);

  $interface->configure($self->webpage, $object);

}

}

1;
