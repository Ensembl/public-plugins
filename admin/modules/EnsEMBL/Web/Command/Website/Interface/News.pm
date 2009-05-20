package EnsEMBL::Web::Command::Website::Interface::News;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::NewsItem;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface->new();
  $data = EnsEMBL::Web::Data::NewsItem->new($object->param('id'));
  $interface->data($data);
  $interface->discover;

  $interface->modify_element('team',        {'type' => 'NoEdit'});
  $interface->modify_element('declaration', {'type' => 'NoEdit'});
  $interface->modify_element('notes',       {'rows' => 2, 'cols' => 80});
  $interface->modify_element('content',     {'type' => 'Html'});
  $interface->modify_element('news_category_id', {'label' => 'Category'});
  $interface->modify_element('priority', {
    'type'    => 'DropDown',
    'select'  => 'select', 
    'values'  => [
      {'name' => '0', 'value' => ''},
      {'name' => '1', 'value' => '1'},
      {'name' => '2', 'value' => '2'},
      {'name' => '3', 'value' => '3'},
      {'name' => '4', 'value' => '4'},
      {'name' => '5', 'value' => '5'},
    ]
  });

  $interface->element_order(['team', 'declaration', 'notes', 'species', 'news_category_id', 'title', 'content', 'status', 'priority', 'news_done']);
  $interface->dropdown(1);
  $interface->option_columns(['title','content']);

  $interface->configure($self->webpage, $object);

}

}

1;
