package EnsEMBL::Web::Command::Help::Interface::Video;

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

  $interface->modify_element('youtube_id', {'label' => 'YouTube ID (11 characters)'});
  $interface->modify_element('length', {'type'=>'String','label'=>'Length (mm:ss)'});

  $interface->element_order(['title', 'youtube_id', 'length', 'list_position', 'status']);
  $interface->dropdown(1);
  $interface->option_columns(['title']);

  $interface->configure($self->webpage, $object);

}

}

1;
