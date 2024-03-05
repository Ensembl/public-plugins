=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::ORM::Component::DbFrontend::Select;

use strict;
use warnings;

use parent qw(EnsEMBL::ORM::Component::DbFrontend);

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
