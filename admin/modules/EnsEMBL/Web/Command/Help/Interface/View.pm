package EnsEMBL::Web::Command::Help::Interface::View;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::View;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = $self->interface;

  $data = EnsEMBL::Web::Data::View->new($object->param('id'));
  
  $interface->data($data);
  $interface->discover;

  $interface->element('movie_tip', {'type' => 'Information', 'value' => 'Tip: To embed a YouTube movie, add the code [[movie=xxx]] on a separate line, where xxx is the numeric ID of the movie (not the YouTube ID string)'});
  $interface->modify_element('ensembl_object', {'label' => 'Page'});
  $interface->modify_element('ensembl_action', {'label' => 'View'});
  $interface->modify_element('content', {'type' => 'Html', 'required' => 'yes'});
  $interface->modify_element('id', {'label' => 'ID', 'type' => 'NoEdit'});

  $interface->element_order(['id', 'ensembl_object', 'ensembl_action', 'movie_tip', 'content', 'comment_note', 'status']);

  $interface->dropdown(1);
  $interface->option_columns(['ensembl_object', 'ensembl_action']);

  $interface->configure($self->webpage, $object);

}

}

1;
