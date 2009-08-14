package EnsEMBL::Web::Command::Help::Interface::Glossary;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::Glossary;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface->new();

  $data = EnsEMBL::Web::Data::Glossary->new($object->param('id'));
  
  $interface->data($data);
  $interface->discover;

  $interface->modify_element('word', {'required' => 'yes'});
  $interface->modify_element('meaning', {'required' => 'yes'});
  $interface->element_order(['word', 'expanded', 'meaning', 'status']);
  $interface->dropdown(1);
  $interface->option_columns(['word','id']);

  $interface->configure($self->webpage, $object);

}

}

1;
