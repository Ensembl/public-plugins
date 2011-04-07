package EnsEMBL::ORM::Component::DbFrontend::Select;

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

  my $func    = $hub->function eq 'Delete' ? 'Confirm' : 'Edit';
  my $content = $self->dom->create_element('div', {'class' => $object->content_css});
  
  unless ($records && @$records) {
    $content->inner_HTML(sprintf('<p>No %s found to %s.</p>', $object->record_name->{'singular'}, lc $hub->function));
  }
  else {
    my $form  = $content->append_child($self->new_form({'action' => $self->hub->url({'action' => $func}), 'method' => 'get'}));
    
    $form->add_field({
      'type'    => $object->record_select_style eq 'radio' ? 'radiolist' : 'dropdown',
      'name'    => 'id',
      'label'   => sprintf("Select a %s to %s", $object->record_name->{'singular'}, lc $hub->function),
      'values'  => [ map {{'value' => $_->get_primary_key_value, 'caption' => $_->get_title}} @$records ],
    });
  
    $form->add_button({'type'  => 'submit', 'value' => 'Next &raquo;' });
  }

  return $content;
}

1;
