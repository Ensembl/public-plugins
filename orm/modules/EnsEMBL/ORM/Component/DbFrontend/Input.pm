package EnsEMBL::ORM::Component::DbFrontend::Input;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Input
### Creates a form to add/edit/preview a database record

### STATUS: Under development
### Note: This module should not be modified! 
### To customise, extend either this module in your component, or EnsEMBL::Web::Object::DbFrontend in your plugin/E/W/Object

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  ## Generates a DOM tree for content HTML
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  ## Flags are set on required HTML elements for 'selection and manipulation' purposes in child classes (get_nodes_by_flag)
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $action  = $hub->action;

  my $record  = $object->rose_object or return $self->dom->create_element('p', {'inner_HTML' => sprintf('No %s selected to edit.', $object->record_name->{'singular'})});
  my $is_ajax = $object->is_ajax_request;
  my $preview = $object->show_preview && $action ne 'Preview' && $is_ajax ne 'list';
  my $serial  = $record->get_primary_key_value;

  my $content = $self->dom->create_element('div', {
    'class'     => [$object->content_css, $self->_JS_CLASS_RESPONSE_ELEMENT],
    'children'  => [$is_ajax ? {'node_name' => 'h3', 'class' => 'dbf-heading', 'inner_HTML' => sprintf('%s %s:', $object->action, $object->record_name->{'singular'})} : ()]
  });
  my $form    = $content->append_child($self->new_form({
    'action' => $hub->url({'action' => $preview ? 'Preview' : 'Save', 'function' => $hub->function}),
    'class'  => !$preview ? $serial ? $self->_JS_CLASS_SAVE_FORM : $self->_JS_CLASS_ADD_FORM : $self->_JS_CLASS_PREVIEW_FORM
  }));
  
  # include extra GET params to hidden inputs (ignore primary keys and ajax flags)
  if ($preview) {
    $_ !~ /^_/ and $_ ne 'id' and $_ ne $record->primary_key and $form->add_hidden({'name' => $_, 'value' => $hub->param($_)}) for $hub->param;
  }

  my $fields  = $self->unpack_rose_object($record);

  # primary key
  $form->add_hidden({'name' => 'id', 'value' => $serial})->set_flag($record->primary_key) if $serial;

  # print fields  
  foreach my $field (@$fields) {

    my $field_extras = $field->extras;
    my $field_params = {'label' => $field->label, 'elements' => []};
    $field_params->{$_} = $field_extras->{$_} for keys %$field_extras;
  
    my $name   = $field->name;
    my $lookup = {};
    my $value  = '';
    my $f_type = $field->field_type;
    my $select = $f_type =~ /^(dropdown|checklist|radiolist)$/ ? 1 : 0;

    map {delete $field_params->{$_}} qw(notes shortnote) if $action eq 'Preview';

    my $form_field = $form->add_field($field_params);
    $form_field->set_flag($name);

    if ($select) {
      $value  = [ keys %{$field->selected} ];
      $lookup = $field->lookup;
      $f_type = $field->multiple ? 'checklist' : 'radiolist' if $f_type =~ /list$/;
    }
    else {
      $value = $field->value;
    }

    my $element_params = {
      'name'      => $name,
      'type'      => $f_type,
      'value'     => $value,
      'values'    => [],
      'multiple'  => $field->multiple,
      'caption'   => $field->caption,
      'no_input'  => $action eq 'Preview' ? 0 : 1,
    };
    $element_params->{$_} = $field_extras->{$_} for keys %$field_extras;
    $element_params->{'class'} .= ' '.$self->_JS_CLASS_DATASTRUCTURE if $action ne 'Preview' && $field->is_datastructure && $field->is_column;

    my $is_null = $field->is_null;
    my $is_datastructure;

    my $selected_values = {};
    if (scalar keys %$lookup) {
      if ($action eq 'Preview') {
        $selected_values = { map {$_ => $lookup->{$_}} @$value };
        scalar keys %$selected_values or $is_null and $selected_values = {'0' => $is_null eq '1' ? 'None' : $is_null};
      }
      else {
        if ($is_null) {
          $element_params->{'value'}  = ['0'] unless scalar @{$element_params->{'value'}};
          $element_params->{'values'} = [{'value' => '0', 'caption' => $is_null eq '1' ? 'None' : $is_null}];
        }
        push @{$element_params->{'values'}}, {'value' => $_, 'caption' => {'inner_HTML' => $lookup->{$_}, $field->is_datastructure ? ('class' => $self->_JS_CLASS_DATASTRUCTURE) : ()}} for sort { $lookup->{$a} cmp $lookup->{$b} } keys %$lookup;
      }
    }

    # trackable fields manipulation
    if ($record->meta->is_trackable($name)) {
      if ($name =~ /^(created|modified)_(at|by_user)$/) {
        $element_params->{'type'}     = 'noedit'; # force noedit field type for trackable fields
        $element_params->{'is_html'}  = 1 if $2 eq 'by_user';
        $element_params->{'caption'}  = $2 eq 'by_user' ? $hub->user->name : 'Now' if $1 eq ($serial ? 'modified' : 'created');
      }
    }
    
    if ($action eq 'Preview') {
      if ($select) {
        for (sort { $selected_values->{$a} cmp $selected_values->{$b} } keys %$selected_values) {
          $element_params->{'value'}   = $_;
          $element_params->{'caption'} = $selected_values->{$_};
          $element_params->{'type'}    = 'noedit';
          my $form_element = $form_field->add_element($element_params);
          map {$_->set_attribute('class', $self->_JS_CLASS_DATASTRUCTURE)} @{$form_element->get_elements_by_tag_name('li')} if $field->is_datastructure;
        }
      }
      else {
        $element_params->{'type'}     = 'noedit';
        $element_params->{'is_html'}  = 1 if $f_type eq 'html';
        my $form_element = $form_field->add_element($element_params);
        $form_element->first_child->set_attribute('class', $self->_JS_CLASS_DATASTRUCTURE) if $field->is_datastructure;
      }
    }
    else {
      $form_field->add_element($element_params);
    }
  }

  $form->add_button({'buttons' => [
    { 'type'  => 'submit', 'value' => $preview ? 'Preview' : 'Save'},
    $action eq 'Preview' || $is_ajax eq 'list' ? () : { 'type'  => 'reset',  'value' => 'Reset' },
    $is_ajax ? { 'type'  => 'reset',  'value' => $preview || $is_ajax eq 'list' ? 'Cancel' : 'Back', 'class' => $self->_JS_CLASS_CANCEL_BUTTON } : ()
  ]})->set_flag('buttons');

  return $content;
}

1;