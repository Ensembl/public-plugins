=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Documents::Preview;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption       { my $title = shift->object->document_title; return $title ? "Preview $title" : ''; }
sub short_caption { return shift->caption;                                                            }

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $message = $object->message;

  return $self->dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;

  my $form = $self->new_form({'method' => 'post', 'action' => $hub->url({'action' => 'Save', 'function' => $hub->function})});
  $form->add_hidden({
    'name'        => 'post_document',
    'value'       => $object->get_raw_file
  });
  $form->add_field({
    'label'       => 'CVS commit message',
    'type'        => 'string',
    'name'        => 'post_cvs',
    'shortnote'   => sprintf(' by %s', $hub->user->email),
    'required'    => 1
  });
  $form->add_button({'value' => 'Save &amp; Commit to CVS'});

  return sprintf('<p><pre class="admin-doc-preview">%s PREVIEW STARTS %1$s</pre></p>%s<p><pre class="admin-doc-preview">%1$s PREVIEW ENDS %1$s</pre></p>%s', '&#8212;' x 20, $self->get_display_html, $form->render);
}

1;