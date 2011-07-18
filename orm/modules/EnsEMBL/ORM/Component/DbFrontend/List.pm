package EnsEMBL::ORM::Component::DbFrontend::List;

### NAME: EnsEMBL::ORM::Component::DbFrontend::List
### Module to create generic record list for DbFrontend and its associated modules

### STATUS: Under development
### Note: This module should not be modified! 
### To customise, either extend this module in your component, or EnsEMBL::Web::Object::DbFrontend in your E::W::object

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  ## Generates a DOM tree for content HTML
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  ## Flags are set on required HTML elements for 'selection and manipulation' purposes in child classes (get_nodes_by_flag)
  my $self    = shift;
  my $object  = $self->object;
  my $records = $object->rose_objects;
  
  return $self->SUPER::content_tree unless $records && @$records;

  my $links = $object->get_page_number ? $self->content_pagination_tree(scalar @$records) : undef;
  map {$_->remove} @{$links->get_nodes_by_flag('pagination_links')} if $links && !$object->pagination;

  my @bg = qw(bg1 bg2);
  
  return $self->dom->create_element('div', {
    'class'     => $object->content_css,
    'children'  => [
      $links ? $links : (), # Top pagination
      {
        'node_name' => 'div',
        'class'     => 'js_panel',
        'children'  => [{
          'node_name'   => 'inputhidden',
          'class'       => 'panel_type',
          'value'       => 'DbFrontendList'
        }, {
          'node_name'   => 'table',
          'class'       => sprintf('ss dbf-ss %s', $object->is_ajax_request ? $self->_JS_CLASS_RESPONSE_ELEMENT : $self->_JS_CLASS_LIST_TABLE),
          'cellpadding' => 0,
          'cellspacing' => 0,
          'border'      => 0,
          'children'    => [{
            'node_name'   => 'thead',
            'children'    => [$self->record_tree($records->[0], '', 1)]
          }, {
            'node_name'   => 'tbody',
            'children'    => [map {@bg = reverse @bg; $self->record_tree($_, $bg[1])} @$records]
          }]
        }]
      },
      $links ? $links->clone_node(1) : () # Bottom pagination
    ]
  });
}

sub record_tree {
  ## Generates a DOM tree (TR node) for each database record
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  my ($self, $record, $css_class, $header_only) = @_;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $primary_key = $record->get_primary_key_value;
  my $record_row  = $self->dom->create_element('tr', $header_only ? () : {'class' => "dbf-list-row _dbf_row_$primary_key $css_class", 'flags' => {'primary_key' => $primary_key}});
  my $columns     = $object->show_columns;

  while (my $column_name = shift @$columns) {

    my $label     = shift @$columns;
    my $value     = $record->$column_name;
    my $is_title  = $record->TITLE_COLUMN && $column_name eq $record->TITLE_COLUMN;

    $value = $self->_display_column_value($value, $is_title);
    $value = sprintf('<a href="%s">%s</a>', $hub->url({'action' => 'Display', 'id' => $primary_key}), $value) if $is_title;

    if ($header_only) {

      my $editable = $record->is_trackable && $column_name =~ /^(created|modified)_(at|by|by_user)$/ ? 0 : 1;
      my $width;

      if (ref $label) {
        $editable = $label->{'editable'} if $editable && exists $label->{'editable'};
        $width    = $label->{'width'};
        $label    = $label->{'title'};
      }

      $record_row->append_child('th', {
        'inner_HTML'  => $editable ? sprintf('<input class="%s" name="%s" value="%s" type="hidden" />%s', $self->_JS_CLASS_EDITABLE, $column_name, $hub->url({'action' => 'Edit'}), $label) : $label,
        'class'       => 'sorting sort_html',
        $width ? ('style' => {'width' => $width}) : (),
      });
    }
    else {
      $record_row->append_child('td', {'inner_HTML' => $value, 'flags' => $column_name});
    }
  }

  return $record_row;
}

sub _display_column_value {
  ## Converts the field value into displayable form
  ## Value, as returned by the rose's method call, can be a string, rose object or an arrayref of rose objects ;)
  my ($self, $value, $is_title) = @_;
  
  ## if nothing
  return '' unless defined $value;

  ## if it's a string
  return $value unless ref $value;
  
  ## if it's an arrayref
  if (ref $value eq 'ARRAY') {
    my @return;
    push @return, $self->_display_column_value($_, $is_title) for @$value;
    return @return ? @return == 1 ? shift @return : join ' and ', reverse (pop @return, join(', ', @return)) : '';
  }

  ## if it's DateTime (rose returns DateTime for datetime mysql type)
  return $self->print_datetime($value) if UNIVERSAL::isa($value, 'DateTime');

  ## if it's a rose object
  if (UNIVERSAL::isa($value, 'EnsEMBL::ORM::Rose::Object')) {
    my $title = $value->get_title;
    
    ## if it's a user
    if ($value->isa('EnsEMBL::ORM::Rose::Object::User') && $self->object->show_user_email && !$is_title) {
      return sprintf('<a href="mailto:%s">%s</a>', $value->email, $title);
    }
    return $title;
  }
  
  ## unknown value type
  return $value;
}

1;
