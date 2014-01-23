=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Documents::Edit;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption       { my $title = shift->object->document_title; return $title ? "Editing $title" : ''; }
sub short_caption { return shift->caption;                                                            }

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $message = $object->message;
  my $html    = '';

  return $self->dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;

  my $form = $self->new_form({'method' => 'post', 'action' => $hub->url({'action' => 'Preview', 'function' => $hub->function})});
  $form->add_fieldset->append_child('textarea', {'cols' => '100', 'rows' => '60', 'name' => 'post_document', 'class' => 'admin-doc-edit', 'inner_HTML' => $object->get_raw_file || ''});
  $form->add_fieldset->add_button({'value' => 'Preview'});

  $html .= $form->render;

  return $html;
}

1;