package EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete;

### NAME: EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete
### Creates a page asking for a confirmation to delete the record

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
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $record  = $object->rose_object;
  
  my $content = $self->dom->create_element('div', {'class' => $self->_JS_CLASS_RESPONSE_ELEMENT});

  if ($object->permit_delete =~ /^(delete|retire)$/) {
    $content->inner_HTML(
      sprintf('<p class="dbf-dialogue">%s</p><p class="dbf-dialogue">Are you sure you want to continue?</p><p class="dbf-dialogue"><a class="dbf-confirm-buttons %s" href="%s">Yes</a><a class="dbf-confirm-buttons %s" href="%s">No</a></p>',
      $1 && $1 eq 'delete'
        ? sprintf('This will permanently remove %s (%s) from the database.', $object->record_name->{'singular'}, $record->get_title)
        : sprintf('%s (%s) will still remain in the database but will no longer be accessible.', ucfirst $object->record_name->{'singular'}, $record->get_title),
      $self->_JS_CLASS_DELETE_BUTTON,
      $hub->url({'action' => 'Delete', 'id' => $record->get_primary_key_value}),
      $self->_JS_CLASS_CANCEL_BUTTON,
      $hub->referer->{'uri'} || $hub->url({'action' => $object->default_action})
    ));
  }
  else {
    $content->inner_HTML(sprintf('<p class="dbf-dialogue">You do not have the permission to delete this %s</p>', $object->record_name->{'singular'}));
  }

  return $content;
}

1;