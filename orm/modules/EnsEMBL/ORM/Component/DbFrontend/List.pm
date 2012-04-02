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
          'class'       => ['ss', 'dbf-ss', $object->is_ajax_request ? $self->_JS_CLASS_RESPONSE_ELEMENT : ($self->_JS_CLASS_LIST_TABLE, $object->list_is_datatable ? $self->_JS_CLASS_DATATABLE : ())],
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
  my $record_name = $object->record_name->{'singular'};
  my $record_meta = $record->meta;
  my $record_row  = $self->dom->create_element('tr', $header_only
    ? {'children'   => [{'node_name' => 'th', 'class' => 'sort_none', 'style' => 'width: 60px'}]}
    : {'children'   => [{'node_name' => 'td', 'class' => ['dbf-list-buttons', $self->_JS_CLASS_LIST_ROW_HANDLE], 'children' => [
        {'node_name'  => 'a', 'href' => $hub->url({'action' => 'Edit',      'function' => $hub->function, 'id' => $primary_key}), 'title' => sprintf('Edit %s',      $record_name), 'class' => [$self->_JS_CLASS_EDIT_BUTTON, 'dbf-list-edit']},
        {'node_name'  => 'a', 'href' => $hub->url({'action' => 'Confirm',   'function' => $hub->function, 'id' => $primary_key}), 'title' => sprintf('Delete %s',    $record_name), 'class' => [$self->_JS_CLASS_EDIT_BUTTON, 'dbf-list-delete']},
        {'node_name'  => 'a', 'href' => $hub->url({'action' => 'Duplicate', 'function' => $hub->function, 'id' => $primary_key}), 'title' => sprintf('Duplicate %s', $record_name), 'class' => [$self->_JS_CLASS_ADD_BUTTON,  'dbf-list-duplicate']}
      ]}], 'class' => "dbf-list-row _dbf_row_$primary_key $css_class", 'flags' => {'primary_key' => $primary_key}});

  my $columns = $object->show_columns;
  while (my $column_name = shift @$columns) {

    my $column = shift @$columns;
    my $label  = (ref $column ? $column->{'title'} : $column) || $column_name;

    if ($header_only) {

      my $real_col    = $record->extract_column_name($column_name);
      my $is_column   = grep {$_ eq $real_col} $record_meta->column_names;
      my $editable    = !$record_meta->is_trackable($real_col);
      my $css         = '';
      my $width;

      if (ref $column) {
        $editable = $column->{'editable'} if $editable && exists $column->{'editable'};
        $width    = $column->{'width'};
        $css      = $column->{'class'} || '';
      }

      $record_row->append_child('th', {
        'inner_HTML'  => $editable ? sprintf('<input class="%s" name="%s" value="%s" type="hidden" />%s', ($is_column ? 'column' : 'relation'), $column_name, $hub->url({'action' => 'Edit', 'function' => $hub->function}), $label) : $label,
        'class'       => $object->list_is_datatable ? ['sorting', 'sort_html', ref $css eq 'ARRAY' ? @$css : split ' ', $css] : $css,
        $width ? ('style' => {'width' => $width}) : (),
      });
    }
    else {
      my $is_title  = $record_meta->title_column && $record_meta->title_column eq $column_name;
      my $relation  = ref $column ? $column->{'ensembl_object'} : '';
      my $value     = $self->_display_column_value($record->field_value($column_name), $is_title, $relation, $label);
      $value        = sprintf('<a href="%s">%s</a>', $hub->url({'action' => 'Display', 'function' => $hub->function, 'id' => $primary_key}), $value) if $is_title;
      $record_row->append_child('td', {'inner_HTML' => $value, 'flags' => $column_name});
    }
  }
  return $record_row;
}

sub _display_column_value {
  ## Converts the field value into displayable form
  ## Value, as returned by the rose's method call, can be a string, rose object or an arrayref of rose objects ;)
  my ($self, $value, $is_title, $relation, $label) = @_;

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
    return sprintf('%s<a class="dbf-list-view _dbf_list_view" title="View related %s" href="%s"></a>', $title, $label, $self->hub->url({'type' => $relation, 'action' => 'Display', 'id' => $value->get_primary_key_value})) if $relation;
    return $title;
  }

  ## unknown value type
  return $value;
}

1;
