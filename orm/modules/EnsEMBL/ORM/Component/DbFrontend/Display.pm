package EnsEMBL::ORM::Component::DbFrontend::Display;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Display
### Creates a page displaying one or more records in full 

### STATUS: Under development
### Note: This module should not be modified! 
### To customise, either extend this module in your component, or EnsEMBL::Web::Object::DbFrontend in your E::W::object
### To maintain AJAXy modification feature, provide the _JS_CLASS_* at corresponding places while extending this class

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  ## Generates a DOM tree for content HTML
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  ## Flags are set on required HTML elements for 'selection and manipulation' purposes in child classes (get_nodes_by_flag)
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $records = $object->rose_objects;
  
  return $self->SUPER::content_tree unless @$records;
  
  my $content = $self->dom->create_element('div', {
    'class'     => [$object->content_css, 'js_panel'],
    'children'  => [{'node_name' => 'input', 'type' => 'hidden', 'class' => 'panel_type', 'value' => 'DbFrontendRow'}]
  });

  my $page    = $object->get_page_number;
  my $links   = defined $page ? $content->append_child($self->content_pagination_tree(scalar @$records)) : undef;
  !$object->pagination and $links and map {$_->remove} @{$links->get_nodes_by_flag('pagination_links')};
  
  !$hub->param('id') and $object->use_ajax and !$object->is_ajax_request and $content->append_child('div', {
    'class' => ['dbf-record', $object->use_ajax ? $self->_JS_CLASS_DBF_RECORD : ()],
    'flags' => 'add_new_button',
    'children' => [
      {'node_name' => 'div', 'class' => 'dbf-row-buttons', 'children' => [
        {'node_name' => 'a', 'inner_HTML' => 'Add new', 'class' => $self->_JS_CLASS_ADD_BUTTON, 'href' => $hub->url({'action' => 'Add', 'function' => $hub->function})}
      ]}
    ]
  });

  my $js_class = $object->use_ajax ? $object->is_ajax_request ? $self->_JS_CLASS_RESPONSE_ELEMENT : $self->_JS_CLASS_DBF_RECORD : ();
  $content->append_child($self->record_tree($_))->set_attributes({'class' => ['dbf-record', $js_class]}) for @$records;
  $content->append_child($links->clone_node(1)) if $links; ## bottom pagination

  return $content;
}

sub record_tree {
  ## Generates a DOM tree for each database record
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  ## Flags are set on required HTML elements for 'selection and manipulation' purposes in child classes (get_nodes_by_flag)
  ## If overriding, make sure _JS_CLASS_DELETE_BUTTON & _JS_CLASS_EDIT_BUTTON classes are on the buttons if JavaScript functionality is required
  my ($self, $record) = @_;
  my $object      = $self->object;
  my $hub         = $self->hub;
  
  my $primary_key = $record->get_primary_key_value;
  my $record_div  = $self->dom->create_element('div', {'flags' => {'primary_key' => $primary_key}});

  my @bg          = qw(bg1 bg2);
  my $fields      = $object->get_fields;

  while (my $field_name = shift @$fields) {

    my $field   = shift @$fields;
    next if $field->{'display'} && $field->{'display'} eq 'never';
    my $value   = $record->field_value($field_name);
    next if !$value && $field->{'display'} && $field->{'display'} eq 'optional';
    my $jclass  = $self->{'_column_class_names'}{$field_name};

    # add class attribute for datastructure type columns
    unless (defined $jclass) {
      my $column = $record->meta->column($field_name);
      $jclass = $self->{'_column_class_names'}{$field_name} = $column && $column->type eq 'datastructure' ? $self->_JS_CLASS_DATASTRUCTURE : '';
    }

    my $display_value = $self->display_field_value($value, $field->{'values'} ? {'lookup' => $field->{'values'}} : {});

    $record_div->append_child('div', {
      'class'     => "dbf-row $bg[0]",
      'flags'     => $field_name,
      'children'  => [{
        'node_name'   => 'div',
        'class'       => 'dbf-row-left',
        'inner_HTML'  => exists $field->{'label'} ? $field->{'label'} : ''
      }, {
        'node_name'   => 'div',
        'class'       => "dbf-row-right $jclass",
        'inner_HTML'  =>  defined $display_value ? $display_value : ''
      }]
    });

    @bg = reverse @bg;
  }

  $record_div->append_child('div', {
    'class'       => "dbf-row-buttons",
    'flags'       => $self->_FLAG_RECORD_BUTTONS,
    'inner_HTML'  => sprintf(
      '<a class="%s" href="%s">Edit</a>%s%s',
      $self->_JS_CLASS_EDIT_BUTTON,
      $hub->url({'action' => 'Edit', 'function' => $hub->function, 'id' => $primary_key}),
      $object->permit_delete ? sprintf(
        '<a class="%s" href="%s">Delete</a>',
        $self->_JS_CLASS_EDIT_BUTTON,
        $hub->url({'action' => 'Confirm', 'function' => $hub->function, 'id' => $primary_key})
      ) : '',
      $object->permit_duplicate ? sprintf(
        '<a class="%s" href="%s">Duplicate</a>',
        $self->_JS_CLASS_EDIT_BUTTON,
        $hub->url({'action' => 'Duplicate', 'function' => $hub->function, 'id' => $primary_key})
      ) : ''
    )
  });
  return $record_div;
}

sub display_field_value {
  ## Converts the field value into displayable form
  ## @param Value, as returned by the rose's method call, can be a string, rose object or an arrayref of rose objects ;)
  ## @param Hashref with some extra stuff with following keys
  ##  - delimiter:  to be used in join if multiple values
  ##  - lookup:     Arrayref with hashrefs of keys 'value' and 'caption'
  my ($self, $value, $extras) = @_;

  # if nothing
  return '' unless defined $value;

  # if it's a string
  if (!ref $value) {
    $_->{'value'} eq $value and return $_->{'caption'} for @{$extras->{'lookup'} || []};
    return $value;
  }
  
  # if it's an arrayref
  if (ref $value eq 'ARRAY') {
    my @return = map {$self->display_field_value($_)} @$value;
    return @return ? sprintf($extras->{'delimiter'} ? '%s' : '<ul><li>%s</li></ul>', join($extras->{'delimiter'} || '</li><li>', sort @return)) : '';
  }

  # if it's DateTime (rose returns DateTime for datetime mysql type)
  if (UNIVERSAL::isa($value, 'DateTime')) {
    return $self->print_datetime($value);
  }

  # if it's a rose object
  if (UNIVERSAL::isa($value, 'EnsEMBL::ORM::Rose::Object')) {
    my $title = $value->get_title;
    
    # if it's a user
    if ($value->isa('EnsEMBL::ORM::Rose::Object::User') && $self->object->show_user_email) {
      return sprintf('<a href="mailto:%s">%s</a>', $value->email, $title);
    }
    return $title;
  }
  
  # unknown value type
  return $value;
}

1;