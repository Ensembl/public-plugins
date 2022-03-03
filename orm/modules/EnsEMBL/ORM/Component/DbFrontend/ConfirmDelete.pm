=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete;

### NAME: EnsEMBL::ORM::Component::DbFrontend::ConfirmDelete
### Creates a page asking for a confirmation to delete the record

### STATUS: Under development
### Note: This module should not be modified! 
### To customise, either extend this module in your component, or EnsEMBL::Web::Object::DbFrontend in your E::W::object

use strict;
use warnings;

use parent qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  ## Generates a DOM tree for content HTML
  ## Override this one in the child class and do the DOM manipulation on the DOM tree if required
  ## Flags are set on required HTML elements for 'selection and manipulation' purposes in child classes (get_nodes_by_flag)
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $record    = $object->rose_object;
  my $function  = $hub->function || '';
  
  my $content = $self->dom->create_element('div', {'class' => $self->_JS_CLASS_RESPONSE_ELEMENT});

  if ($object->permit_delete =~ /^(delete|retire)$/) {
    $content->inner_HTML(
      sprintf('<div class="dbf-padded"><p>%s</p><p>Are you sure you want to continue?</p><div class="dbf-confirm-buttons"><a class="%s" href="%s">Yes</a><a class="%s" href="%s">No</a></div></div>',
      $1 && $1 eq 'delete'
        ? sprintf('This will permanently remove %s (%s) from the database.', $object->record_name->{'singular'}, $record->get_title)
        : sprintf('%s (%s) will still remain in the database but will no longer be accessible.', ucfirst $object->record_name->{'singular'}, $record->get_title),
      $self->_JS_CLASS_DELETE_BUTTON,
      $hub->url({'action' => 'Delete', 'function' => $function, 'id' => $record->get_primary_key_value}),
      $self->_JS_CLASS_CANCEL_BUTTON,
      $hub->referer->{'uri'} || $hub->url({'action' => $object->default_action, 'function' => $function})
    ));
  }
  else {
    $content->inner_HTML(sprintf('<div class="dbf-padded"><p>You do not have the permission to delete this %s</p></div>', $object->record_name->{'singular'}));
  }

  return $content;
}

1;