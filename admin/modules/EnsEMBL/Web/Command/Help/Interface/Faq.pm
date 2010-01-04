package EnsEMBL::Web::Command::Help::Interface::Faq;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::Faq;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = $self->interface;

  $data = EnsEMBL::Web::Data::Faq->new($object->param('id'));
  
  $interface->data($data);
  $interface->discover;

  my @keywords = (
    {'name' => 'Webpage',       'value' => 'web'},
    {'name' => 'Core API',      'value' => 'core'},
    {'name' => 'Compara API',   'value' => 'compara'},
    {'name' => 'Variation API',   'value' => 'variation'},
    {'name' => 'Funcgen API',       'value' => 'funcgen'},
  );
  $interface->modify_element('keyword', {'type' => 'DropDown', 'label' => 'Type', 'values' => \@keywords, 'select' => 'select'});
  $interface->modify_element('content', {'type' => 'Html'});

## Form elements
  $interface->element_order(['keyword', 'question', 'answer', 'status']);
  $interface->dropdown(1);
  $interface->option_columns(['keyword', 'question']);

  $interface->configure($self->webpage, $object);

}

}

1;
