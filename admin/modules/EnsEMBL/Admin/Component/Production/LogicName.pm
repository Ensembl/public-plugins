package EnsEMBL::Admin::Component::Production::LogicName;

use strict;

use base qw(EnsEMBL::Admin::Component::Production);

sub caption {
  return '';
}

sub content {
  my $self = shift;

  my $object  = $self->object;
  my $dom     = $self->dom;
  my $records = $object->rose_objects;

  my $content = $dom->create_element('div');

  my @columns = qw(edit analysis_description species db_type web_data displayable);
  my %widths  = qw(edit 35px analysis_description 200px species 150px db_type 100px web_data 100% displayable 100px);
  my %labels  = ('edit', '', 'analysis_description', 'Logic Name', 'species', 'Species', 'db_type', 'Database Type', 'web_data', 'Web Data', 'displayable', 'Displayable');

  $content->append_child('table', {
    'class'       => 'ss prod-ss',
    'cellspacing' => '0',
    'children'    => [{
      'node_name'   => 'tr',
      'class'       => 'ss_header',
      'children'    => [map {{'node_name' => 'th', 'style' => {'width' => $widths{$_}}, 'inner_HTML' => $labels{$_}}} @columns]
      }, 
      map {
        my $record = $_;
        {
          'node_name' => 'tr',
          'children'  => [
            {'node_name' => 'td', 'style' => {'width' => $widths{'edit'}}, 'inner_HTML' => sprintf('<a href="%s">Edit</a>', $self->hub->url({'action' => 'Edit', 'id' => $record->get_primary_key_value}))},
            (map {{'node_name' => 'td', 'style' => {'width' => $widths{$_}}, 'inner_HTML' => $self->get_printable($record->$_)}} qw(analysis_description species db_type web_data)),
            {'node_name' => 'td', 'style' => {'width' => $widths{'displayable'}}, 'inner_HTML' => $record->displayable ? 'Yes' : 'No'},
          ]
        }
      } @$records
    ]
  });

  return $content->render;
}

1;